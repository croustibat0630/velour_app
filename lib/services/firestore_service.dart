import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/skin_config.dart';
import 'firestore_dense_world_rank_snapshot.dart';
import 'velour_observability.dart';

/// Rang dense mondial + égalité de score (footer « Votre rang »).
typedef MyDenseWorldRank = ({int denseRank, bool tiedWithOthersSameScore});

/// Données joueur lues sur Firestore après auth (fusion avec le disque local).
typedef PlayerCloudPull = ({
  List<String>? inventory,
  String? activeSkinId,
  int cloudLuxCoins,
  int cloudHighScore,
});

/// Réponse de la callable [velourApplyLuxDelta] (`functions/src/index.ts`).
typedef LuxDeltaApplyResult = ({
  bool ok,
  int? newLux,
  int? prevLux,
  int? appliedDelta,
});

/// Accès Firestore / auth anonyme pour le profil joueur et le classement.
///
/// [GameState] n’utilise que cette façade ; les noms de champs et collections
/// restent encapsulés ici.
class FirestoreService {
  FirestoreService._();
  static final FirestoreService instance = FirestoreService._();

  /// Même région que les callables dans `functions/src/index.ts`.
  static const String cloudFunctionsRegion = 'europe-west3';

  /// Au-delà : log [VelourObservability.logEconomySecurity] (bootstrap LUX).
  static const int maxBootstrapLuxDeltaSingleLog = 50000;

  /// Lazy : ne pas toucher Firebase au premier accès à [instance] (tests sans init).
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  bool _authInitInProgress = false;
  bool _authReady = false;
  String? _uid;

  int? _pendingCloudHighScore;
  int? _pendingCloudLuxCoins;

  DocumentReference<Map<String, dynamic>>? get _playerRef =>
      _uid == null ? null : _db.collection('players').doc(_uid);

  Query<Map<String, dynamic>> get _topTenQuery => _db
      .collection('players')
      .orderBy('highScore', descending: true)
      .orderBy('updatedAt', descending: false)
      .limit(10);

  /// Un seul flux Firestore pour le Top 10 (partage entre écouteurs).
  late final Stream<QuerySnapshot<Map<String, dynamic>>>
  leaderboardTopTenStream = _topTenQuery
      .snapshots(includeMetadataChanges: true)
      .asBroadcastStream();

  bool get isCloudReady => _authReady && _playerRef != null;

  /// UID courant (auth Firebase), sans dépendre de [initializeAuthAndPullSkins].
  String? get currentFirebaseUserId {
    try {
      return FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  /// Doc joueur (métadonnées incluses) pour HUD footer score / pseudo à jour.
  Stream<DocumentSnapshot<Map<String, dynamic>>> getPlayerDocStream(
    String uid,
  ) {
    return _db
        .collection('players')
        .doc(uid)
        .snapshots(includeMetadataChanges: true);
  }

  Future<MyDenseWorldRank> _denseWorldRankForHighScore(int myScore) async {
    try {
      return await computeMyDenseWorldRankFromFirestore(_db, myScore);
    } catch (_) {
      return (denseRank: 0, tiedWithOthersSameScore: false);
    }
  }

  /// Stream du rang dense mondial : recalcul **à chaque snapshot** du doc joueur
  /// (score / méta) + tick lent pour les cas où le classement bouge sans ton doc.
  Stream<MyDenseWorldRank> getMyRankStream(String uid) {
    final DocumentReference<Map<String, dynamic>> ref = _db
        .collection('players')
        .doc(uid);

    return Stream<MyDenseWorldRank>.multi((controller) {
      StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? docSub;
      StreamSubscription<int>? clockSub;
      int publishGen = 0;

      Future<void> publishForSnapshot(
        DocumentSnapshot<Map<String, dynamic>> snap,
      ) async {
        final int g = ++publishGen;
        if (controller.isClosed) return;
        final int myScore = (snap.data()?['highScore'] as num?)?.toInt() ?? 0;
        final MyDenseWorldRank r = await _denseWorldRankForHighScore(myScore);
        if (controller.isClosed || g != publishGen) return;
        controller.add(r);
      }

      docSub = getPlayerDocStream(uid).listen(
        (DocumentSnapshot<Map<String, dynamic>> snap) {
          unawaited(publishForSnapshot(snap));
        },
        onError: (e, st) {
          VelourObservability.logFirestoreFailure(
            'getMyRankStream.playerDoc',
            error: e,
            stackTrace: st,
          );
          if (!controller.isClosed) {
            controller.add((denseRank: 0, tiedWithOthersSameScore: false));
          }
        },
      );

      clockSub = Stream<int>.periodic(const Duration(seconds: 45)).listen((_) {
        unawaited(() async {
          try {
            final DocumentSnapshot<Map<String, dynamic>> snap = await ref.get();
            await publishForSnapshot(snap);
          } catch (e, st) {
            VelourObservability.logFirestoreFailure(
              'getMyRankStream.periodicRefresh',
              error: e,
              stackTrace: st,
            );
            if (!controller.isClosed) {
              controller.add((denseRank: 0, tiedWithOthersSameScore: false));
            }
          }
        }());
      });

      controller.onCancel = () {
        docSub?.cancel();
        clockSub?.cancel();
      };
    });
  }

  bool _isNetworkFirebaseException(Object e) {
    if (e is! FirebaseException) return false;
    const Set<String> codes = <String>{
      'unavailable',
      'deadline-exceeded',
      'network-request-failed',
      'unknown',
      'internal',
      'aborted',
      'cancelled',
    };
    return codes.contains(e.code);
  }

  Future<T> _firestoreRetry<T>(Future<T> Function() op) async {
    int attempt = 0;
    int backoffMs = 180;
    while (true) {
      try {
        return await op();
      } catch (e, st) {
        attempt++;
        if (attempt >= 3 || !_isNetworkFirebaseException(e)) {
          if (attempt >= 3) {
            VelourObservability.logFirestoreFailure(
              'firestore_retry_exhausted',
              error: e,
              stackTrace: st,
              context: <String, Object?>{
                'attempts': attempt,
                'transientNetwork': _isNetworkFirebaseException(e),
              },
            );
          }
          rethrow;
        }
        await Future<void>.delayed(Duration(milliseconds: backoffMs));
        backoffMs = (backoffMs * 2).clamp(180, 1200);
      }
    }
  }

  /// Auth anonyme + doc joueur + lecture inventaire / skin / LUX / high score.
  ///
  /// Retourne `null` si pas de session cloud ; sinon [inventory] / [activeSkinId]
  /// peuvent être null si la lecture a échoué (les entiers restent à 0).
  Future<PlayerCloudPull?> initializeAuthAndPullSkins() async {
    if (_authReady) {
      return await _pullPlayerEconomySnapshot();
    }
    if (_authInitInProgress) return null;
    _authInitInProgress = true;
    try {
      User? u;
      try {
        u = FirebaseAuth.instance.currentUser;
      } catch (_) {
        return null;
      }
      if (u == null) {
        try {
          final UserCredential cred = await FirebaseAuth.instance
              .signInAnonymously();
          u = cred.user;
        } catch (_) {
          return null;
        }
      }
      if (u == null) return null;
      _uid = u.uid;
      _authReady = true;

      try {
        final DocumentReference<Map<String, dynamic>> doc = _db
            .collection('players')
            .doc(u.uid);
        final DocumentSnapshot<Map<String, dynamic>> snap = await doc.get();
        if (!snap.exists) {
          await doc.set(<String, dynamic>{
            'highScore': 0,
            'totalLux': 0,
            'inventory': <String>[SkinCatalog.standard.id],
            'activeSkinId': SkinCatalog.standard.id,
            'lastSeen': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          await doc.set(<String, dynamic>{
            'lastSeen': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      } catch (_) {}

      final PlayerCloudPull? skins = await _pullPlayerEconomySnapshot();

      return skins;
    } finally {
      _authInitInProgress = false;
    }
  }

  Future<PlayerCloudPull?> _pullPlayerEconomySnapshot() async {
    final DocumentReference<Map<String, dynamic>>? ref = _playerRef;
    if (!_authReady || ref == null) return null;
    try {
      final DocumentSnapshot<Map<String, dynamic>> me = await ref.get();
      final Map<String, dynamic>? d = me.data();
      final List<dynamic>? inv = d?['inventory'] as List<dynamic>?;
      final String? active = d?['activeSkinId'] as String?;
      final List<String>? inventory = inv
          ?.map((dynamic e) => e.toString())
          .toList();
      final int cloudLux = (d?['totalLux'] as num?)?.toInt() ?? 0;
      final int cloudHs = (d?['highScore'] as num?)?.toInt() ?? 0;
      return (
        inventory: inventory,
        activeSkinId: active,
        cloudLuxCoins: cloudLux,
        cloudHighScore: cloudHs,
      );
    } catch (_) {
      return (
        inventory: null,
        activeSkinId: null,
        cloudLuxCoins: 0,
        cloudHighScore: 0,
      );
    }
  }

  /// Écriture consolidée après fusion multi-appareils (préserve `pseudo`, etc.).
  /// Valeurs en attente d’écriture cloud (auth pas prête) — à intégrer au merge.
  ({int? luxCoins, int? highScore}) consumePendingCloudSyncHints() {
    final int? lux = _pendingCloudLuxCoins;
    final int? hs = _pendingCloudHighScore;
    _pendingCloudLuxCoins = null;
    _pendingCloudHighScore = null;
    return (luxCoins: lux, highScore: hs);
  }

  /// Pousse inventaire / skin / high score — **pas** `totalLux` (réservé aux callables).
  Future<void> pushMergedPlayerProgress({
    required int highScore,
    required List<String> inventory,
    required String activeSkinId,
  }) async {
    final DocumentReference<Map<String, dynamic>>? ref = _playerRef;
    if (!_authReady || ref == null) return;
    try {
      await _firestoreRetry(() async {
        await ref.set(<String, dynamic>{
          'highScore': highScore,
          'inventory': inventory,
          'activeSkinId': activeSkinId,
          'lastSeen': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      });
    } catch (e, st) {
      VelourObservability.logFirestoreFailure(
        'pushMergedPlayerProgress',
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<void> syncHighScoreToCloud(int score) async {
    final DocumentReference<Map<String, dynamic>>? ref = _playerRef;
    if (!_authReady || ref == null) {
      _pendingCloudHighScore = score;
      return;
    }
    try {
      await _firestoreRetry(() async {
        await ref.set(<String, dynamic>{
          'highScore': score,
          'lastSeen': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      });
    } catch (e, st) {
      VelourObservability.logFirestoreFailure(
        'syncHighScoreToCloud',
        error: e,
        stackTrace: st,
        context: <String, Object?>{'score': score},
      );
      _pendingCloudHighScore = score;
    }
  }

  /// Indice pour le prochain merge local (échec callable / auth tardive).
  void queuePendingLuxCloudHint(int absoluteLuxCoinsHint) {
    final int prev = _pendingCloudLuxCoins ?? 0;
    _pendingCloudLuxCoins = math.max(prev, absoluteLuxCoinsHint);
  }

  /// Morceau de delta autorisé par appel [velourApplyLuxDelta] (aligné sur la CF).
  static int chunkLuxDeltaForCallable(int delta) {
    if (delta == 0) return 0;
    if (delta > 0) return math.min(delta, 2500);
    return math.max(delta, -500000);
  }

  /// Régularise le solde serveur vers [targetMergedLux] après bootstrap (chunks callables).
  Future<bool> reconcileBootstrapLuxAgainstSnapshot({
    required int targetMergedLux,
    required int cloudLuxSnapshot,
  }) async {
    if (!_authReady || _uid == null) return false;
    int serverCursor = math.max(0, cloudLuxSnapshot);
    final int gap = (targetMergedLux - cloudLuxSnapshot).abs();
    if (gap > maxBootstrapLuxDeltaSingleLog) {
      VelourObservability.logEconomySecurity(
        'bootstrap_lux_gap_suspicious',
        data: <String, Object?>{
          'target': targetMergedLux,
          'cloudSnap': cloudLuxSnapshot,
          'gap': gap,
        },
      );
    }
    for (
      int iter = 0;
      iter < 10000 && serverCursor != targetMergedLux;
      iter++
    ) {
      final int rawDelta = targetMergedLux - serverCursor;
      if (rawDelta == 0) break;
      final int step = chunkLuxDeltaForCallable(rawDelta);
      if (step == 0) break;
      final LuxDeltaApplyResult? r = await tryApplyLuxDeltaViaCallable(step);
      if (r == null || !r.ok) {
        VelourObservability.logEconomySecurity(
          'bootstrap_lux_reconcile_callable_failed',
          data: <String, Object?>{
            'step': step,
            'serverCursor': serverCursor,
            'target': targetMergedLux,
          },
        );
        return false;
      }
      final int? n = r.newLux;
      final int applied = r.appliedDelta ?? step;
      serverCursor = n ?? (serverCursor + applied);
    }
    return serverCursor == targetMergedLux;
  }

  /// `true` si le dialogue peut se fermer (succès ou hors-ligne volontaire).
  Future<bool> updateOraclePseudo(String cleaned) async {
    final DocumentReference<Map<String, dynamic>>? ref = _playerRef;
    if (!_authReady || ref == null) {
      return true;
    }
    try {
      await _firestoreRetry(() async {
        await ref.set(<String, dynamic>{
          'pseudo': cleaned,
          'lastSeen': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      });
      return true;
    } catch (e, st) {
      VelourObservability.logFirestoreFailure(
        'updateOraclePseudo',
        error: e,
        stackTrace: st,
      );
      return false;
    }
  }

  /// `true` si le joueur doit voir la cérémonie de nom (pseudo placeholder + top 10).
  Future<bool> shouldOfferOracleNamingForNewHighScore(int newHighScore) async {
    final DocumentReference<Map<String, dynamic>>? ref = _playerRef;
    if (!_authReady || ref == null) return false;
    try {
      final DocumentSnapshot<Map<String, dynamic>> me = await _firestoreRetry(
        () => ref.get(),
      );
      final Map<String, dynamic>? d = me.data();
      final String? pseudo = d?['pseudo'] as String?;
      final bool needsName =
          pseudo == null ||
          pseudo.startsWith('Oracle_') ||
          pseudo.startsWith('oracle_');
      if (!needsName) return false;

      final QuerySnapshot<Map<String, dynamic>> top = await _firestoreRetry(
        () => _topTenQuery.get(),
      );
      final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs = top.docs;
      final bool inTop = docs.length < 10
          ? true
          : newHighScore >=
                ((docs.last.data()['highScore'] as num?)?.toInt() ?? 0);
      return inTop;
    } catch (e, st) {
      VelourObservability.logFirestoreFailure(
        'shouldOfferOracleNamingForNewHighScore',
        error: e,
        stackTrace: st,
        context: <String, Object?>{'newHighScore': newHighScore},
      );
      return false;
    }
  }

  /// Applique un delta LUX en transaction serveur ([velourApplyLuxDelta]).
  ///
  /// Retourne `null` si l’appel est impossible (pas d’auth, hors ligne, fonction non
  /// déployée).
  Future<LuxDeltaApplyResult?> tryApplyLuxDeltaViaCallable(int delta) async {
    if (delta == 0) {
      return (ok: true, newLux: null, prevLux: null, appliedDelta: 0);
    }
    if (!_authReady || _uid == null) {
      return null;
    }
    try {
      final FirebaseFunctions fns = FirebaseFunctions.instanceFor(
        app: Firebase.app(),
        region: cloudFunctionsRegion,
      );
      final HttpsCallable callable = fns.httpsCallable(
        'velourApplyLuxDelta',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 25)),
      );
      final HttpsCallableResult res = await callable.call(<String, dynamic>{
        'delta': delta,
      });
      final Object? data = res.data;
      if (data is! Map) {
        return (ok: false, newLux: null, prevLux: null, appliedDelta: null);
      }
      final Map<String, dynamic> raw = Map<String, dynamic>.from(data);
      final bool ok = raw['ok'] == true;
      final int? newLux = (raw['newLux'] as num?)?.toInt();
      final int? prevLux = (raw['prevLux'] as num?)?.toInt();
      final int? appliedDelta = (raw['appliedDelta'] as num?)?.toInt();
      if (!ok) {
        return (
          ok: false,
          newLux: newLux,
          prevLux: prevLux,
          appliedDelta: appliedDelta,
        );
      }
      return (
        ok: true,
        newLux: newLux,
        prevLux: prevLux,
        appliedDelta: appliedDelta,
      );
    } on FirebaseFunctionsException catch (e, st) {
      VelourObservability.logFirestoreFailure(
        'velourApplyLuxDelta',
        error: e,
        stackTrace: st,
        context: <String, Object?>{'delta': delta, 'code': e.code},
      );
      return null;
    } catch (e, st) {
      VelourObservability.logFirestoreFailure(
        'velourApplyLuxDelta',
        error: e,
        stackTrace: st,
        context: <String, Object?>{'delta': delta},
      );
      return null;
    }
  }

  Future<void> mergeActiveSkinOnly(String skinId) async {
    final DocumentReference<Map<String, dynamic>>? ref = _playerRef;
    if (!_authReady || ref == null) return;
    try {
      await _firestoreRetry(() async {
        await ref.set(<String, dynamic>{
          'activeSkinId': skinId,
          'lastSeen': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      });
    } catch (e, st) {
      VelourObservability.logFirestoreFailure(
        'mergeActiveSkinOnly',
        error: e,
        stackTrace: st,
        context: <String, Object?>{'skinId': skinId},
      );
    }
  }

  Future<void> mergeSkinPurchaseAndEquip(String skinId) async {
    final DocumentReference<Map<String, dynamic>>? ref = _playerRef;
    if (!_authReady || ref == null) return;
    try {
      await _firestoreRetry(() async {
        await ref.set(<String, dynamic>{
          'inventory': FieldValue.arrayUnion(<String>[skinId]),
          'activeSkinId': skinId,
          'lastSeen': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      });
    } catch (e, st) {
      VelourObservability.logFirestoreFailure(
        'mergeSkinPurchaseAndEquip',
        error: e,
        stackTrace: st,
        context: <String, Object?>{'skinId': skinId},
      );
    }
  }
}
