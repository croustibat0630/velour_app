/**
 * Cloud Functions Velour — callables authentifiées + économie LUX transactionnelle.
 *
 * Région alignée avec le client Flutter ([FirestoreService.cloudFunctionsRegion]).
 */
import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import { initializeApp } from "firebase-admin/app";
import { FieldValue, getFirestore } from "firebase-admin/firestore";

initializeApp();

const REGION = "europe-west3";

// Optional hardening: require Firebase App Check tokens on callable functions.
// Enable by setting env var `VELOUR_ENFORCE_APP_CHECK=1` for deployed Functions v2
// (via `functions/.env.<projectId>` consumed by Firebase CLI deploy, or Cloud Run env).
const ENFORCE_APP_CHECK = process.env.VELOUR_ENFORCE_APP_CHECK === "1";

/** Plafond crédit LUX positif par appel (aligné `lib/services/lux_credit_limits.dart`). */
const MAX_POSITIVE_LUX_DELTA = 10000;

/** Plafond débit par appel (mises, shop, rafales) — borne l’abus si le client est compromis. */
const MAX_NEGATIVE_LUX_MAGNITUDE = 500_000;

// Anti-abuse: cap daily positive credits (does not block normal gameplay, but
// limits scripted spam of callables on compromised clients).
const MAX_DAILY_POSITIVE_LUX = 50_000;

/** Limite d’appels [velourApplyLuxDelta] par minute et par joueur (anti-script). */
const MAX_LUX_APPLY_CALLS_PER_MINUTE = 90;

/** Codes logs Cloud Logging / filtres dashboards (`VEL_CF_*`). */
const CF_LUX_DELTA_CLAMPED = "VEL_CF_LUX_DELTA_CLAMPED";
const CF_LUX_DAILY_CAP_PARTIAL = "VEL_CF_LUX_DAILY_CAP_PARTIAL";
const CF_LUX_DAILY_CAP_BLOCK = "VEL_CF_LUX_DAILY_CAP_BLOCK";
const CF_LUX_RATE_LIMIT = "VEL_CF_LUX_RATE_LIMIT";
const CF_LUX_APPLY_OK = "VEL_CF_LUX_APPLY_OK";

/** Ping authentifié — vérifie le déploiement Functions + droits d’appel. */
export const velourHealth = onCall(
  { region: REGION, enforceAppCheck: ENFORCE_APP_CHECK },
  async (request) => {
    if (!request.auth?.uid) {
      throw new HttpsError("unauthenticated", "Auth required");
    }
    logger.info("VEL_CF_HEALTH_OK", {
      code: "VEL_CF_HEALTH_OK",
      uid: request.auth.uid,
    });
    return { ok: true as const, uid: request.auth.uid };
  },
);

/**
 * Applique un delta LUX sur `players/{uid}` en **transaction** (source de vérité serveur).
 *
 * Réponse : `{ ok, newLux, prevLux, appliedDelta }` — `appliedDelta` peut différer du
 * paramètre si plafonné côté serveur.
 */
export const velourApplyLuxDelta = onCall(
  { region: REGION, enforceAppCheck: ENFORCE_APP_CHECK },
  async (request) => {
    if (!request.auth?.uid) {
      throw new HttpsError("unauthenticated", "Auth required");
    }
    const uid = request.auth.uid;
    const raw = request.data as { delta?: unknown };
    const d0 =
      typeof raw.delta === "number" && Number.isFinite(raw.delta)
        ? Math.trunc(raw.delta)
        : NaN;
    if (!Number.isFinite(d0) || d0 === 0) {
      throw new HttpsError(
        "invalid-argument",
        "delta must be a non-zero finite integer"
      );
    }

    const appliedDelta = Math.min(
      MAX_POSITIVE_LUX_DELTA,
      Math.max(-MAX_NEGATIVE_LUX_MAGNITUDE, d0)
    );
    if (appliedDelta !== d0) {
      logger.warn(CF_LUX_DELTA_CLAMPED, {
        code: CF_LUX_DELTA_CLAMPED,
        uid,
        requested: d0,
        appliedDelta,
      });
    }

    const db = getFirestore();
    const ref = db.collection("players").doc(uid);

    const { prevLux, newLux, applied } = await db.runTransaction(
      async (tx) => {
        const snap = await tx.get(ref);
        const minuteEpoch = Math.floor(Date.now() / 60_000);
        const prevMin = snap.exists
          ? Math.trunc((snap.get("luxApplyMinuteEpoch") as number) || 0)
          : 0;
        const prevMinCount = snap.exists
          ? Math.max(0, Math.trunc((snap.get("luxApplyMinuteCount") as number) || 0))
          : 0;
        const minuteCount =
          prevMin === minuteEpoch ? prevMinCount + 1 : 1;
        if (minuteCount > MAX_LUX_APPLY_CALLS_PER_MINUTE) {
          logger.warn(CF_LUX_RATE_LIMIT, {
            code: CF_LUX_RATE_LIMIT,
            uid,
            minuteEpoch,
            minuteCount,
            max: MAX_LUX_APPLY_CALLS_PER_MINUTE,
          });
          throw new HttpsError(
            "resource-exhausted",
            "Lux apply rate limit — retry later"
          );
        }

        const prev = snap.exists
          ? Math.max(0, Math.trunc((snap.get("totalLux") as number) || 0))
          : 0;
        // Daily cap (positive only).
        const day =
          Math.floor(Date.now() / (24 * 60 * 60 * 1000)) /* UTC-ish day index */;
        const prevDay = snap.exists
          ? Math.trunc((snap.get("dailyPositiveLuxDay") as number) || 0)
          : 0;
        const prevDaily = snap.exists
          ? Math.max(0, Math.trunc((snap.get("dailyPositiveLux") as number) || 0))
          : 0;
        const daily = prevDay === day ? prevDaily : 0;
        const budget =
          appliedDelta > 0 ? Math.max(0, MAX_DAILY_POSITIVE_LUX - daily) : 0;
        const clampedForDay =
          appliedDelta > 0 ? Math.min(appliedDelta, budget) : appliedDelta;

        if (appliedDelta > 0 && clampedForDay === 0) {
          logger.warn(CF_LUX_DAILY_CAP_BLOCK, {
            code: CF_LUX_DAILY_CAP_BLOCK,
            uid,
            day,
            daily,
            requested: appliedDelta,
          });
        } else if (appliedDelta > 0 && clampedForDay < appliedDelta) {
          logger.warn(CF_LUX_DAILY_CAP_PARTIAL, {
            code: CF_LUX_DAILY_CAP_PARTIAL,
            uid,
            day,
            daily,
            requested: appliedDelta,
            applied: clampedForDay,
          });
        }

        const next = Math.max(0, prev + clampedForDay);
        tx.set(
          ref,
          {
            totalLux: next,
            lastSeen: FieldValue.serverTimestamp(),
            updatedAt: FieldValue.serverTimestamp(),
            dailyPositiveLuxDay: day,
            dailyPositiveLux:
              clampedForDay > 0 ? daily + clampedForDay : daily,
            luxApplyMinuteEpoch: minuteEpoch,
            luxApplyMinuteCount: minuteCount,
          },
          { merge: true }
        );
        return { prevLux: prev, newLux: next, applied: clampedForDay };
      }
    );

    logger.info(CF_LUX_APPLY_OK, {
      code: CF_LUX_APPLY_OK,
      uid,
      prevLux,
      newLux,
      appliedDelta: applied,
    });

    return {
      ok: true as const,
      newLux,
      prevLux,
      appliedDelta: applied,
    };
  },
);

export { velourGrantIapLux } from "./iap";
export { velourMirrorPlayerToLeaderboardPublic } from "./leaderboardPublic";
