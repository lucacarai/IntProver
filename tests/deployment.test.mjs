import test from 'node:test';
import assert from 'node:assert/strict';
import { readFile, readdir } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';
import { inflateRawSync } from 'node:zlib';
import { createHash } from 'node:crypto';

const root = fileURLToPath(new URL('../', import.meta.url));
const build = spawnSync(process.execPath, ['scripts/build.mjs'], { cwd: root, encoding: 'utf8' });
assert.equal(build.status, 0, build.stderr);

function unzip(data) {
  const entries = new Map();
  let offset = 0;
  while (data.readUInt32LE(offset) === 0x04034b50) {
    const method = data.readUInt16LE(offset + 8);
    const compressedSize = data.readUInt32LE(offset + 18);
    const originalSize = data.readUInt32LE(offset + 22);
    const nameLength = data.readUInt16LE(offset + 26);
    const extraLength = data.readUInt16LE(offset + 28);
    const filename = data.subarray(offset + 30, offset + 30 + nameLength).toString('utf8');
    const start = offset + 30 + nameLength + extraLength;
    assert.equal(method, 8);
    const content = inflateRawSync(data.subarray(start, start + compressedSize));
    assert.equal(content.length, originalSize);
    assert.equal(entries.has(filename), false, 'No duplicate source paths');
    entries.set(filename, content);
    offset = start + compressedSize;
  }
  assert.equal(data.readUInt32LE(offset), 0x02014b50);
  return entries;
}

test('static output contains prover, runtime, GPL text and source/license links', async () => {
  const dist = new URL('../dist/', import.meta.url);
  for (const path of ['index.html', 'src/app.js', 'src/prover-worker.js', 'src/engine.pl', 'fcube.pl', 'vendor/package/dist/swipl/swipl-web.js', 'vendor/package/dist/swipl/swipl-web.wasm', 'vendor/package/dist/swipl/swipl-web.data', 'LICENSE', 'license.html', 'licenses/SWI-Prolog.txt', 'licenses/fCube-original-README.txt', 'source.zip', '.nojekyll']) assert.ok((await readFile(new URL(path, dist))).length || path === '.nojekyll', path);
  assert.deepEqual(await readFile(new URL('fcube.pl', dist)), await readFile(new URL('../fCube-11.1 Original version/fCube-11.1/fCube/fCube.pl', import.meta.url)));
  const index = await readFile(new URL('index.html', dist), 'utf8');
  assert.match(index, /href="\.\/source.zip"/);
  assert.match(index, /href="\.\/license.html"/);
  assert.doesNotMatch(index, /(?:href|src)="\/(?!\/)/);
  assert.doesNotMatch(await readFile(new URL('src/prover-worker.js', dist), 'utf8'), /importScripts\('\//);
  assert.deepEqual((await readdir(dist)).sort(), ['.nojekyll', 'LICENSE', 'NOTICE.md', 'SOURCE-MANIFEST.sha256', 'fcube.pl', 'index.html', 'license.html', 'licenses', 'source.zip', 'src', 'vendor'].sort());
});

test('source archive matches published source and excludes unrelated files', async () => {
  const entries = unzip(await readFile(new URL('../dist/source.zip', import.meta.url)));
  for (const path of ['index.html', 'src/app.js', 'src/formula.js', 'scripts/build.mjs', 'scripts/zip.mjs', 'tests/prover.test.mjs', 'README.md', 'docs/DEPLOYMENT.md', 'LICENSE', 'vendor/package/LICENSE.txt', '.github/workflows/deploy.yml']) {
    assert.deepEqual(entries.get(path), await readFile(new URL(`../${path}`, import.meta.url)), path);
  }
  assert.equal([...entries.keys()].some(path => /^dist\/|^\.git\/|preview.*\.jpg|\.env|\.tgz$/.test(path)), false);
  const manifest = entries.get('SOURCE-MANIFEST.sha256').toString();
  for (const line of manifest.trim().split('\n')) {
    const [, checksum, path] = line.match(/^([a-f0-9]{64})  (.+)$/);
    assert.equal(createHash('sha256').update(entries.get(path)).digest('hex'), checksum, path);
  }
  assert.equal(manifest.trim().split('\n').length, entries.size - 1);
});
