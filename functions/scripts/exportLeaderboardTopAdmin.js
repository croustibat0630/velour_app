/**
 * Exporte les N premiers documents `players` avec la même requête que l’app
 * (highScore desc, updatedAt asc). Utile avant une purge manuelle du classement.
 *
 *   cd functions && npm ci
 *   export GOOGLE_APPLICATION_CREDENTIALS="$HOME/.../service-account.json"
 *   node scripts/exportLeaderboardTopAdmin.js --limit=30
 *   node scripts/exportLeaderboardTopAdmin.js --limit=50 --out=scripts/.local/top.json
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

function parseArg(name, def) {
  const prefix = `${name}=`;
  const hit = process.argv.find((a) => a.startsWith(prefix));
  if (!hit) return def;
  const v = hit.slice(prefix.length);
  return v === '' ? def : v;
}

function parseLimit() {
  const raw = parseArg('--limit', '30');
  const n = parseInt(String(raw), 10);
  if (!Number.isFinite(n) || n < 1 || n > 500) {
    throw new Error('--limit doit être un entier entre 1 et 500');
  }
  return n;
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

function tsToIso(v) {
  if (v == null) return null;
  if (typeof v.toDate === 'function') {
    try {
      return v.toDate().toISOString();
    } catch (_) {
      return null;
    }
  }
  return null;
}

function printHelp() {
  // eslint-disable-next-line no-console
  console.log(`Velour — export top players (Admin SDK)

Options :
  --limit=N     Nombre de documents (défaut 30, max 500)
  --out=chemin  Écrire le JSON dans ce fichier (sinon stdout)
  --help

Même requête que l’app : orderBy highScore desc, orderBy updatedAt asc.
Les joueurs sans updatedAt n’apparaissent pas dans ce snapshot.
`);
}

async function main() {
  if (process.argv.includes('--help') || process.argv.includes('-h')) {
    printHelp();
    return;
  }

  assertServiceAccountFileIfSet();

  if (!admin.apps.length) {
    admin.initializeApp();
  }

  const limit = parseLimit();
  const outPathRaw = parseArg('--out', null);
  const db = admin.firestore();
  const startedAt = new Date().toISOString();
  const projectId =
    admin.app().options.projectId || readProjectIdFromCredentials();

  const snap = await db
      .collection('players')
      .orderBy('highScore', 'desc')
      .orderBy('updatedAt', 'asc')
      .limit(limit)
      .get();

  const rows = snap.docs.map((doc) => {
    const d = doc.data();
    const hs =
        d.highScore == null || d.highScore === ''
          ? null
          : Number(d.highScore);
    return {
      uid: doc.id,
      pseudo: d.pseudo != null ? String(d.pseudo) : null,
      highScore: Number.isFinite(hs) ? hs : null,
      updatedAt: tsToIso(d.updatedAt),
    };
  });

  const payload = {
    mode: 'export-leaderboard-top',
    projectId,
    startedAt,
    finishedAt: new Date().toISOString(),
    limit,
    count: rows.length,
    players: rows,
  };

  const json = JSON.stringify(payload, null, 2);

  if (outPathRaw != null && String(outPathRaw).trim() !== '') {
    const outPath = path.isAbsolute(outPathRaw)
      ? outPathRaw
      : path.join(process.cwd(), outPathRaw);
    const dir = path.dirname(outPath);
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }
    fs.writeFileSync(outPath, json, 'utf8');
    // eslint-disable-next-line no-console
    console.error(`Écrit : ${outPath}`);
  } else {
    // eslint-disable-next-line no-console
    console.log(json);
  }
}

main().catch((e) => {
  // eslint-disable-next-line no-console
  console.error(e);
  process.exit(1);
});
