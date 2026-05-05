/**
 * Validation IAP côté serveur + crédit LUX idempotent.
 *
 * ## Android (Google Play)
 * 1. Compte de service + accès Finances dans la Play Console.
 * 2. Secret : `firebase functions:secrets:set GOOGLE_PLAY_SERVICE_ACCOUNT_JSON`
 * 3. Optionnel : `ANDROID_PACKAGE_NAME` (défaut `fr.grandjean.velour`).
 * La callable appelle `purchases.products.get` ; `purchaseState === 0` requis.
 *
 * ## iOS (App Store — StoreKit 2)
 * 1. Le client envoie le **JWS de transaction** (`verificationData.serverVerificationData`
 *    depuis `in_app_purchase_storekit`).
 * 2. Paramètre Cloud Functions : `APPLE_APP_STORE_APP_ID` = identifiant numérique Apple
 *    de l’app (App Store Connect → App → Informations générales → Identifiant Apple).
 *    Obligatoire pour valider les reçus **Production** ; le bac à sable est essayé
 *    automatiquement si l’environnement du JWS ne correspond pas.
 * 3. Certificats racine Apple : `functions/certs/*.cer` (G3 + G2), utilisés par
 *    `@apple/app-store-server-library` pour vérifier la chaîne x5c du JWS.
 *
 * ## Client Flutter
 * Après `PurchaseDetails` en `purchased`, appeler avec :
 * - Android : `platform: 'android'`, `productId`, `androidPurchaseToken`
 * - iOS : `platform: 'ios'`, `productId`, `iosTransactionJws` (JWS StoreKit 2)
 */
import * as crypto from "node:crypto";
import * as fs from "node:fs";
import * as path from "node:path";
import { GoogleAuth } from "google-auth-library";
import {
  Environment,
  SignedDataVerifier,
  Type as IapTransactionType,
  VerificationException,
  VerificationStatus,
} from "@apple/app-store-server-library";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import { defineSecret, defineString } from "firebase-functions/params";
import { FieldValue, getFirestore } from "firebase-admin/firestore";

const REGION = "europe-west3";

/** Callable gateway rejects invalid App Check when `VELOUR_ENFORCE_APP_CHECK=1` at runtime. */
const ENFORCE_APP_CHECK = process.env.VELOUR_ENFORCE_APP_CHECK === "1";

const googlePlayServiceAccountJson = defineSecret(
  "GOOGLE_PLAY_SERVICE_ACCOUNT_JSON"
);

/** Identifiant numérique Apple de l’app (requis pour vérifier les JWS Production). */
const appleAppStoreAppId = defineString("APPLE_APP_STORE_APP_ID", {
  default: "",
});

const MAX_IAP_LUX_GRANT = 10_000;

const VAULT_PRODUCT_LUX: Record<string, number> = {
  "com.velour.100lux": 100,
  "com.velour.750lux": 750,
  "com.velour.5000lux": 5000,
};

const DEFAULT_PACKAGE =
  process.env.ANDROID_PACKAGE_NAME || "fr.grandjean.velour";

const DEFAULT_IOS_BUNDLE_ID =
  process.env.APPLE_IOS_BUNDLE_ID || "fr.grandjean.velour";

interface AndroidProductPurchase {
  purchaseState?: number;
  orderId?: string;
}

let appleRootDerBuffers: Buffer[] | null = null;

function loadAppleRootCertificates(): Buffer[] {
  if (appleRootDerBuffers) {
    return appleRootDerBuffers;
  }
  const certsDir = path.join(__dirname, "..", "certs");
  const files = ["AppleRootCA-G3.cer", "AppleRootCA-G2.cer"];
  appleRootDerBuffers = files.map((name) => {
    const p = path.join(certsDir, name);
    if (!fs.existsSync(p)) {
      throw new Error(`Missing Apple root certificate: ${p}`);
    }
    return fs.readFileSync(p);
  });
  return appleRootDerBuffers;
}

function luxForProduct(productId: string): number {
  const n = VAULT_PRODUCT_LUX[productId];
  if (typeof n !== "number" || n <= 0) {
    throw new HttpsError("invalid-argument", "Unknown IAP productId");
  }
  return Math.min(MAX_IAP_LUX_GRANT, n);
}

function grantDocId(
  platform: string,
  productId: string,
  uniqueToken: string
): string {
  const h = crypto.createHash("sha256").update(uniqueToken).digest("hex");
  return `${platform}_${productId}_${h.slice(0, 48)}`;
}

function looksLikeCompactJws(s: string): boolean {
  const parts = s.split(".");
  return (
    parts.length === 3 &&
    parts[0].length > 0 &&
    parts[1].length > 0 &&
    parts[2].length > 0
  );
}

function isInvalidEnvironmentVerification(err: unknown): boolean {
  return (
    err instanceof VerificationException &&
    err.status === VerificationStatus.INVALID_ENVIRONMENT
  );
}

function mapAppleVerificationError(err: unknown): never {
  if (err instanceof HttpsError) {
    throw err;
  }
  if (err instanceof VerificationException) {
    logger.warn("apple_jws_verification_failed", {
      status: VerificationStatus[err.status] ?? err.status,
    });
    throw new HttpsError(
      "permission-denied",
      "Apple could not verify this transaction"
    );
  }
  const msg = err instanceof Error ? err.message : String(err);
  logger.warn("apple_jws_verification_error", { message: msg });
  throw new HttpsError(
    "internal",
    "Apple transaction verification failed"
  );
}

async function verifyIosStoreKit2Jws(
  signedTransaction: string,
  expectedProductId: string,
  bundleId: string,
  appAppleIdRaw: string
): Promise<{ transactionId: string }> {
  if (!looksLikeCompactJws(signedTransaction)) {
    throw new HttpsError(
      "invalid-argument",
      "iosTransactionJws must be the StoreKit 2 signed transaction JWS " +
        "(from PurchaseVerificationData.serverVerificationData on iOS)"
    );
  }

  const roots = loadAppleRootCertificates();
  const appAppleIdTrim = appAppleIdRaw.trim();
  const appAppleIdNum = parseInt(appAppleIdTrim, 10);
  if (!Number.isFinite(appAppleIdNum) || appAppleIdNum <= 0) {
    throw new HttpsError(
      "failed-precondition",
      "Set parameter APPLE_APP_STORE_APP_ID to the numeric Apple ID of this app " +
        "(App Store Connect → App → App Information)"
    );
  }

  const decodeWithEnv = async (
    env: Environment,
    appAppleId?: number
  ) => {
    const verifier = new SignedDataVerifier(
      roots,
      true,
      env,
      bundleId,
      appAppleId
    );
    return verifier.verifyAndDecodeTransaction(signedTransaction);
  };

  let decoded;
  try {
    decoded = await decodeWithEnv(Environment.PRODUCTION, appAppleIdNum);
  } catch (e) {
    if (isInvalidEnvironmentVerification(e)) {
      try {
        decoded = await decodeWithEnv(Environment.SANDBOX, undefined);
      } catch (e2) {
        mapAppleVerificationError(e2);
      }
    } else {
      mapAppleVerificationError(e);
    }
  }

  if (decoded.productId !== expectedProductId) {
    throw new HttpsError(
      "permission-denied",
      "Transaction product does not match request"
    );
  }
  if (decoded.revocationDate != null) {
    throw new HttpsError(
      "failed-precondition",
      "Transaction was revoked or refunded"
    );
  }
  const t = decoded.type;
  if (t !== IapTransactionType.CONSUMABLE && t !== "Consumable") {
    throw new HttpsError(
      "failed-precondition",
      "Not a consumable in-app purchase"
    );
  }
  const transactionId = decoded.transactionId?.trim() ?? "";
  if (!transactionId) {
    throw new HttpsError(
      "internal",
      "Missing transactionId in Apple-signed payload"
    );
  }

  return { transactionId };
}

async function verifyAndroidProductPurchase(
  serviceAccountJson: string,
  packageName: string,
  productId: string,
  purchaseToken: string
): Promise<{ orderId: string | null }> {
  const rawJson = serviceAccountJson;
  if (!rawJson || rawJson.trim().length === 0) {
    throw new HttpsError(
      "failed-precondition",
      "GOOGLE_PLAY_SERVICE_ACCOUNT_JSON secret is empty or missing"
    );
  }
  let credentials: Record<string, unknown>;
  try {
    credentials = JSON.parse(rawJson) as Record<string, unknown>;
  } catch {
    throw new HttpsError(
      "failed-precondition",
      "Invalid GOOGLE_PLAY_SERVICE_ACCOUNT_JSON"
    );
  }

  const auth = new GoogleAuth({
    credentials,
    scopes: ["https://www.googleapis.com/auth/androidpublisher"],
  });
  const client = await auth.getClient();
  const url =
    `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/` +
    `${encodeURIComponent(packageName)}/purchases/products/` +
    `${encodeURIComponent(productId)}/tokens/${encodeURIComponent(purchaseToken)}`;

  let body: AndroidProductPurchase;
  try {
    const res = await client.request<AndroidProductPurchase>({
      url,
      method: "GET",
    });
    body = (res.data as AndroidProductPurchase) || {};
  } catch (e: unknown) {
    const err = e as { response?: { status?: number; data?: unknown } };
    logger.warn("androidpublisher_get_failed", {
      status: err.response?.status,
      data: err.response?.data,
    });
    throw new HttpsError(
      "permission-denied",
      "Google Play could not validate this purchase token"
    );
  }

  if (body.purchaseState !== 0) {
    throw new HttpsError(
      "failed-precondition",
      `Purchase not in purchased state (state=${String(body.purchaseState)})`
    );
  }

  return { orderId: body.orderId ?? null };
}

/**
 * Vérifie un achat coffre-fort et crédite `totalLux` une seule fois par transaction.
 */
export const velourGrantIapLux = onCall(
  {
    region: REGION,
    secrets: [googlePlayServiceAccountJson],
    enforceAppCheck: ENFORCE_APP_CHECK,
  },
  async (request) => {
    if (!request.auth?.uid) {
      throw new HttpsError("unauthenticated", "Auth required");
    }
    const uid = request.auth.uid;
    const playSaJson = googlePlayServiceAccountJson.value();
    const appStoreNumericId = appleAppStoreAppId.value();

    const raw = request.data as {
      platform?: unknown;
      productId?: unknown;
      androidPurchaseToken?: unknown;
      iosTransactionJws?: unknown;
    };

    const platform =
      typeof raw.platform === "string" ? raw.platform.toLowerCase() : "";
    const productId =
      typeof raw.productId === "string" ? raw.productId.trim() : "";
    if (!productId || !(productId in VAULT_PRODUCT_LUX)) {
      throw new HttpsError("invalid-argument", "Invalid productId");
    }
    const lux = luxForProduct(productId);

    let uniqueKey: string;
    if (platform === "android") {
      const token =
        typeof raw.androidPurchaseToken === "string"
          ? raw.androidPurchaseToken.trim()
          : "";
      if (!token) {
        throw new HttpsError(
          "invalid-argument",
          "androidPurchaseToken is required for Android"
        );
      }
      await verifyAndroidProductPurchase(
        playSaJson,
        DEFAULT_PACKAGE,
        productId,
        token
      );
      uniqueKey = token;
    } else if (platform === "ios") {
      const jws =
        typeof raw.iosTransactionJws === "string"
          ? raw.iosTransactionJws.trim()
          : "";
      if (!jws) {
        throw new HttpsError(
          "invalid-argument",
          "iosTransactionJws is required for iOS"
        );
      }
      const { transactionId } = await verifyIosStoreKit2Jws(
        jws,
        productId,
        DEFAULT_IOS_BUNDLE_ID,
        appStoreNumericId
      );
      uniqueKey = transactionId;
    } else {
      throw new HttpsError(
        "invalid-argument",
        "platform must be 'android' or 'ios'"
      );
    }

    const grantId = grantDocId(platform, productId, uniqueKey);
    const db = getFirestore();
    const grantRef = db.collection("iap_grants").doc(grantId);
    const playerRef = db.collection("players").doc(uid);

    const out = await db.runTransaction(async (tx) => {
      const gSnap = await tx.get(grantRef);
      if (gSnap.exists) {
        const data = gSnap.data();
        const owner = data?.uid as string | undefined;
        if (owner != null && owner !== uid) {
          throw new HttpsError(
            "permission-denied",
            "This purchase was already recorded for another account"
          );
        }
        const grantedLux = data?.luxGranted as number | undefined;
        return {
          ok: true as const,
          alreadyGranted: true as const,
          luxGranted: typeof grantedLux === "number" ? grantedLux : lux,
          newLux: null as number | null,
        };
      }

      const pSnap = await tx.get(playerRef);
      const prev = pSnap.exists
        ? Math.max(0, Math.trunc((pSnap.get("totalLux") as number) || 0))
        : 0;
      const next = Math.max(0, prev + lux);

      tx.set(
        grantRef,
        {
          uid,
          platform,
          productId,
          luxGranted: lux,
          resultLux: lux,
          createdAt: FieldValue.serverTimestamp(),
        },
        { merge: false }
      );
      tx.set(
        playerRef,
        {
          totalLux: next,
          lastSeen: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true }
      );

      return {
        ok: true as const,
        alreadyGranted: false as const,
        luxGranted: lux,
        newLux: next,
      };
    });

    logger.info("VEL_IAP_GRANT", {
      code: out.alreadyGranted ? "VEL_IAP_GRANT_DUP" : "VEL_IAP_GRANT_NEW",
      uid,
      productId,
      platform,
      alreadyGranted: out.alreadyGranted,
      lux: out.luxGranted,
    });

    return out;
  }
);
