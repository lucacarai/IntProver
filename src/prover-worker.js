// SPDX-License-Identifier: GPL-3.0-or-later
// Browser worker added 2026-10-05. Original fCube source is unchanged.
const runtimeBase = new URL('../vendor/package/dist/swipl/', self.location.href).href;
importScripts(`${runtimeBase}swipl-web.js`);

let runtime;
let countermodelReady;
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

function loadCountermodelEngine() {
  return countermodelReady ??= (async () => {
    for (const [url, target] of [[new URL('../fcube4.pl', self.location.href), '/fcube4.pl'], [new URL('./countermodel-engine.pl', self.location.href), '/countermodel-engine.pl']]) {
      const response = await fetch(url);
      if (!response.ok) throw new Error('Could not load the countermodel generator.');
      runtime.FS.writeFile(target, await response.text());
    }
    // The module includes fCube 4.1 in its own namespace; do not consult that
    // source globally, where its predicates would replace those of fCube 11.1.
    if (!runtime.prolog.query("consult('/countermodel-engine.pl').").once().success) throw new Error('Could not initialize countermodel generation.');
  })();
}

onmessage = async event => {
  try {
    await ready;
    const { id, input } = event.data;
    // Parse and serialize again here; never execute the user's input as Prolog.
    const { parseFormula, toProlog } = await import('./formula.js');
    const ast = parseFormula(input);
    const formula = toProlog(ast);
    const result = runtime.prolog.query(`fcube_validity(${formula}, Verdict).`).once();
    if (!result.success || !['valid', 'invalid'].includes(result.Verdict)) {
      throw new Error('The check could not be completed. Try a smaller formula.');
    }
    postMessage({ type: 'result', id, valid: result.Verdict === 'valid' });
    if (result.Verdict === 'invalid') {
      try {
        await loadCountermodelEngine();
        const { decodeCountermodel } = await import('./countermodel.js');
        const generated = runtime.prolog.query(`fcube4:fcube_countermodel(${formula}, Model).`).once();
        if (!generated.success) throw new Error('Countermodel generation could not be completed.');
        const model = decodeCountermodel(generated.Model, ast);
        postMessage({ type: 'countermodel', id, model });
      } catch {
        // Failure to obtain a verified model never changes the established
        // validity verdict and never results in displaying an unchecked model.
        postMessage({ type: 'countermodel', id, message: 'The formula is not valid, but a verified countermodel could not be displayed within the available limits.' });
      }
    }
  } catch (error) {
    postMessage({ type: 'error', id: event.data.id, message: error.message });
  }
};
