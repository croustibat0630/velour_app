/**
 * Copie chaque doc `players/{uid}` vers `leaderboardPublic/{uid}` (highScore, pseudo, updatedAt).
 * À lancer **après** déploiement du trigger `velourMirrorPlayerToLeaderboardPublic` et **avant**
 * de resserrer les règles `players` (lecture owner-only), ou pour réparer un écart historique.
 *
 *   cd functions && npm ci
 *   export GOOGLE_APPLICATION_CREDENTIALS="$HOME/.../service-account.json"
 *   node scripts/backfillLeaderboardPublicAdmin.js
 *   node scripts/backfillLeaderboardPublicAdmin.js --execute   (sinon dry-run)
 */
/* eslint-disable no-console */

const fs = require('fs');
const admin = require('firebase-admin');
const { FieldValue, FieldPath } = require('firebase-admin/firestore');

function assertServiceAccountFileIfSet() {
  const p = process.env.GOOGLE_APPLICATION_CREDENTIALS;
  if (!p || p.trim() === '') return;
  if (!fs.existsSync(p)) {
    throw new Error(
      `Fichier introuvable : GOOGLE_APPLICATION_CREDENTIALS=${p}\n` +
        'Exporte le chemin absolu vers la clé JSON du compte de service.',
    );
  }
}

function parseExecute() {
  return process.argv.includes('--execute');
}

function printHelp() {
  console.log(`Velour — backfill leaderboardPublic depuis players (Admin SDK)

Sans --execute : compte les docs et affiche un échantillon (dry-run).
Avec --execute  : écrit dans leaderboardPublic par lots de 400.

  node scripts/backfillLeaderboardPublicAdmin.js
  node scripts/backfillLeaderboardPublicAdmin.js --execute

Prérequis : GOOGLE_APPLICATION_CREDENTIALS pointant vers un compte de service Firebase.
`);
}

async function main() {
  if (process.argv.includes('--help')) {
    printHelp();
    process.exit(0);
  }
  assertServiceAccountFileIfSet();
  const execute = parseExecute();

  if (!admin.apps.length) {
    admin.initializeApp();
  }
  const db = admin.firestore();

  let processed = 0;
  let written = 0;
  let last = null;
  const sample = [];

  // eslint-disable-next-line no-constant-condition
  while (true) {
    let q = db.collection('players').orderBy(FieldPath.documentId()).limit(400);
    if (last) {
      q = q.startAfter(last);
    }
    const snap = await q.get();
    if (snap.empty) break;

    const batch = db.batch();
    for (const doc of snap.docs) {
      processed++;
      const uid = doc.id;
      const d = doc.data() || {};
      const highScore = Math.max(0, Math.trunc(Number(d.highScore) || 0));
      let updatedAt = d.updatedAt;
      if (!updatedAt) {
        updatedAt = FieldValue.serverTimestamp();
      }
      const payload = { highScore, updatedAt };
      const raw = d.pseudo;
      if (typeof raw === 'string' && raw.trim().length > 0) {
        payload.pseudo = raw.trim().slice(0, 15);
      }
      if (sample.length < 3) {
        sample.push({ uid, highScore, hasPseudo: !!payload.pseudo });
      }
      if (execute) {
        batch.set(db.collection('leaderboardPublic').doc(uid), payload, { merge: false });
        written++;
      }
    }
    if (execute) {
      await batch.commit();
    }
    last = snap.docs[snap.docs.length - 1];
  }

  console.log(
    execute
      ? `OK — ${written} documents écrits dans leaderboardPublic (${processed} players parcourus).`
      : `Dry-run — ${processed} players. Relance avec --execute pour écrire. Exemple :`,
  );
  if (!execute) {
    console.log(JSON.stringify(sample, null, 2));
  }
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
