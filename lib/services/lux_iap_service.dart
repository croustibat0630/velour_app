import 'dart:async';
import 'dart:io' show InternetAddress, Socket;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show
        TargetPlatform,
        ValueNotifier,
        defaultTargetPlatform,
        kIsWeb,
        kReleaseMode,
        visibleForTesting;
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/game_state.dart';
import '../utils/velour_audit_log.dart';
import 'iap_cloud_grant_service.dart';
import 'lux_apply_motifs.dart';
import 'velour_observability.dart';

/// Identifiants consommables — mêmes SKU sur App Store Connect et Google Play Console.
abstract final class LuxIapProducts {
  static const String sparkReserve = 'com.velour.100lux';
  static const String oracleTreasure = 'com.velour.750lux';
  static const String royalLegacy = 'com.velour.5000lux';

  static const Set<String> vaultIds = <String>{
    sparkReserve,
    oracleTreasure,
    royalLegacy,
  };

  static int luxForProductId(String productId) {
    switch (productId) {
      case sparkReserve:
        return 100;
      case oracleTreasure:
        return 750;
      case royalLegacy:
        return 5000;
      default:
        return 0;
    }
  }
}

enum LuxIapBuyKind {
  success,
  cancelled,
  unavailable,
  productsUnavailable,
  busy,
  error,
}

class LuxIapBuyOutcome {
  const LuxIapBuyOutcome._(this.kind, this.luxAmount, this.errorDetail);
  const LuxIapBuyOutcome.success(int lux)
    : this._(LuxIapBuyKind.success, lux, null);
  const LuxIapBuyOutcome.cancelled() : this._(LuxIapBuyKind.cancelled, 0, null);
  const LuxIapBuyOutcome.unavailable()
    : this._(LuxIapBuyKind.unavailable, 0, null);
  const LuxIapBuyOutcome.productsUnavailable()
    : this._(LuxIapBuyKind.productsUnavailable, 0, null);
  const LuxIapBuyOutcome.busy() : this._(LuxIapBuyKind.busy, 0, null);
  const LuxIapBuyOutcome.error(String? detail)
    : this._(LuxIapBuyKind.error, 0, detail);

  final LuxIapBuyKind kind;
  final int luxAmount;
  final String? errorDetail;
}

bool _looksLikeCompactJws(String s) {
  final List<String> parts = s.split('.');
  return parts.length == 3 &&
      parts[0].isNotEmpty &&
      parts[1].isNotEmpty &&
      parts[2].isNotEmpty;
}

/// JWS de transaction StoreKit 2 : le plugin le met dans [PurchaseVerificationData.serverVerificationData].
String? _iosTransactionJwsForCloud(PurchaseVerificationData vd) {
  final String server = vd.serverVerificationData.trim();
  if (_looksLikeCompactJws(server)) {
    return server;
  }
  final String local = vd.localVerificationData.trim();
  if (_looksLikeCompactJws(local)) {
    return local;
  }
  return null;
}

/// Achats intégrés Coffre-fort (StoreKit sur iOS, Play Billing sur Android via [in_app_purchase]).
///
/// Souscription au flux dès le binding [bindGameState] pour ne pas rater d’événements
/// (recommandation Flutter).
///
/// **Anti-triche cloud** : après achat coffre-fort, [finalizeAfterLuxDelivered] et le
/// chemin « orphelin » appellent [IapCloudGrantService.tryGrantVaultPurchase]
/// (`velourGrantIapLux` — voir `functions/src/iap.ts`).
class LuxIapService {
  LuxIapService._();
  static final LuxIapService instance = LuxIapService._();

  static const bool _forceOffline = bool.fromEnvironment(
    'VELOUR_FORCE_OFFLINE',
    defaultValue: false,
  );

  /// Désactive la synchro Cloud Function (tests unitaires sans Firebase).
  @visibleForTesting
  static bool debugSkipCloudPurchaseSync = false;

  static const String _prefsConsumedKey = 'velour_iap_consumed_purchase_ids';

  InAppPurchase get _iap => InAppPurchase.instance;

  /// Incrémenté après chaque [queryProductDetails] (prix / titres magasin).
  final ValueNotifier<int> vaultStorePricesEpoch = ValueNotifier<int>(0);

  /// Libellé prix tel que renvoyé par le store (`ProductDetails.price`, ex. « 0,99 € »), iOS comme Android.
  String? storePriceLabelForProduct(String productId) {
    if (!LuxIapProducts.vaultIds.contains(productId)) return null;
    return _products[productId]?.price;
  }

  /// Réinitialise l’état entre tests (singleton + [InAppPurchasePlatform.instance] mocké).
  @visibleForTesting
  void resetForTesting() {
    _subscription?.cancel();
    _subscription = null;
    final Completer<LuxIapBuyOutcome>? pending = _awaiting;
    if (pending != null && !pending.isCompleted) {
      pending.complete(const LuxIapBuyOutcome.error('test_reset'));
    }
    _awaiting = null;
    _awaitingProductId = null;
    _pendingAppleCompletion = null;
    _initialized = false;
    _storeAvailable = false;
    _products.clear();
    _buyInFlight = false;
    _gameState = null;
    vaultStorePricesEpoch.value = 0;
  }

  GameState? _gameState;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  bool _initialized = false;
  bool _storeAvailable = false;
  final Map<String, ProductDetails> _products = <String, ProductDetails>{};

  bool _buyInFlight = false;
  Completer<LuxIapBuyOutcome>? _awaiting;
  String? _awaitingProductId;
  PurchaseDetails? _pendingAppleCompletion;

  /// Référence au [GameState] pour créditer les LUX « orphelins » (session relancée avant completePurchase).
  void bindGameState(GameState gameState) {
    _gameState = gameState;
    unawaited(_ensureInitialized());
  }

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    _initialized = true;
    if (_forceOffline) {
      _storeAvailable = false;
      VelourAuditLog.event(
        'iap.init',
        data: <String, Object?>{
          'available': false,
          'platform': defaultTargetPlatform.toString(),
          'forcedOffline': true,
        },
      );
      return;
    }
    try {
      _storeAvailable = await _iap.isAvailable();
    } catch (_) {
      _storeAvailable = false;
    }
    VelourAuditLog.event(
      'iap.init',
      data: <String, Object?>{
        'available': _storeAvailable,
        'platform': defaultTargetPlatform.toString(),
      },
    );
    if (!_storeAvailable) return;

    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdates,
      onError: (Object e, StackTrace st) {
        VelourAuditLog.event(
          'iap.stream_error',
          data: <String, Object?>{'error': e.toString()},
        );
        VelourObservability.recordClientFailure(
          VelourObsCodes.iapPurchaseStream,
          e,
          st,
        );
        _completeAwaitingIfAny(LuxIapBuyOutcome.error(e.toString()));
      },
    );

    await _reloadProductDetails();
  }

  /// Recharge les métadonnées produit (utile si le réseau était indisponible au premier bind).
  Future<void> reloadProductsForDebug() => _reloadProductDetails();

  Future<void> _reloadProductDetails() async {
    if (!_storeAvailable) return;
    try {
      final ProductDetailsResponse r = await _iap.queryProductDetails(
        LuxIapProducts.vaultIds,
      );
      _products
        ..clear()
        ..addEntries(
          r.productDetails.map((ProductDetails d) => MapEntry(d.id, d)),
        );
      VelourAuditLog.event(
        'iap.products',
        data: <String, Object?>{
          'count': r.productDetails.length,
          'notFound': r.notFoundIDs.length,
        },
      );
    } catch (e, st) {
      _products.clear();
      VelourAuditLog.event('iap.products_error');
      VelourObservability.recordClientFailure(
        VelourObsCodes.iapQueryProducts,
        e,
        st,
      );
    } finally {
      vaultStorePricesEpoch.value++;
    }
  }

  Future<bool> _wasConsumed(String? purchaseId) async {
    if (purchaseId == null || purchaseId.isEmpty) return false;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> ids =
        prefs.getStringList(_prefsConsumedKey) ?? <String>[];
    return ids.contains(purchaseId);
  }

  Future<void> _markConsumed(String? purchaseId) async {
    if (purchaseId == null || purchaseId.isEmpty) return;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> ids = List<String>.from(
      prefs.getStringList(_prefsConsumedKey) ?? <String>[],
    );
    if (ids.contains(purchaseId)) return;
    ids.add(purchaseId);
    while (ids.length > 120) {
      ids.removeAt(0);
    }
    await prefs.setStringList(_prefsConsumedKey, ids);
  }

  Future<void> _completeIfNeeded(PurchaseDetails p) async {
    if (!p.pendingCompletePurchase) return;
    try {
      await _iap.completePurchase(p);
    } catch (e, st) {
      VelourObservability.recordClientFailure(
        VelourObsCodes.iapCompletePurchase,
        e,
        st,
      );
    }
  }

  void _completeAwaitingIfAny(LuxIapBuyOutcome outcome) {
    final Completer<LuxIapBuyOutcome>? c = _awaiting;
    if (c == null || c.isCompleted) return;
    c.complete(outcome);
    _awaiting = null;
    _awaitingProductId = null;
  }

  Future<void> _onPurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final PurchaseDetails p in purchases) {
      if (!LuxIapProducts.vaultIds.contains(p.productID)) continue;
      VelourAuditLog.event(
        'iap.update',
        data: <String, Object?>{
          'productId': p.productID,
          'status': p.status.toString(),
          'pendingComplete': p.pendingCompletePurchase,
          'hasError': p.error != null,
        },
      );

      switch (p.status) {
        case PurchaseStatus.pending:
          break;
        case PurchaseStatus.error:
          if (_awaitingProductId == p.productID) {
            final Object err = p.error ?? StateError('iap_store_error');
            VelourObservability.recordClientFailure(
              VelourObsCodes.iapPurchaseStoreError,
              err,
              StackTrace.current,
              <String, Object?>{
                'productId': p.productID,
                'code': p.error?.code,
                'message': p.error?.message,
              },
            );
            _pendingAppleCompletion = null;
            _completeAwaitingIfAny(
              LuxIapBuyOutcome.error(p.error?.message ?? p.error?.code),
            );
          }
          await _completeIfNeeded(p);
          break;
        case PurchaseStatus.canceled:
          if (_awaitingProductId == p.productID) {
            _pendingAppleCompletion = null;
            _completeAwaitingIfAny(const LuxIapBuyOutcome.cancelled());
          }
          await _completeIfNeeded(p);
          break;
        case PurchaseStatus.purchased:
          await _handlePurchasedOrRestored(p);
          break;
        case PurchaseStatus.restored:
          // Consumables should not be restored. We complete them to clear the queue,
          // but never grant LUX from a restore event.
          VelourAuditLog.event(
            'iap.restore_ignored',
            data: <String, Object?>{'productId': p.productID},
          );
          if (_awaitingProductId == p.productID) {
            _pendingAppleCompletion = null;
            _completeAwaitingIfAny(
              const LuxIapBuyOutcome.error('restored_ignored'),
            );
          }
          await _completeIfNeeded(p);
          break;
      }
    }
  }

  Future<void> _handlePurchasedOrRestored(PurchaseDetails p) async {
    final int lux = LuxIapProducts.luxForProductId(p.productID);
    if (lux <= 0) {
      await _completeIfNeeded(p);
      return;
    }

    final String? pid = p.purchaseID;
    final bool already = await _wasConsumed(pid);

    final bool hasAwaiting =
        _awaiting != null &&
        !_awaiting!.isCompleted &&
        _awaitingProductId == p.productID;

    if (already) {
      await _completeIfNeeded(p);
      if (hasAwaiting) {
        _pendingAppleCompletion = null;
        _completeAwaitingIfAny(
          const LuxIapBuyOutcome.error('duplicate_transaction'),
        );
      }
      return;
    }

    if (hasAwaiting) {
      // Security: validate/credit server-side first. Only then allow local LUX grant.
      final bool ok = await _tryGrantVaultPurchaseToCloudStrict(p);
      if (!ok) {
        // Keep the purchase uncompleted so StoreKit/Play can re-deliver later.
        _pendingAppleCompletion = null;
        final bool online = kIsWeb ? false : await _hasInternetQuick();
        _completeAwaitingIfAny(
          LuxIapBuyOutcome.error(
            online ? 'server_verification_failed' : 'offline',
          ),
        );
        return;
      }
      // UI can now animate and grant locally, then call finalizeAfterLuxDelivered()
      // to complete/consume the transaction.
      _pendingAppleCompletion = p;
      _completeAwaitingIfAny(LuxIapBuyOutcome.success(lux));
      return;
    }

    // Achat confirmé alors que l’UI n’attend plus (ex. app relancée).
    // We still require server-side verification before granting locally.
    final GameState? gs = _gameState;
    if (gs != null) {
      final bool ok = await _tryGrantVaultPurchaseToCloudStrict(p);
      if (ok) {
        gs.addLuxCoins(
          lux,
          luxCloudMotif: LuxApplyMotifs.velourClientSync,
          recordCloudPending: false,
        );
        await gs.flushLuxCoinsPersistence();
        await _markConsumed(pid);
        await _completeIfNeeded(p);
      }
      return;
    }
  }

  /// À appeler après [GameState.addLuxCoins] / persistance (ex. fin de l’animation boutique).
  Future<void> finalizeAfterLuxDelivered() async {
    final PurchaseDetails? p = _pendingAppleCompletion;
    if (p == null) return;
    _pendingAppleCompletion = null;
    await _markConsumed(p.purchaseID);
    await _completeIfNeeded(p);
  }

  /// Validation + crédit serveur (`velourGrantIapLux`) — **strict**: must succeed for paid packs.
  Future<bool> _tryGrantVaultPurchaseToCloudStrict(PurchaseDetails p) async {
    // Tests / debug : pas d’appel Functions. **Interdit en release** (pas de bypass cloud).
    if (debugSkipCloudPurchaseSync) {
      return !kReleaseMode;
    }
    if (kIsWeb) return false;
    try {
      if (Firebase.apps.isEmpty) return false;
    } catch (_) {
      return false;
    }
    final TargetPlatform tp = defaultTargetPlatform;
    final bool isApple = tp == TargetPlatform.iOS || tp == TargetPlatform.macOS;
    final String platform = isApple ? 'ios' : 'android';
    final PurchaseVerificationData vd = p.verificationData;
    final String? androidTok = !isApple && vd.serverVerificationData.isNotEmpty
        ? vd.serverVerificationData
        : null;
    // StoreKit 2 : le JWS signé est dans serverVerificationData (receiptData natif).
    // StoreKit 1 : local/server = même reçu base64 — pas de JWS ; la callable iOS exige SK2.
    final String? iosJws = isApple ? _iosTransactionJwsForCloud(vd) : null;
    if (!isApple && (androidTok == null || androidTok.isEmpty)) {
      return false;
    }
    if (isApple && (iosJws == null || iosJws.isEmpty)) {
      return false;
    }
    final IapCloudGrantResult? r =
        await IapCloudGrantService.tryGrantVaultPurchase(
          platform: platform,
          productId: p.productID,
          androidPurchaseToken: androidTok,
          iosTransactionJws: iosJws,
        );
    final bool ok = r != null && (r.ok || r.alreadyGranted);
    VelourAuditLog.event(
      'iap.cloud_grant',
      data: <String, Object?>{
        'ok': ok,
        'already': r?.alreadyGranted,
        'productId': p.productID,
      },
    );
    return ok;
  }

  /// Lance l’achat consommable [productId] (StoreKit / Play). Attend la confirmation ou l’échec.
  Future<LuxIapBuyOutcome> buyVaultConsumable(String productId) async {
    if (!LuxIapProducts.vaultIds.contains(productId)) {
      return const LuxIapBuyOutcome.error('invalid_product');
    }
    await _ensureInitialized();
    if (!_storeAvailable) {
      return const LuxIapBuyOutcome.unavailable();
    }
    if (_products.isEmpty) {
      await _reloadProductDetails();
    }
    final ProductDetails? details = _products[productId];
    if (details == null) {
      return const LuxIapBuyOutcome.productsUnavailable();
    }
    if (_buyInFlight) {
      return const LuxIapBuyOutcome.busy();
    }

    _buyInFlight = true;
    VelourAuditLog.event(
      'iap.buy_start',
      data: <String, Object?>{'productId': productId},
    );
    final Completer<LuxIapBuyOutcome> completer = Completer<LuxIapBuyOutcome>();
    _awaiting = completer;
    _awaitingProductId = productId;
    try {
      if (!kIsWeb) {
        final bool online = await _hasInternetQuick();
        if (!online) {
          _pendingAppleCompletion = null;
          _completeAwaitingIfAny(const LuxIapBuyOutcome.error('offline'));
          return const LuxIapBuyOutcome.error('offline');
        }
      }

      // On iOS (StoreKit), consumables must be auto-consumed by the plugin.
      // Using autoConsume: false triggers an assertion and crashes in debug.
      final bool autoConsume = defaultTargetPlatform == TargetPlatform.iOS;
      final bool launched = await _iap.buyConsumable(
        purchaseParam: PurchaseParam(productDetails: details),
        autoConsume: autoConsume,
      );
      if (!launched) {
        _pendingAppleCompletion = null;
        _completeAwaitingIfAny(const LuxIapBuyOutcome.error('launch_failed'));
        VelourAuditLog.event(
          'iap.buy_launch_failed',
          data: <String, Object?>{'productId': productId},
        );
        return completer.future;
      }
      final LuxIapBuyOutcome out = await completer.future.timeout(
        const Duration(minutes: 2),
        onTimeout: () {
          _pendingAppleCompletion = null;
          _completeAwaitingIfAny(const LuxIapBuyOutcome.error('timeout'));
          return const LuxIapBuyOutcome.error('timeout');
        },
      );
      VelourAuditLog.event(
        'iap.buy_end',
        data: <String, Object?>{
          'productId': productId,
          'kind': out.kind.toString(),
          'lux': out.luxAmount,
          'hasError': out.errorDetail != null,
        },
      );
      return out;
    } finally {
      _buyInFlight = false;
    }
  }

  Future<bool> _hasInternetQuick() async {
    try {
      // DNS can be served from cache even in airplane mode.
      // A short TCP connect is a better signal for “real” connectivity.
      final Socket s = await Socket.connect(
        InternetAddress('1.1.1.1'),
        53,
        timeout: const Duration(milliseconds: 1200),
      );
      s.destroy();
      return true;
    } catch (_) {
      return false;
    }
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}
