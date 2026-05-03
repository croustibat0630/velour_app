/**
 * Script admin (firebase-admin) : nettoyage des pseudos sur `players/{uid}`.
 *
 * - Pseudo invalide → champ [pseudo] supprimé.
 * - Pseudo valide → minuscules (casse stockage type [OraclePseudo]).
 * - Option [--backfill-updated-at] : [updatedAt] manquant → [lastSeen] ou serveur.
 *
 *   cd functions && npm ci
 *   Remplace le chemin par la vraie clé JSON (Console Firebase → ⚙ projet →
 *   Comptes de service → Générer une nouvelle clé privée) :
 *   export GOOGLE_APPLICATION_CREDENTIALS="$HOME/chemin/vers/velour-adminsdk.json"
 *   (ne pas laisser l’exemple littéral « /chemin/vers/… ».)
 *
 *   node scripts/normalizePlayerPseudos.js --dry-run --verbose
 *   node scripts/normalizePlayerPseudos.js --uid=UID_FIREBASE --dry-run --verbose
 *   node scripts/normalizePlayerPseudos.js --max-docs=500 --dry-run
 *   node scripts/normalizePlayerPseudos.js --backfill-updated-at
 *
 * Logs : résumé JSON sur stdout ; avec [--verbose], une ligne JSON par doc
 * modifiée sur stderr (préfixe type `velour.admin.normalizePlayer.verbose`).
 */

const fs = require('fs');
const admin = require('firebase-admin');

function assertServiceAccountFileIfSet() {
  const p = process.env.GOOGLE_APPLICATION_CREDENTIALS;
  if (!p || p.trim() === '') return;
  if (!fs.existsSync(p)) {
    throw new Error(
      `Fichier introuvable : GOOGLE_APPLICATION_CREDENTIALS=${p}\n` +
        'Télécharge la clé JSON du compte de service (Firebase Console → ' +
        'Paramètres du projet → Comptes de service), puis exporte le chemin absolu, ' +
        'par exemple :\n' +
        '  export GOOGLE_APPLICATION_CREDENTIALS="$HOME/keys/velour-service-account.json"',
    );
  }
  if (!fs.statSync(p).isFile()) {
    throw new Error(`GOOGLE_APPLICATION_CREDENTIALS doit être un fichier : ${p}`);
  }
}

function resolveProjectIdForSummary() {
  if (admin.apps.length > 0) {
    const id = admin.app().options.projectId;
    if (id) return id;
  }
  const credPath = process.env.GOOGLE_APPLICATION_CREDENTIALS;
  if (credPath && fs.existsSync(credPath)) {
    try {
      const j = JSON.parse(fs.readFileSync(credPath, 'utf8'));
      if (typeof j.project_id === 'string' && j.project_id.length > 0) {
        return j.project_id;
      }
    } catch (_) {}
  }
  return process.env.GCLOUD_PROJECT || process.env.GCP_PROJECT || null;
}

const PSEUDO_OK = /^[A-Za-z0-9_]{1,15}$/;

function parseArg(name) {
  const prefix = `${name}=`;
  const hit = process.argv.find((a) => a.startsWith(prefix));
  return hit ? hit.slice(prefix.length) : null;
}

function parsePositiveInt(name) {
  const raw = parseArg(name);
  if (raw == null || raw === '') return null;
  const n = Number.parseInt(raw, 10);
  if (!Number.isFinite(n) || n < 1) {
    throw new Error(`Argument ${name}= doit être un entier >= 1 (reçu: ${raw})`);
  }
  return n;
}

function planPseudoUpdate(raw) {
  if (raw === undefined) return null;
  if (typeof raw !== 'string') return { op: 'delete' };
  const t = raw.trim();
  if (t.length === 0) return { op: 'delete' };
  if (!PSEUDO_OK.test(t)) return { op: 'delete' };
  const lower = t.toLowerCase();
  if (lower !== raw) return { op: 'set', value: lower };
  return null;
}

function planUpdatedAtUpdate(data) {
  if (data.updatedAt !== undefined && data.updatedAt !== null) return null;
  if (data.lastSeen !== undefined && data.lastSeen !== null) {
    return { op: 'copyLastSeen', value: data.lastSeen };
  }
  return { op: 'server' };
}

function buildUpdates(data, backfillTs, counters) {
  const updates = {};
  const trace = {};

  const p = planPseudoUpdate(data.pseudo);
  if (p?.op === 'delete') {
    updates.pseudo = admin.firestore.FieldValue.delete();
    trace.pseudo = 'delete';
    counters.pseudoFieldsDeleted++;
  } else if (p?.op === 'set') {
    updates.pseudo = p.value;
    trace.pseudo = `set:${p.value}`;
    counters.pseudoLowercased++;
  }

  if (backfillTs) {
    const u = planUpdatedAtUpdate(data);
    if (u?.op === 'copyLastSeen') {
      updates.updatedAt = u.value;
      trace.updatedAt = 'from_last_seen';
      counters.updatedAtBackfilled++;
    } else if (u?.op === 'server') {
      updates.updatedAt = admin.firestore.FieldValue.serverTimestamp();
      trace.updatedAt = 'server_timestamp';
      counters.updatedAtBackfilled++;
    }
  }

  return { updates, trace };
}

async function processSingleUid(db, uid, dry, backfillTs, verbose, startedAt) {
  const counters = {
    pseudoFieldsDeleted: 0,
    pseudoLowercased: 0,
    updatedAtBackfilled: 0,
  };
  const ref = db.collection('players').doc(uid);
  const snap = await ref.get();
  if (!snap.exists) {
    const summary = {
      mode: 'single-uid',
      uid,
      error: 'document_not_found',
      startedAt,
      finishedAt: new Date().toISOString(),
    };
    // eslint-disable-next-line no-console
    console.log(JSON.stringify(summary, null, 2));
    return;
  }
  const d = snap.data();
  const { updates, trace } = buildUpdates(d, backfillTs, counters);
  const docsWouldTouch = Object.keys(updates).length > 0 ? 1 : 0;

  if (verbose && docsWouldTouch) {
    // eslint-disable-next-line no-console
    console.error(
      JSON.stringify({
        type: 'velour.admin.normalizePlayer.verbose',
        docId: snap.id,
        trace,
      }),
    );
  }

  let batchesCommitted = 0;
  if (!dry && docsWouldTouch) {
    await ref.update(updates);
    batchesCommitted = 1;
  }

  const summary = {
    mode: 'single-uid',
    uid: snap.id,
    dryRun: dry,
    backfillUpdatedAt: backfillTs,
    verbose,
    startedAt,
    finishedAt: new Date().toISOString(),
    projectId: resolveProjectIdForSummary(),
    scannedDocs: 1,
    documentsWithPlannedWrites: docsWouldTouch,
    batchCommits: dry ? 0 : batchesCommitted,
    pseudoFieldsDeleted: counters.pseudoFieldsDeleted,
    pseudoLowercased: counters.pseudoLowercased,
    updatedAtBackfilled: counters.updatedAtBackfilled,
  };
  // eslint-disable-next-line no-console
  console.log(JSON.stringify(summary, null, 2));
}

async function processScanAll(db, dry, backfillTs, verbose, maxDocs, startedAt) {
  const counters = {
    pseudoFieldsDeleted: 0,
    pseudoLowercased: 0,
    updatedAtBackfilled: 0,
  };

  let lastId = null;
  let scanned = 0;
  let docsWouldTouch = 0;
  let batchesCommitted = 0;

  // eslint-disable-next-line no-constant-condition
  while (true) {
    if (maxDocs != null && scanned >= maxDocs) {
      break;
    }
    const pageSize = maxDocs == null ? 250 : Math.min(250, maxDocs - scanned);
    if (pageSize <= 0) break;

    let q = db
      .collection('players')
      .orderBy(admin.firestore.FieldPath.documentId())
      .limit(pageSize);
    if (lastId) {
      q = q.startAfter(lastId);
    }
    const snap = await q.get();
    if (snap.empty) break;

    let batch = db.batch();
    let ops = 0;
    let stopPaging = false;

    for (const doc of snap.docs) {
      if (maxDocs != null && scanned >= maxDocs) {
        stopPaging = true;
        break;
      }
      scanned++;
      const d = doc.data();
      const { updates, trace } = buildUpdates(d, backfillTs, counters);

      if (Object.keys(updates).length === 0) continue;

      docsWouldTouch++;
      if (verbose) {
        // eslint-disable-next-line no-console
        console.error(
          JSON.stringify({
            type: 'velour.admin.normalizePlayer.verbose',
            docId: doc.id,
            trace,
          }),
        );
      }

      if (dry) {
        continue;
      }

      batch.update(doc.ref, updates);
      ops++;
      if (ops >= 400) {
        await batch.commit();
        batchesCommitted++;
        batch = db.batch();
        ops = 0;
      }
    }

    if (!dry && ops > 0) {
      await batch.commit();
      batchesCommitted++;
    }

    if (stopPaging) {
      break;
    }

    lastId = snap.docs[snap.docs.length - 1];
    if (snap.size < pageSize) break;
  }

  const summary = {
    mode: 'scan-all',
    dryRun: dry,
    backfillUpdatedAt: backfillTs,
    verbose,
    maxDocsScanned: maxDocs,
    startedAt,
    finishedAt: new Date().toISOString(),
    projectId: resolveProjectIdForSummary(),
    scannedDocs: scanned,
    documentsWithPlannedWrites: docsWouldTouch,
    batchCommits: dry ? 0 : batchesCommitted,
    pseudoFieldsDeleted: counters.pseudoFieldsDeleted,
    pseudoLowercased: counters.pseudoLowercased,
    updatedAtBackfilled: counters.updatedAtBackfilled,
  };
  // eslint-disable-next-line no-console
  console.log(JSON.stringify(summary, null, 2));
}

function printHelp() {
  // eslint-disable-next-line no-console
  console.log(`Velour — normalisation profils joueurs (Admin SDK)

Options :
  --dry-run              Aucune écriture Firestore
  --verbose              Une ligne JSON par doc touchée (stderr)
  --backfill-updated-at  Remplir updatedAt si absent
  --max-docs=N           Scanner au plus N documents (parcours documentId)
  --uid=UID              Un seul joueur (incompatible avec --max-docs)
  --help                 Ce message

Authentification Admin SDK :
  export GOOGLE_APPLICATION_CREDENTIALS="$HOME/.../clé-service-account.json"
  (chemin réel vers le fichier JSON ; sans ce fichier valide, le script échoue.)

Exemples :
  node scripts/normalizePlayerPseudos.js --help
  node scripts/normalizePlayerPseudos.js --uid=abc123 --dry-run --verbose
  node scripts/normalizePlayerPseudos.js --max-docs=200 --dry-run --verbose
`);
}

async function main() {
  if (process.argv.includes('--help') || process.argv.includes('-h')) {
    printHelp();
    return;
  }

  const dry = process.argv.includes('--dry-run');
  const backfillTs = process.argv.includes('--backfill-updated-at');
  const verbose = process.argv.includes('--verbose');
  const maxDocs = parsePositiveInt('--max-docs');
  const uidRaw = parseArg('--uid');
  const uid = uidRaw != null && uidRaw !== '' ? uidRaw.trim() : null;

  if (uid && maxDocs != null) {
    throw new Error('Utiliser soit --uid=… soit --max-docs=…, pas les deux.');
  }

  assertServiceAccountFileIfSet();

  if (!admin.apps.length) {
    admin.initializeApp();
  }
  const db = admin.firestore();
  const startedAt = new Date().toISOString();

  if (uid) {
    await processSingleUid(db, uid, dry, backfillTs, verbose, startedAt);
  } else {
    await processScanAll(db, dry, backfillTs, verbose, maxDocs, startedAt);
  }
}

main().catch((e) => {
  // eslint-disable-next-line no-console
  console.error(e);
  process.exit(1);
});
