import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/skin_config.dart';
import 'firestore_dense_world_rank_snapshot.dart';

/// Rang dense mondial + égalité de score (footer « Votre rang »).
typedef MyDenseWorldRank = ({
  int denseRank,
  bool tiedWithOthersSameScore,
});

/// Accès Firestore / auth anonyme pour le profil joueur et le classement.
///
/// [GameState] n’utilise que cette façade ; les noms de champs et collections
/// restent encapsulés ici.
class FirestoreService {
  FirestoreService._();
  static final FirestoreService instance = FirestoreService._();

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
  late final Stream<QuerySnapshot<Map<String, dynamic>>> leaderboardTopTenStream =
      _topTenQuery
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
    final DocumentReference<Map<String, dynamic>> ref =
        _db.collection('players').doc(uid);

    return Stream<MyDenseWorldRank>.multi((controller) {
      StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? docSub;
      StreamSubscription<int>? clockSub;
      int publishGen = 0;

      Future<void> publishForSnapshot(
        DocumentSnapshot<Map<String, dynamic>> snap,
      ) async {
        final int g = ++publishGen;
        if (controller.isClosed) return;
        final int myScore =
            (snap.data()?['highScore'] as num?)?.toInt() ?? 0;
        final MyDenseWorldRank r = await _denseWorldRankForHighScore(myScore);
        if (controller.isClosed || g != publishGen) return;
        controller.add(r);
      }

      docSub = getPlayerDocStream(uid).listen(
        (DocumentSnapshot<Map<String, dynamic>> snap) {
          unawaited(publishForSnapshot(snap));
        },
        onError: (_) {
          if (!controller.isClosed) {
            controller.add((
              denseRank: 0,
              tiedWithOthersSameScore: false,
            ));
          }
        },
      );

      clockSub = Stream<int>.periodic(const Duration(seconds: 45)).listen(
        (_) {
          unawaited(() async {
            try {
              final DocumentSnapshot<Map<String, dynamic>> snap =
                  await ref.get();
              await publishForSnapshot(snap);
            } catch (_) {
              if (!controller.isClosed) {
                controller.add((
                  denseRank: 0,
                  tiedWithOthersSameScore: false,
                ));
              }
            }
          }());
        },
      );

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
      } catch (e) {
        attempt++;
        if (attempt >= 3 || !_isNetworkFirebaseException(e)) {
          rethrow;
        }
        await Future<void>.delayed(Duration(milliseconds: backoffMs));
        backoffMs = (backoffMs * 2).clamp(180, 1200);
      }
    }
  }

  /// Auth anonyme + doc joueur + lecture inventaire / skin actif (best-effort).
  ///
  /// Retourne `null` si pas de session cloud ; sinon paires optionnelles si la
  /// lecture Firestore a échoué.
  Future<({List<String>? inventory, String? activeSkinId})?>
  initializeAuthAndPullSkins() async {
    if (_authReady) {
      return await _pullSkinsSnapshot();
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
          final UserCredential cred =
              await FirebaseAuth.instance.signInAnonymously();
          u = cred.user;
        } catch (_) {
          return null;
        }
      }
      if (u == null) return null;
      _uid = u.uid;
      _authReady = true;

      try {
        final DocumentReference<Map<String, dynamic>> doc =
            _db.collection('players').doc(u.uid);
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

      final ({List<String>? inventory, String? activeSkinId})? skins =
          await _pullSkinsSnapshot();

      final int? hs = _pendingCloudHighScore;
      _pendingCloudHighScore = null;
      if (hs != null) {
        unawaited(syncHighScoreToCloud(hs));
      }
      final int? lux = _pendingCloudLuxCoins;
      _pendingCloudLuxCoins = null;
      if (lux != null) {
        unawaited(syncLuxToCloud(lux));
      }

      return skins;
    } finally {
      _authInitInProgress = false;
    }
  }

  Future<({List<String>? inventory, String? activeSkinId})?> _pullSkinsSnapshot() async {
    final DocumentReference<Map<String, dynamic>>? ref = _playerRef;
    if (!_authReady || ref == null) return null;
    try {
      final DocumentSnapshot<Map<String, dynamic>> me =
          await ref.get();
      final Map<String, dynamic>? d = me.data();
      final List<dynamic>? inv = d?['inventory'] as List<dynamic>?;
      final String? active = d?['activeSkinId'] as String?;
      final List<String>? inventory =
          inv?.map((dynamic e) => e.toString()).toList();
      return (inventory: inventory, activeSkinId: active);
    } catch (_) {
      return (inventory: null, activeSkinId: null);
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
    } catch (_) {
      _pendingCloudHighScore = score;
    }
  }

  Future<void> syncLuxToCloud(int amount) async {
    final DocumentReference<Map<String, dynamic>>? ref = _playerRef;
    if (!_authReady || ref == null) {
      _pendingCloudLuxCoins = amount;
      return;
    }
    try {
      await _firestoreRetry(() async {
        await ref.set(<String, dynamic>{
          'totalLux': amount,
          'lastSeen': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      });
    } catch (_) {
      _pendingCloudLuxCoins = amount;
    }
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
    } catch (_) {
      return false;
    }
  }

  /// `true` si le joueur doit voir la cérémonie de nom (pseudo placeholder + top 10).
  Future<bool> shouldOfferOracleNamingForNewHighScore(int newHighScore) async {
    final DocumentReference<Map<String, dynamic>>? ref = _playerRef;
    if (!_authReady || ref == null) return false;
    try {
      final DocumentSnapshot<Map<String, dynamic>> me =
          await _firestoreRetry(() => ref.get());
      final Map<String, dynamic>? d = me.data();
      final String? pseudo = d?['pseudo'] as String?;
      final bool needsName = pseudo == null ||
          pseudo.startsWith('Oracle_') ||
          pseudo.startsWith('oracle_');
      if (!needsName) return false;

      final QuerySnapshot<Map<String, dynamic>> top =
          await _firestoreRetry(() => _topTenQuery.get());
      final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs = top.docs;
      final bool inTop = docs.length < 10
          ? true
          : newHighScore >=
                ((docs.last.data()['highScore'] as num?)?.toInt() ?? 0);
      return inTop;
    } catch (_) {
      return false;
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
    } catch (_) {}
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
    } catch (_) {}
  }
}
