import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/game_state.dart';

/// Identifiants App Store Connect (consommables) — crédit LUX après validation Apple.
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

enum LuxIapBuyKind { success, cancelled, unavailable, productsUnavailable, busy, error }

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

/// Achats intégrés Coffre-fort (StoreKit sur iOS, Play Billing sur Android via [in_app_purchase]).
///
/// Souscription au flux dès le binding [bindGameState] pour ne pas rater d’événements
/// (recommandation Flutter).
class LuxIapService {
  LuxIapService._();
  static final LuxIapService instance = LuxIapService._();

  static const String _prefsConsumedKey = 'velour_iap_consumed_purchase_ids';

  final InAppPurchase _iap = InAppPurchase.instance;

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
    try {
      _storeAvailable = await _iap.isAvailable();
    } catch (_) {
      _storeAvailable = false;
    }
    if (!_storeAvailable) return;

    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdates,
      onError: (Object e, StackTrace st) {
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
        ..addEntries(r.productDetails.map((ProductDetails d) => MapEntry(d.id, d)));
    } catch (_) {
      _products.clear();
    }
  }

  Future<bool> _wasConsumed(String? purchaseId) async {
    if (purchaseId == null || purchaseId.isEmpty) return false;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> ids = prefs.getStringList(_prefsConsumedKey) ?? <String>[];
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
    } catch (_) {}
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

      switch (p.status) {
        case PurchaseStatus.pending:
          break;
        case PurchaseStatus.error:
          if (_awaitingProductId == p.productID) {
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
        case PurchaseStatus.restored:
          await _handlePurchasedOrRestored(p);
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
      _pendingAppleCompletion = p;
      _completeAwaitingIfAny(LuxIapBuyOutcome.success(lux));
      return;
    }

    // Achat confirmé alors que l’UI n’attend plus (ex. app relancée) : créditer quand même.
    final GameState? gs = _gameState;
    if (gs != null) {
      gs.addLuxCoins(lux);
      await gs.flushLuxCoinsPersistence();
    }
    await _markConsumed(pid);
    await _completeIfNeeded(p);
  }

  /// À appeler après [GameState.addLuxCoins] / persistance (ex. fin de l’animation boutique).
  Future<void> finalizeAfterLuxDelivered() async {
    final PurchaseDetails? p = _pendingAppleCompletion;
    if (p == null) return;
    _pendingAppleCompletion = null;
    await _markConsumed(p.purchaseID);
    await _completeIfNeeded(p);
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
    final Completer<LuxIapBuyOutcome> completer = Completer<LuxIapBuyOutcome>();
    _awaiting = completer;
    _awaitingProductId = productId;
    try {
      final bool launched = await _iap.buyConsumable(
        purchaseParam: PurchaseParam(productDetails: details),
        autoConsume: false,
      );
      if (!launched) {
        _pendingAppleCompletion = null;
        _completeAwaitingIfAny(const LuxIapBuyOutcome.error('launch_failed'));
        return completer.future;
      }
      return await completer.future.timeout(
        const Duration(minutes: 2),
        onTimeout: () {
          _pendingAppleCompletion = null;
          _completeAwaitingIfAny(const LuxIapBuyOutcome.error('timeout'));
          return const LuxIapBuyOutcome.error('timeout');
        },
      );
    } finally {
      _buyInFlight = false;
    }
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}
