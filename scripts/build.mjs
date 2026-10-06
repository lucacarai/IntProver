// SPDX-License-Identifier: GPL-3.0-or-later
// Static deployment and source distribution, added 2026-10-05.
import { mkdir, readFile, writeFile, readdir, copyFile, stat } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import { resolve, relative, dirname } from 'node:path';
import { createHash } from 'node:crypto';
import { createZip } from './zip.mjs';

const root = fileURLToPath(new URL('../', import.meta.url));
const dist = resolve(root, 'dist');
const original = 'fCube-11.1 Original version/fCube-11.1';
async function copy(source, destination = source) {
  const target = resolve(dist, destination);
  await mkdir(dirname(target), { recursive: true });
  await copyFile(resolve(root, source), target);
}
async function files(directory) {
  const found = [];
  for (const entry of (await readdir(resolve(root, directory), { withFileTypes: true })).sort((a, b) => a.name.localeCompare(b.name, 'en'))) {
    const path = `${directory}/${entry.name}`;
    if (entry.isDirectory()) found.push(...await files(path));
    else if (entry.isFile()) found.push(path);
    else throw new Error(`Unsupported source entry: ${path}`);
  }
  return found;
}

await mkdir(dist, { recursive: true });
const site = ['index.html', 'license.html', 'LICENSE', 'NOTICE.md'];
for (const path of site) await copy(path);
for (const path of await files('src')) await copy(path);
for (const filename of ['swipl-web.js', 'swipl-web.wasm', 'swipl-web.data']) await copy(`vendor/package/dist/swipl/${filename}`);
await copy(`${original}/fCube/fCube.pl`, 'fcube.pl');
await copy('vendor/fcube4/fcube.pl', 'fcube4.pl');
await copy('vendor/fcube4/README.txt', 'licenses/fCube-4.1-README.txt');
await copy(`${original}/README.txt`, 'licenses/fCube-original-README.txt');
await copy('vendor/package/LICENSE.txt', 'licenses/SWI-Prolog.txt');
await copy('vendor/package/package.json', 'licenses/swipl-wasm-package.json');
try {
  await stat(resolve(dist, '.nojekyll'));
} catch (error) {
  if (error.code !== 'ENOENT') throw error;
  await writeFile(resolve(dist, '.nojekyll'), '');
}

// Explicit source list: never include credentials, Git metadata, screenshots,
// previous build output, or unrelated files from the developer's computer.
const source = [
  ...site, 'README.md', 'package.json', 'package-lock.json', 'server.mjs', '.gitignore',
  `${original}/fCube/fCube.pl`, `${original}/README.txt`, 'vendor/swipl-metadata.json',
  ...await files('src'), ...await files('scripts'), ...await files('tests'),
  ...await files('docs'), ...await files('.github'), ...await files('vendor/package'),
  ...await files('vendor/fcube4'),
].sort();
const entries = await Promise.all(source.map(async path => ({ name: path.replaceAll('\\', '/'), data: await readFile(resolve(root, path)) })));
const manifest = entries.map(({ name, data }) => `${createHash('sha256').update(data).digest('hex')}  ${name}`).join('\n') + '\n';
entries.push({ name: 'SOURCE-MANIFEST.sha256', data: Buffer.from(manifest) });
await writeFile(resolve(dist, 'source.zip'), createZip(entries));
await writeFile(resolve(dist, 'SOURCE-MANIFEST.sha256'), manifest);
console.log(`Built ${relative(root, dist)} with ${entries.length} source files and GPL/source download links.`);
