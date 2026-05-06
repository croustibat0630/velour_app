/**
 * Cloud Functions Velour — callables authentifiées + économie LUX transactionnelle.
 *
 * Région alignée avec le client Flutter ([FirestoreService.cloudFunctionsRegion]).
 */
import { createHash } from "node:crypto";
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

/** Motifs connus (client + serveur) — toute autre valeur est rejetée. */
const LUX_MOTIF_CLIENT_SYNC = "velour_client_sync";
const LUX_MOTIF_BOOTSTRAP_RECONCILE = "bootstrap_reconcile";
const LUX_MOTIF_WELCOME_GRANT = "welcome_grant";
const LUX_MOTIF_SHOP_SKIN = "shop_skin";
const LUX_MOTIF_SHOP_FORGE = "shop_forge_consumable";
const LUX_MOTIF_STAKE_ANTE = "stake_ante";
const LUX_MOTIF_STAKE_REWARD = "stake_reward";
const LUX_MOTIF_ORACLE_REFUND = "oracle_insurance_refund";
const LUX_MOTIF_VAULT_SOFT = "vault_soft_credit";

/** Aligné `GameState.highStakesAnteLux` / `SessionStakeConstants.royalAnteLux`. */
const STAKE_ANTE_HIGH = 50;
const STAKE_ANTE_ROYAL = 250;

/** Aligné `GameState` forge (prix unitaires). */
const FORGE_PRICE_ORACLE_INSURANCE = 200;
const FORGE_PRICE_ROYAL_BOUNTY = 350;
const FORGE_PRICE_CHRONO_PULSE = 175;
const FORGE_PRICE_MERCY_SALVAGE = 220;

/**
 * Plafond journalier **par motif** (crédits positifs cumulés sur `luxMotifDailyDay`).
 * Les motifs absents ne sont limités que par [MAX_DAILY_POSITIVE_LUX].
 */
const MOTIF_DAILY_POSITIVE_CAP: Partial<Record<string, number>> = {
  [LUX_MOTIF_STAKE_REWARD]: 40_000,
  [LUX_MOTIF_ORACLE_REFUND]: 4_000,
  [LUX_MOTIF_WELCOME_GRANT]: 500,
  [LUX_MOTIF_VAULT_SOFT]: 20_000,
};

const ALLOWED_LUX_MOTIFS = new Set<string>([
  LUX_MOTIF_CLIENT_SYNC,
  LUX_MOTIF_BOOTSTRAP_RECONCILE,
  LUX_MOTIF_WELCOME_GRANT,
  LUX_MOTIF_SHOP_SKIN,
  LUX_MOTIF_SHOP_FORGE,
  LUX_MOTIF_STAKE_ANTE,
  LUX_MOTIF_STAKE_REWARD,
  LUX_MOTIF_ORACLE_REFUND,
  LUX_MOTIF_VAULT_SOFT,
]);

const MAX_IDEMPOTENCY_KEY_LEN = 200;

/** Codes logs Cloud Logging / filtres dashboards (`VEL_CF_*`). */
const CF_LUX_DELTA_CLAMPED = "VEL_CF_LUX_DELTA_CLAMPED";
const CF_LUX_DAILY_CAP_PARTIAL = "VEL_CF_LUX_DAILY_CAP_PARTIAL";
const CF_LUX_DAILY_CAP_BLOCK = "VEL_CF_LUX_DAILY_CAP_BLOCK";
const CF_LUX_RATE_LIMIT = "VEL_CF_LUX_RATE_LIMIT";
const CF_LUX_APPLY_OK = "VEL_CF_LUX_APPLY_OK";
const CF_LUX_MOTIF_INVALID = "VEL_CF_LUX_MOTIF_INVALID";
const CF_LUX_DEDUP_HIT = "VEL_CF_LUX_DEDUP_HIT";
const CF_LUX_LEDGER_WRITTEN = "VEL_CF_LUX_LEDGER_WRITTEN";
const CF_LUX_MOTIF_DELTA_REJECTED = "VEL_CF_LUX_MOTIF_DELTA_REJECTED";
const CF_LUX_MOTIF_DAILY_CAP_PARTIAL = "VEL_CF_LUX_MOTIF_DAILY_CAP_PARTIAL";
const CF_LUX_MOTIF_DAILY_CAP_BLOCK = "VEL_CF_LUX_MOTIF_DAILY_CAP_BLOCK";

function luxMotifCaps(motif: string): {
  maxPositive: number;
  maxNegativeMagnitude: number;
} {
  switch (motif) {
    case LUX_MOTIF_WELCOME_GRANT:
      return { maxPositive: 300, maxNegativeMagnitude: 0 };
    case LUX_MOTIF_SHOP_SKIN:
      return {
        maxPositive: MAX_POSITIVE_LUX_DELTA,
        maxNegativeMagnitude: MAX_NEGATIVE_LUX_MAGNITUDE,
      };
    case LUX_MOTIF_SHOP_FORGE:
      return { maxPositive: 0, maxNegativeMagnitude: 500 };
    case LUX_MOTIF_STAKE_ANTE:
      return { maxPositive: 0, maxNegativeMagnitude: 500 };
    case LUX_MOTIF_STAKE_REWARD:
      return { maxPositive: MAX_POSITIVE_LUX_DELTA, maxNegativeMagnitude: 0 };
    case LUX_MOTIF_ORACLE_REFUND:
      return { maxPositive: 500, maxNegativeMagnitude: 0 };
    case LUX_MOTIF_VAULT_SOFT:
      return { maxPositive: MAX_POSITIVE_LUX_DELTA, maxNegativeMagnitude: 0 };
    case LUX_MOTIF_BOOTSTRAP_RECONCILE:
    case LUX_MOTIF_CLIENT_SYNC:
      return {
        maxPositive: MAX_POSITIVE_LUX_DELTA,
        maxNegativeMagnitude: MAX_NEGATIVE_LUX_MAGNITUDE,
      };
    default:
      return {
        maxPositive: MAX_POSITIVE_LUX_DELTA,
        maxNegativeMagnitude: MAX_NEGATIVE_LUX_MAGNITUDE,
      };
  }
}

function luxDedupDocId(uid: string, idempotencyKey: string): string {
  return createHash("sha256")
    .update(`${uid}\n${idempotencyKey}`, "utf8")
    .digest("hex");
}

function rejectMotifDelta(
  motif: string,
  d0: number,
  message: string
): never {
  logger.warn(CF_LUX_MOTIF_DELTA_REJECTED, {
    code: CF_LUX_MOTIF_DELTA_REJECTED,
    motif,
    delta: d0,
    message,
  });
  throw new HttpsError("invalid-argument", message);
}

/** Montants discrets attendus par motif (hors bootstrap / client_sync). */
function assertDeltaAllowedForMotif(motif: string, d0: number): void {
  const oracleRefundHigh = Math.trunc((STAKE_ANTE_HIGH * 60) / 100);
  const oracleRefundRoyal = Math.trunc((STAKE_ANTE_ROYAL * 60) / 100);

  switch (motif) {
    case LUX_MOTIF_STAKE_ANTE:
      if (d0 !== -STAKE_ANTE_HIGH && d0 !== -STAKE_ANTE_ROYAL) {
        rejectMotifDelta(
          motif,
          d0,
          "stake_ante: delta must match a known ante (-50 or -250)"
        );
      }
      break;
    case LUX_MOTIF_SHOP_FORGE: {
      const forgeOk = new Set([
        -FORGE_PRICE_ORACLE_INSURANCE,
        -FORGE_PRICE_ROYAL_BOUNTY,
        -FORGE_PRICE_CHRONO_PULSE,
        -FORGE_PRICE_MERCY_SALVAGE,
      ]);
      if (!forgeOk.has(d0)) {
        rejectMotifDelta(
          motif,
          d0,
          "shop_forge_consumable: delta must match a forge shop price"
        );
      }
      break;
    }
    case LUX_MOTIF_ORACLE_REFUND:
      if (d0 !== oracleRefundHigh && d0 !== oracleRefundRoyal) {
        rejectMotifDelta(
          motif,
          d0,
          "oracle_insurance_refund: delta must match configured refund amounts"
        );
      }
      break;
    case LUX_MOTIF_STAKE_REWARD:
      if (d0 < 1 || d0 > 2600) {
        rejectMotifDelta(motif, d0, "stake_reward: delta out of allowed range");
      }
      break;
    case LUX_MOTIF_WELCOME_GRANT:
      if (d0 < 1 || d0 > 300) {
        rejectMotifDelta(motif, d0, "welcome_grant: delta out of allowed range");
      }
      break;
    case LUX_MOTIF_VAULT_SOFT:
      if (d0 < 1 || d0 > MAX_POSITIVE_LUX_DELTA) {
        rejectMotifDelta(
          motif,
          d0,
          "vault_soft_credit: delta out of allowed range"
        );
      }
      break;
    case LUX_MOTIF_SHOP_SKIN:
      if (d0 >= 0) {
        rejectMotifDelta(
          motif,
          d0,
          "shop_skin: only negative purchase debits are allowed"
        );
      }
      break;
    default:
      break;
  }
}

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
 * Corps attendu : `{ delta, motif, idempotencyKey? }`.
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
    const raw = request.data as {
      delta?: unknown;
      motif?: unknown;
      idempotencyKey?: unknown;
    };

    const motifRaw =
      typeof raw.motif === "string" ? raw.motif.trim() : "";
    if (!motifRaw || !ALLOWED_LUX_MOTIFS.has(motifRaw)) {
      logger.warn(CF_LUX_MOTIF_INVALID, {
        code: CF_LUX_MOTIF_INVALID,
        uid,
        motif: motifRaw || null,
      });
      throw new HttpsError(
        "invalid-argument",
        "motif must be a known non-empty string (e.g. velour_client_sync)"
      );
    }
    const motif = motifRaw;

    let idempotencyKey: string | null = null;
    if (raw.idempotencyKey !== undefined && raw.idempotencyKey !== null) {
      if (typeof raw.idempotencyKey !== "string") {
        throw new HttpsError(
          "invalid-argument",
          "idempotencyKey must be a string when provided"
        );
      }
      const trimmed = raw.idempotencyKey.trim();
      if (trimmed.length === 0 || trimmed.length > MAX_IDEMPOTENCY_KEY_LEN) {
        throw new HttpsError(
          "invalid-argument",
          "idempotencyKey must be 1–200 characters after trim"
        );
      }
      idempotencyKey = trimmed;
    }

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

    assertDeltaAllowedForMotif(motif, d0);

    const caps = luxMotifCaps(motif);
    const appliedDelta = Math.min(
      caps.maxPositive,
      Math.max(-caps.maxNegativeMagnitude, d0)
    );
    if (appliedDelta !== d0) {
      logger.warn(CF_LUX_DELTA_CLAMPED, {
        code: CF_LUX_DELTA_CLAMPED,
        uid,
        motif,
        requested: d0,
        appliedDelta,
      });
    }
    if (appliedDelta === 0) {
      throw new HttpsError(
        "invalid-argument",
        "delta is incompatible with motif caps (would apply 0)"
      );
    }

    const db = getFirestore();
    const ref = db.collection("players").doc(uid);
    const dedupId = idempotencyKey
      ? luxDedupDocId(uid, idempotencyKey)
      : null;

    const { prevLux, newLux, applied, fromDedup } = await db.runTransaction(
      async (tx) => {
        if (dedupId) {
          const dedRef = ref.collection("luxDedup").doc(dedupId);
          const dedSnap = await tx.get(dedRef);
          if (dedSnap.exists) {
            const dr = dedSnap.data();
            const nl = dr?.newLux;
            const pl = dr?.prevLux;
            const ad = dr?.appliedDelta;
            if (
              typeof nl === "number" &&
              Number.isFinite(nl) &&
              typeof pl === "number" &&
              Number.isFinite(pl) &&
              typeof ad === "number" &&
              Number.isFinite(ad)
            ) {
              return {
                fromDedup: true as const,
                prevLux: Math.trunc(pl),
                newLux: Math.max(0, Math.trunc(nl)),
                applied: Math.trunc(ad),
              };
            }
          }
        }

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
            motif,
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
        const day =
          Math.floor(Date.now() / (24 * 60 * 60 * 1000)) /* UTC-ish day index */;

        const prevMotifDay = snap.exists
          ? Math.trunc((snap.get("luxMotifDailyDay") as number) || 0)
          : 0;
        let motifDailyPos: Record<string, number> = {};
        if (snap.exists) {
          const rawMot = snap.get("luxMotifDailyPositive");
          if (
            rawMot != null &&
            typeof rawMot === "object" &&
            !Array.isArray(rawMot)
          ) {
            for (const [k, v] of Object.entries(
              rawMot as Record<string, unknown>
            )) {
              if (typeof v === "number" && Number.isFinite(v)) {
                motifDailyPos[k] = Math.max(0, Math.trunc(v));
              }
            }
          }
        }
        if (prevMotifDay !== day) {
          motifDailyPos = {};
        }

        let afterMotifDaily = appliedDelta;
        const motifDailyCap = MOTIF_DAILY_POSITIVE_CAP[motif];
        if (appliedDelta > 0 && typeof motifDailyCap === "number") {
          const usedMotif = Math.max(0, Math.trunc(motifDailyPos[motif] || 0));
          const budgetMotif = Math.max(0, motifDailyCap - usedMotif);
          afterMotifDaily = Math.min(appliedDelta, budgetMotif);
          if (afterMotifDaily === 0 && appliedDelta > 0) {
            logger.warn(CF_LUX_MOTIF_DAILY_CAP_BLOCK, {
              code: CF_LUX_MOTIF_DAILY_CAP_BLOCK,
              uid,
              motif,
              day,
              motifDailyUsed: usedMotif,
              motifDailyCap,
              requested: appliedDelta,
            });
          } else if (afterMotifDaily < appliedDelta) {
            logger.warn(CF_LUX_MOTIF_DAILY_CAP_PARTIAL, {
              code: CF_LUX_MOTIF_DAILY_CAP_PARTIAL,
              uid,
              motif,
              day,
              motifDailyUsed: usedMotif,
              motifDailyCap,
              requested: appliedDelta,
              applied: afterMotifDaily,
            });
          }
        }

        // Daily cap global (positifs), après cap par motif.
        const prevDay = snap.exists
          ? Math.trunc((snap.get("dailyPositiveLuxDay") as number) || 0)
          : 0;
        const prevDaily = snap.exists
          ? Math.max(0, Math.trunc((snap.get("dailyPositiveLux") as number) || 0))
          : 0;
        const daily = prevDay === day ? prevDaily : 0;
        const budget =
          afterMotifDaily > 0
            ? Math.max(0, MAX_DAILY_POSITIVE_LUX - daily)
            : 0;
        const clampedForDay =
          afterMotifDaily > 0
            ? Math.min(afterMotifDaily, budget)
            : afterMotifDaily;

        if (afterMotifDaily > 0 && clampedForDay === 0) {
          logger.warn(CF_LUX_DAILY_CAP_BLOCK, {
            code: CF_LUX_DAILY_CAP_BLOCK,
            uid,
            motif,
            day,
            daily,
            requested: afterMotifDaily,
          });
        } else if (afterMotifDaily > 0 && clampedForDay < afterMotifDaily) {
          logger.warn(CF_LUX_DAILY_CAP_PARTIAL, {
            code: CF_LUX_DAILY_CAP_PARTIAL,
            uid,
            motif,
            day,
            daily,
            requested: afterMotifDaily,
            applied: clampedForDay,
          });
        }

        const appliedLocal = clampedForDay;
        const next = Math.max(0, prev + appliedLocal);

        const nextMotifDailyPos: Record<string, number> = { ...motifDailyPos };
        if (appliedLocal > 0 && typeof motifDailyCap === "number") {
          const usedBefore = Math.max(0, Math.trunc(motifDailyPos[motif] || 0));
          nextMotifDailyPos[motif] = usedBefore + appliedLocal;
        }

        tx.set(
          ref,
          {
            totalLux: next,
            lastSeen: FieldValue.serverTimestamp(),
            updatedAt: FieldValue.serverTimestamp(),
            dailyPositiveLuxDay: day,
            dailyPositiveLux:
              appliedLocal > 0 ? daily + appliedLocal : daily,
            luxMotifDailyDay: day,
            luxMotifDailyPositive: nextMotifDailyPos,
            luxApplyMinuteEpoch: minuteEpoch,
            luxApplyMinuteCount: minuteCount,
          },
          { merge: true }
        );

        if (dedupId && idempotencyKey) {
          tx.set(ref.collection("luxDedup").doc(dedupId), {
            prevLux: prev,
            newLux: next,
            appliedDelta: appliedLocal,
            motif,
            createdAt: FieldValue.serverTimestamp(),
          });
        }

        if (appliedLocal !== 0) {
          const ledgerRef = ref.collection("luxLedger").doc();
          tx.set(ledgerRef, {
            motif,
            prevLux: prev,
            newLux: next,
            appliedDelta: appliedLocal,
            createdAt: FieldValue.serverTimestamp(),
          });
        }

        return {
          fromDedup: false as const,
          prevLux: prev,
          newLux: next,
          applied: appliedLocal,
        };
      }
    );

    if (fromDedup) {
      logger.info(CF_LUX_DEDUP_HIT, {
        code: CF_LUX_DEDUP_HIT,
        uid,
        motif,
        prevLux,
        newLux,
        appliedDelta: applied,
      });
    } else {
      logger.info(CF_LUX_APPLY_OK, {
        code: CF_LUX_APPLY_OK,
        uid,
        motif,
        prevLux,
        newLux,
        appliedDelta: applied,
      });
      if (applied !== 0) {
        logger.info(CF_LUX_LEDGER_WRITTEN, {
          code: CF_LUX_LEDGER_WRITTEN,
          uid,
          motif,
          appliedDelta: applied,
        });
      }
    }

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
