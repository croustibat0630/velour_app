/**
 * Suppression Admin des documents `players/{uid}` (classement / profil cloud).
 * Optionnel : suppression du compte Firebase Auth associé.
 *
 * Sans [--execute] : simulation uniquement (aucune suppression).
 *
 *   cd functions && npm ci
 *   export GOOGLE_APPLICATION_CREDENTIALS="$HOME/.../velour-admin.json"
 *
 *   node scripts/deletePlayersAdmin.js --help
 *   node scripts/deletePlayersAdmin.js --uids-file=./uids-a-supprimer.txt --verbose
 *   node scripts/deletePlayersAdmin.js --uids-file=./uids-a-supprimer.txt --execute --verbose
 *   node scripts/deletePlayersAdmin.js --uids=uid1,uid2 --execute --with-auth --verbose
 *
 * Fichier UID : une ligne = un UID ; lignes vides et lignes commençant par # ignorées.
 */

const fs = require('fs');
const path = require('path');
const admin = require('firebase-admin');

function assertServiceAccountFileIfSet() {
  const p = process.env.GOOGLE_APPLICATION_CREDENTIALS;
  if (!p || p.trim() === '') return;
  if (!fs.existsSync(p)) {
    throw new Error(
      `Fichier introuvable : GOOGLE_APPLICATION_CREDENTIALS=${p}\n` +
        'Exporte le chemin absolu vers la clé JSON du compte de service.',
    );
  }
  if (!fs.statSync(p).isFile()) {
    throw new Error(`GOOGLE_APPLICATION_CREDENTIALS doit être un fichier : ${p}`);
  }
}

function readProjectIdFromCredentials() {
  const credPath = process.env.GOOGLE_APPLICATION_CREDENTIALS;
  if (!credPath || !fs.existsSync(credPath)) return null;
  try {
    const j = JSON.parse(fs.readFileSync(credPath, 'utf8'));
    return typeof j.project_id === 'string' ? j.project_id : null;
  } catch (_) {
    return null;
  }
}

function parseArg(name) {
  const prefix = `${name}=`;
  const hit = process.argv.find((a) => a.startsWith(prefix));
  return hit ? hit.slice(prefix.length) : null;
}

function parseUidList() {
  const raw = parseArg('--uids');
  if (raw != null && raw.trim() !== '') {
    return raw
        .split(',')
        .map((s) => s.trim())
        .filter((s) => s.length > 0);
  }
  const filePath = parseArg('--uids-file');
  if (filePath == null || filePath.trim() === '') {
    return null;
  }
  const abs = path.isAbsolute(filePath)
    ? filePath
    : path.join(process.cwd(), filePath);
  if (!fs.existsSync(abs)) {
    throw new Error(`Fichier introuvable : ${abs}`);
  }
  const text = fs.readFileSync(abs, 'utf8');
  const out = [];
  for (const line of text.split(/\r?\n/)) {
    const t = line.trim();
    if (t === '' || t.startsWith('#')) continue;
    out.push(t);
  }
  return out;
}

function printHelp() {
  // eslint-disable-next-line no-console
  console.log(`Velour — suppression profils players (Admin SDK)

Sans [--execute] : simulation uniquement (aucune suppression).

Options :
  --uids=uid1,uid2,...   Liste d’UID Firebase (séparés par des virgules)
  --uids-file=chemin     Fichier texte : un UID par ligne (# = commentaire)
  --execute              Effectuer les suppressions Firestore (obligatoire pour appliquer)
  --with-auth            Après chaque doc, supprimer aussi l’utilisateur Auth (irréversible)
  --verbose              Journal détaillé sur stderr
  --help

Exemple avant prod (liste dans uids.txt) :
  node scripts/deletePlayersAdmin.js --uids-file=./uids-test.txt --verbose
  node scripts/deletePlayersAdmin.js --uids-file=./uids-test.txt --execute --verbose
`);
}

function isAuthUserNotFound(err) {
  const c = err?.code || err?.errorInfo?.code;
  return c === 'auth/user-not-found';
}

async function main() {
  if (process.argv.includes('--help') || process.argv.includes('-h')) {
    printHelp();
    return;
  }

  const execute = process.argv.includes('--execute');
  const withAuth = process.argv.includes('--with-auth');
  const verbose = process.argv.includes('--verbose');

  const uids = parseUidList();
  if (uids == null || uids.length === 0) {
    throw new Error(
      'Fournis --uids=... ou --uids-file=... (voir --help). Liste d’UID vide.',
    );
  }

  assertServiceAccountFileIfSet();

  if (!admin.apps.length) {
    admin.initializeApp();
  }
  const db = admin.firestore();
  const startedAt = new Date().toISOString();
  const projectId =
    admin.app().options.projectId || readProjectIdFromCredentials();

  if (!execute) {
    if (verbose) {
      for (const uid of uids) {
        // eslint-disable-next-line no-console
        console.error(
          JSON.stringify({
            type: 'velour.admin.deletePlayers.verbose',
            action: 'would_delete',
            uid,
            firestore: true,
            auth: withAuth,
          }),
        );
      }
    }
    // eslint-disable-next-line no-console
    console.log(
      JSON.stringify(
        {
          mode: 'delete-players',
          dryRun: true,
          withAuthPlanned: withAuth,
          projectId,
          startedAt,
          finishedAt: new Date().toISOString(),
          uidCount: uids.length,
          note:
            'Aucune suppression effectuée. Relance avec --execute pour appliquer.',
        },
        null,
        2,
      ),
    );
    return;
  }

  const summary = {
    mode: 'delete-players',
    dryRun: false,
    withAuth,
    verbose,
    projectId,
    startedAt,
    uidsRequested: uids.length,
    firestoreDeleted: 0,
    firestoreMissing: 0,
    firestoreErrors: 0,
    authDeleted: 0,
    authMissing: 0,
    authErrors: 0,
  };

  for (const uid of uids) {
    if (!uid || typeof uid !== 'string') continue;

    try {
      const ref = db.collection('players').doc(uid);
      const snap = await ref.get();
      if (!snap.exists) {
        summary.firestoreMissing++;
        if (verbose) {
          // eslint-disable-next-line no-console
          console.error(
            JSON.stringify({
              type: 'velour.admin.deletePlayers.verbose',
              action: 'firestore_missing',
              uid,
            }),
          );
        }
      } else {
        await ref.delete();
        summary.firestoreDeleted++;
        if (verbose) {
          // eslint-disable-next-line no-console
          console.error(
            JSON.stringify({
              type: 'velour.admin.deletePlayers.verbose',
              action: 'firestore_deleted',
              uid,
            }),
          );
        }
      }
    } catch (e) {
      summary.firestoreErrors++;
      // eslint-disable-next-line no-console
      console.error(
        JSON.stringify({
          type: 'velour.admin.deletePlayers.error',
          phase: 'firestore',
          uid,
          message: String(e.message || e),
        }),
      );
    }

    if (withAuth) {
      try {
        await admin.auth().deleteUser(uid);
        summary.authDeleted++;
        if (verbose) {
          // eslint-disable-next-line no-console
          console.error(
            JSON.stringify({
              type: 'velour.admin.deletePlayers.verbose',
              action: 'auth_deleted',
              uid,
            }),
          );
        }
      } catch (e) {
        if (isAuthUserNotFound(e)) {
          summary.authMissing++;
          if (verbose) {
            // eslint-disable-next-line no-console
            console.error(
              JSON.stringify({
                type: 'velour.admin.deletePlayers.verbose',
                action: 'auth_missing',
                uid,
              }),
            );
          }
        } else {
          summary.authErrors++;
          // eslint-disable-next-line no-console
          console.error(
            JSON.stringify({
              type: 'velour.admin.deletePlayers.error',
              phase: 'auth',
              uid,
              message: String(e.message || e),
            }),
          );
        }
      }
    }
  }

  summary.finishedAt = new Date().toISOString();
  // eslint-disable-next-line no-console
  console.log(JSON.stringify(summary, null, 2));
}

main().catch((e) => {
  // eslint-disable-next-line no-console
  console.error(e);
  process.exit(1);
});
