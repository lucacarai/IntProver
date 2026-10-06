// SPDX-License-Identifier: GPL-3.0-or-later
// Preview the static build under a project subfolder, added 2026-10-05.
import { createServer } from 'node:http';
import { readFile, stat } from 'node:fs/promises';
import { resolve, relative, extname } from 'node:path';
import { fileURLToPath } from 'node:url';

const dist = fileURLToPath(new URL('../dist/', import.meta.url));
const prefix = `/${(process.env.PREVIEW_PATH || 'prover').replace(/^\/+|\/+$/g, '')}/`;
const port = Number(process.env.PORT || 4174);
const mime = { '.html': 'text/html; charset=utf-8', '.js': 'text/javascript; charset=utf-8', '.css': 'text/css; charset=utf-8', '.wasm': 'application/wasm', '.zip': 'application/zip', '.md': 'text/plain; charset=utf-8', '.txt': 'text/plain; charset=utf-8', '.pl': 'text/plain; charset=utf-8' };
createServer(async (req, res) => {
  try {
    const pathname = decodeURIComponent(new URL(req.url, 'http://localhost').pathname);
    if (pathname === '/' || pathname === prefix.slice(0, -1)) { res.writeHead(302, { Location: prefix }); res.end(); return; }
    if (!pathname.startsWith(prefix)) { res.writeHead(404); res.end('Not found'); return; }
    const path = resolve(dist, pathname.slice(prefix.length) || 'index.html');
    if (relative(dist, path).startsWith('..') || !(await stat(path)).isFile()) { res.writeHead(404); res.end('Not found'); return; }
    res.writeHead(200, { 'Content-Type': relative(dist, path) === 'LICENSE' ? 'text/plain; charset=utf-8' : mime[extname(path)] || 'application/octet-stream', 'X-Content-Type-Options': 'nosniff', 'Cache-Control': 'no-cache' });
    res.end(await readFile(path));
  } catch { res.writeHead(404); res.end('Not found'); }
}).listen(port, '127.0.0.1', () => console.log(`Static build ready at http://127.0.0.1:${port}${prefix}`));
