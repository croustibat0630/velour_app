/**
 * Miroir public du classement : `leaderboardPublic/{uid}` (pseudo, highScore, updatedAt).
 * Synchronisé depuis `players/{uid}` pour que les règles puissent restreindre la lecture
 * des profils complets au propriétaire uniquement.
 */
import { onDocumentWritten } from "firebase-functions/v2/firestore";
import * as logger from "firebase-functions/logger";
import {
  FieldValue,
  getFirestore,
  Timestamp,
} from "firebase-admin/firestore";

const REGION = "europe-west3";

export const velourMirrorPlayerToLeaderboardPublic = onDocumentWritten(
  { document: "players/{uid}", region: REGION },
  async (event) => {
    const uid = event.params.uid as string;
    const db = getFirestore();
    const pubRef = db.collection("leaderboardPublic").doc(uid);

    if (!event.data?.after.exists) {
      try {
        await pubRef.delete();
      } catch (e) {
        logger.warn("VEL_LB_PUBLIC_DELETE_FAILED", {
          code: "VEL_LB_PUBLIC_DELETE_FAILED",
          uid,
          err: String(e),
        });
      }
      return;
    }

    const d = event.data.after.data() as Record<string, unknown>;
    const highScore = Math.max(0, Math.trunc((d.highScore as number) || 0));
    const updatedAt =
      d.updatedAt instanceof Timestamp
        ? d.updatedAt
        : FieldValue.serverTimestamp();

    const payload: Record<string, unknown> = {
      highScore,
      updatedAt,
    };

    const rawPseudo = d.pseudo;
    if (typeof rawPseudo === "string" && rawPseudo.trim().length > 0) {
      payload.pseudo = rawPseudo.trim().slice(0, 15);
    } else {
      payload.pseudo = FieldValue.delete();
    }

    try {
      await pubRef.set(payload, { merge: false });
    } catch (e) {
      logger.error("VEL_LB_PUBLIC_MIRROR_FAILED", {
        code: "VEL_LB_PUBLIC_MIRROR_FAILED",
        uid,
        err: String(e),
      });
    }
  }
);
