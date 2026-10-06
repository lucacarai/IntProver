// SPDX-License-Identifier: GPL-3.0-or-later
// Browser worker added 2026-10-05. Original fCube source is unchanged.
const runtimeBase = new URL('../vendor/package/dist/swipl/', self.location.href).href;
importScripts(`${runtimeBase}swipl-web.js`);

let runtime;
const ready = (async () => {
  runtime = await SWIPL({
    arguments: ['-q'],
    locateFile: path => new URL(path, runtimeBase).href,
    print: () => {},
    printErr: message => console.warn(message),
  });
  for (const [url, target] of [[new URL('../fcube.pl', self.location.href), '/fcube.pl'], [new URL('./engine.pl', self.location.href), '/engine.pl']]) {
    const response = await fetch(url);
    if (!response.ok) throw new Error('Could not load the prover.');
    runtime.FS.writeFile(target, await response.text());
    const result = runtime.prolog.query(`consult('${target}').`).once();
    if (!result.success) throw new Error('Could not initialize the prover.');
  }
  postMessage({ type: 'ready' });
})();
ready.catch(error => postMessage({ type: 'error', message: error.message }));

onmessage = async event => {
  try {
    await ready;
    const { id, input } = event.data;
    // Parse and serialize again here; never execute the user's input as Prolog.
    const { parseFormula, toProlog } = await import('./formula.js');
    const formula = toProlog(parseFormula(input));
    const result = runtime.prolog.query(`fcube_validity(${formula}, Verdict).`).once();
    if (!result.success || !['valid', 'invalid'].includes(result.Verdict)) {
      throw new Error('The check could not be completed. Try a smaller formula.');
    }
    postMessage({ type: 'result', id, valid: result.Verdict === 'valid' });
  } catch (error) {
    postMessage({ type: 'error', id: event.data.id, message: error.message });
  }
};
