/**
 * Supprime **tous** les documents de la collection `players`, en pages.
 * Optionnel : supprimer aussi chaque utilisateur Firebase Auth (`--with-auth`).
 *
 * Sans `--execute` : compte seulement les documents (aucune suppression).
 *
 *   cd functions && npm ci
 *   export GOOGLE_APPLICATION_CREDENTIALS="..."
 *   node scripts/purgeAllPlayersAdmin.js --verbose
 *   node scripts/purgeAllPlayersAdmin.js --execute --verbose
 *   node scripts/purgeAllPlayersAdmin.js --execute --with-auth --verbose
 */

const fs = require('fs');
const admin = require('firebase-admin');

const PAGE = 300;

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

function isAuthUserNotFound(err) {
  const c = err?.code || err?.errorInfo?.code;
  return c === 'auth/user-not-found';
}

function printHelp() {
  // eslint-disable-next-line no-console
  console.log(`Velour — purge complète de la collection players (Admin SDK)

Sans [--execute] : compte les documents uniquement (aucune suppression).

Options :
  --execute     Supprimer chaque document players/{uid}
  --with-auth   Après chaque suppression Firestore, supprimer l’utilisateur Auth (irréversible)
  --verbose     Une ligne stderr par uid traité
  --help
`);
}

async function main() {
  if (process.argv.includes('--help') || process.argv.includes('-h')) {
    printHelp();
    return;
  }

  const execute = process.argv.includes('--execute');
  const withAuth = process.argv.includes('--with-auth');
  const verbose = process.argv.includes('--verbose');

  assertServiceAccountFileIfSet();

  if (!admin.apps.length) {
    admin.initializeApp();
  }

  const db = admin.firestore();
  const startedAt = new Date().toISOString();
  const projectId =
    admin.app().options.projectId || readProjectIdFromCredentials();

  const summary = {
    mode: 'purge-all-players',
    dryRun: !execute,
    withAuth: execute && withAuth,
    projectId,
    startedAt,
    playersSeen: 0,
    firestoreDeleted: 0,
    firestoreErrors: 0,
    authDeleted: 0,
    authMissing: 0,
    authErrors: 0,
  };

  let lastDoc = null;

  for (;;) {
    let q = db
        .collection('players')
        .orderBy(admin.firestore.FieldPath.documentId())
        .limit(PAGE);
    if (lastDoc) {
      q = q.startAfter(lastDoc);
    }
    const snap = await q.get();
    if (snap.empty) {
      break;
    }

    for (const doc of snap.docs) {
      summary.playersSeen++;
      const uid = doc.id;

      if (!execute) {
        if (verbose) {
          // eslint-disable-next-line no-console
          console.error(
            JSON.stringify({
              type: 'velour.admin.purgeAllPlayers.verbose',
              action: 'would_delete',
              uid,
            }),
          );
        }
        continue;
      }

      try {
        await doc.ref.delete();
        summary.firestoreDeleted++;
        if (verbose) {
          // eslint-disable-next-line no-console
          console.error(
            JSON.stringify({
              type: 'velour.admin.purgeAllPlayers.verbose',
              action: 'firestore_deleted',
              uid,
            }),
          );
        }
      } catch (e) {
        summary.firestoreErrors++;
        // eslint-disable-next-line no-console
        console.error(
          JSON.stringify({
            type: 'velour.admin.purgeAllPlayers.error',
            phase: 'firestore',
            uid,
            message: String(e.message || e),
          }),
        );
        continue;
      }

      if (withAuth) {
        try {
          await admin.auth().deleteUser(uid);
          summary.authDeleted++;
          if (verbose) {
            // eslint-disable-next-line no-console
            console.error(
              JSON.stringify({
                type: 'velour.admin.purgeAllPlayers.verbose',
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
                  type: 'velour.admin.purgeAllPlayers.verbose',
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
                type: 'velour.admin.purgeAllPlayers.error',
                phase: 'auth',
                uid,
                message: String(e.message || e),
              }),
            );
          }
        }
      }
    }

    lastDoc = snap.docs[snap.docs.length - 1];
    if (snap.size < PAGE) {
      break;
    }
  }

  summary.finishedAt = new Date().toISOString();
  if (!execute) {
    summary.note =
      'Aucune suppression effectuée. Relance avec --execute (et éventuellement --with-auth).';
  }
  // eslint-disable-next-line no-console
  console.log(JSON.stringify(summary, null, 2));
}

main().catch((e) => {
  // eslint-disable-next-line no-console
  console.error(e);
  process.exit(1);
});
