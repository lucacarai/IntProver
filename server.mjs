// SPDX-License-Identifier: GPL-3.0-or-later
// Local development server added 2026-10-05. See NOTICE.md and LICENSE.
import { createServer } from 'node:http';
import { readFile, stat } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import { resolve, relative, extname } from 'node:path';

const root = fileURLToPath(new URL('.', import.meta.url));
const prover = resolve(root, 'fCube-11.1 Original version/fCube-11.1/fCube/fCube.pl');
const mime = { '.html': 'text/html; charset=utf-8', '.js': 'text/javascript; charset=utf-8', '.css': 'text/css; charset=utf-8', '.wasm': 'application/wasm', '.data': 'application/octet-stream', '.pl': 'text/plain; charset=utf-8', '.md': 'text/plain; charset=utf-8', '.txt': 'text/plain; charset=utf-8', '.zip': 'application/zip' };
const aliases = {
  '/fcube.pl': prover,
  '/fcube4.pl': resolve(root, 'vendor/fcube4/fcube.pl'),
  '/source.zip': resolve(root, 'dist/source.zip'),
  '/licenses/fCube-original-README.txt': resolve(root, 'fCube-11.1 Original version/fCube-11.1/README.txt'),
  '/licenses/fCube-4.1-README.txt': resolve(root, 'vendor/fcube4/README.txt'),
  '/licenses/SWI-Prolog.txt': resolve(root, 'vendor/package/LICENSE.txt'),
};
const port = Number(process.env.PORT || 4173);
createServer(async (req, res) => {
  try {
    if (!['GET', 'HEAD'].includes(req.method)) { res.writeHead(405); res.end(); return; }
    const pathname = decodeURIComponent(new URL(req.url, 'http://localhost').pathname);
    const path = aliases[pathname] || resolve(root, `.${pathname === '/' ? '/index.html' : pathname}`);
    const rel = relative(root, path);
    const permitted = ['index.html', 'license.html', 'NOTICE.md', 'LICENSE'].includes(rel) || /^(src|vendor)[\\/]/.test(rel) || Object.values(aliases).includes(path);
    if (rel.startsWith('..') || !permitted) { res.writeHead(404); res.end('Not found'); return; }
    if (!(await stat(path)).isFile()) { res.writeHead(404); res.end('Not found'); return; }
    res.writeHead(200, { 'Content-Type': rel === 'LICENSE' ? 'text/plain; charset=utf-8' : mime[extname(path)] || 'application/octet-stream', 'X-Content-Type-Options': 'nosniff', 'Cache-Control': 'no-cache' });
    res.end(req.method === 'HEAD' ? undefined : await readFile(path));
  } catch { res.writeHead(404); res.end('Not found'); }
}).listen(port, '127.0.0.1', () => console.log(`fCube is ready at http://127.0.0.1:${port}`));
