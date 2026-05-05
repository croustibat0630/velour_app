import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firestore_service.dart';
import 'velour_observability.dart';

/// Réponse de la callable [velourGrantIapLux] (`functions/src/iap.ts`).
typedef IapCloudGrantResult = ({
  bool ok,
  bool alreadyGranted,
  int? luxGranted,
  int? newLux,
});

/// Appelle la validation IAP serveur + crédit LUX idempotent.
///
/// **Android** : passe le jeton d’achat (souvent
/// `purchaseDetails.verificationData.serverVerificationData`).
///
/// **iOS** : envoyer le JWS StoreKit 2 (`serverVerificationData` côté plugin) ;
/// la Function valide via `@apple/app-store-server-library` (paramètre
/// `APPLE_APP_STORE_APP_ID` côté Cloud Functions).
///
/// À intégrer dans le flux boutique **après** succès store et **avant** de
/// considérer les LUX comme définitivement acquis côté cloud (voir
/// [LuxIapService] / `finalizeAfterLuxDelivered`).
class IapCloudGrantService {
  IapCloudGrantService._();

  static Future<IapCloudGrantResult?> tryGrantVaultPurchase({
    required String platform,
    required String productId,
    String? androidPurchaseToken,
    String? iosTransactionJws,
  }) async {
    try {
      if (Firebase.apps.isEmpty) return null;
    } catch (_) {
      return null;
    }

    await FirestoreService.instance.ensureAnonymousAuthReady();

    if (FirebaseAuth.instance.currentUser == null) {
      VelourObservability.recordClientFailure(
        VelourObsCodes.iapCloudGrantNoUser,
        StateError('anonymous auth not ready'),
      );
      return null;
    }

    try {
      final FirebaseFunctions fns = FirebaseFunctions.instanceFor(
        app: Firebase.app(),
        region: FirestoreService.cloudFunctionsRegion,
      );
      final HttpsCallable callable = fns.httpsCallable(
        'velourGrantIapLux',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
      );
      final Map<String, dynamic> payload = <String, dynamic>{
        'platform': platform,
        'productId': productId,
      };
      if (androidPurchaseToken != null) {
        payload['androidPurchaseToken'] = androidPurchaseToken;
      }
      if (iosTransactionJws != null) {
        payload['iosTransactionJws'] = iosTransactionJws;
      }
      final HttpsCallableResult res = await callable.call(payload);
      final Object? data = res.data;
      if (data is! Map) {
        return null;
      }
      final Map<String, dynamic> raw = Map<String, dynamic>.from(data);
      final bool ok = raw['ok'] == true;
      final bool alreadyGranted = raw['alreadyGranted'] == true;
      final int? luxGranted = (raw['luxGranted'] as num?)?.toInt();
      final int? newLux = (raw['newLux'] as num?)?.toInt();
      return (
        ok: ok,
        alreadyGranted: alreadyGranted,
        luxGranted: luxGranted,
        newLux: newLux,
      );
    } on FirebaseFunctionsException catch (e, st) {
      VelourObservability.logFirestoreFailure(
        VelourObsCodes.iapCloudGrantCallable,
        error: e,
        stackTrace: st,
        context: <String, Object?>{
          'code': e.code,
          'details': e.details?.toString(),
          'productId': productId,
        },
      );
      return null;
    } catch (e, st) {
      VelourObservability.logFirestoreFailure(
        VelourObsCodes.iapCloudGrantUnknown,
        error: e,
        stackTrace: st,
        context: <String, Object?>{'productId': productId},
      );
      return null;
    }
  }
}
