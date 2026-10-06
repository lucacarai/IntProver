import test from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import SWIPL from '../vendor/package/dist/index.js';
import { parseFormula, toProlog } from '../src/formula.js';
import { decodeCountermodel, verifyCountermodel, forcingAtWorlds, propositionLetters, MAX_WORLDS } from '../src/countermodel.js';
import { countermodelSVG, layoutCountermodel } from '../src/countermodel-diagram.js';

const diagnostics = [];
const runtime = await SWIPL({ arguments: ['-q'], print: () => {}, printErr: text => diagnostics.push(text) });
for (const [source, target, consult] of [
  ['fCube-11.1 Original version/fCube-11.1/fCube/fCube.pl', '/fcube.pl', true],
  ['src/engine.pl', '/engine.pl', true],
  ['vendor/fcube4/fcube.pl', '/fcube4.pl', false],
  ['src/countermodel-engine.pl', '/countermodel-engine.pl', true],
]) {
  runtime.FS.writeFile(target, await readFile(new URL(`../${source}`, import.meta.url), 'utf8'));
  if (consult) assert.equal(runtime.prolog.query(`consult('${target}').`).once().success, true);
}
function generate(ast) {
  const result = runtime.prolog.query(`fcube4:fcube_countermodel(${toProlog(ast)}, Model).`).once();
  return result.success ? decodeCountermodel(result.Model, ast) : null;
}
function validity(ast) {
  return runtime.prolog.query(`fcube_validity(${toProlog(ast)}, Verdict).`).once().Verdict;
}

// Deliberately use the semantic clauses directly, independently of the
// production bottom-up implementation, to check the generated models.
function referenceForces(ast, model, i = 0) {
  const future = index => [index, ...model.worlds[index].children.flatMap(future)];
  switch (ast.type) {
    case 'atom': return model.worlds[i].atoms.includes(ast.name);
    case 'true': return true;
    case 'false': return false;
    case 'neg': return future(i).every(j => !referenceForces(ast.argument, model, j));
    case 'and': return referenceForces(ast.left, model, i) && referenceForces(ast.right, model, i);
    case 'or': return referenceForces(ast.left, model, i) || referenceForces(ast.right, model, i);
    case 'imp': return future(i).every(j => !referenceForces(ast.left, model, j) || referenceForces(ast.right, model, j));
    case 'iff': return future(i).every(j => referenceForces(ast.left, model, j) === referenceForces(ast.right, model, j));
  }
}

test('fCube 4.1 produces independently verified countermodels while 11.1 retains its verdicts', () => {
  for (const input of ['p', 'p imp q', 'p or neg p', 'neg neg p imp p', 'neg p or neg neg p', '((p imp q) imp p) imp p', 'neg (p and q) imp (neg p or neg q)', '(p imp q or r) imp ((p imp q) or (p imp r))', 'p and q and r imp s', 'P12 imp q3', 'false', 'true imp false', 'neg true', 'neg p']) {
    const ast = parseFormula(input);
    assert.equal(validity(ast), 'invalid', input);
    const model = generate(ast);
    assert.ok(model, input);
    assert.equal(referenceForces(ast, model), false, input);
    assert.deepEqual(model.atoms, propositionLetters(ast));
    assert.equal(validity(ast), 'invalid', input);
  }
  for (const input of ['p imp p', 'true', 'neg false', 'p imp neg neg p']) {
    const ast = parseFormula(input);
    assert.equal(validity(ast), 'valid', input);
    assert.equal(generate(ast), null, input);
  }
  assert.equal(diagnostics.some(line => /ERROR|Unknown procedure|Redefined static procedure/.test(line)), false, diagnostics.join('\n'));
});

test('all formulas of up to six nodes over p and q agree with the original prover and reference semantics', () => {
  const sizes = [[], [{ type: 'atom', name: 'p' }, { type: 'atom', name: 'q' }]];
  for (let n = 2; n <= 6; n++) {
    sizes[n] = sizes[n - 1].map(argument => ({ type: 'neg', argument }));
    for (let leftSize = 1; leftSize < n - 1; leftSize++) {
      for (const left of sizes[leftSize]) for (const right of sizes[n - 1 - leftSize]) {
        for (const type of ['and', 'or', 'imp']) sizes[n].push({ type, left, right });
      }
    }
  }
  let invalid = 0;
  for (const ast of sizes.flat()) {
    const model = generate(ast);
    assert.equal(validity(ast), model ? 'invalid' : 'valid', toProlog(ast));
    if (model) {
      invalid++;
      assert.equal(referenceForces(ast, model), false, toProlog(ast));
      const production = forcingAtWorlds(ast, model);
      for (let i = 0; i < model.worlds.length; i++) assert.equal(production[i], referenceForces(ast, model, i));
    }
  }
  assert.equal(sizes.flat().length, 1116);
  assert.equal(invalid, 1026);
});

const signed = (sign, atom) => ({ $t: 't', swff: [[sign, atom]] });
test('reconstruction inherits atoms and rejects inconsistent or non-refuting output', () => {
  const ast = parseFormula('p imp q');
  const model = decodeCountermodel([signed('t', 'p'), [signed('t', 'r')]], ast);
  assert.deepEqual(model.worlds[0].atoms, ['p']);
  // r is projected away; stuttering worlds disappear.
  assert.equal(model.worlds.length, 1);
  const inherited = decodeCountermodel([signed('t', 'p'), [signed('t', 'q')]], parseFormula('p imp r'));
  // q is irrelevant; same projection again reduces to a single world.
  assert.deepEqual(inherited.worlds[0].atoms, ['p']);
  const withRelevantChild = decodeCountermodel([signed('t', 'p'), [signed('t', 'q')]], parseFormula('p and q'));
  assert.deepEqual(withRelevantChild.worlds[1].atoms, ['p', 'q']);
  assert.throws(() => decodeCountermodel([signed('fc', 'p')], parseFormula('neg neg p imp p')));
  assert.throws(() => decodeCountermodel([signed('t', 'p'), signed('f', 'p')], ast));
  assert.throws(() => decodeCountermodel([signed('fc', 'p'), [signed('t', 'p')]], ast));
  assert.throws(() => decodeCountermodel(['valida'], ast));
  assert.throws(() => verifyCountermodel(ast, { root: 0, worlds: [{ atoms: ['p'], children: [0] }] }));
  assert.throws(() => verifyCountermodel(ast, { root: 0, worlds: [{ atoms: ['p'], children: [1] }, { atoms: [], children: [] }] }));
  assert.throws(() => verifyCountermodel(ast, { root: 0, worlds: Array.from({ length: MAX_WORLDS + 1 }, () => ({ atoms: [], children: [] })) }));
});

test('simplification keeps distinct futures with the same valuation and removes redundant roots', () => {
  assert.equal(generate(parseFormula('neg neg p imp p')).worlds.length, 2);
  const branching = generate(parseFormula('neg p or neg neg p'));
  assert.equal(branching.worlds.length, 3);
  assert.equal(branching.worlds.filter(world => world.atoms.length === 0).length, 2);
});

test('biimplication countermodels agree with independent intuitionistic semantics', () => {
  for (const input of ['p iff q', 'p iff neg neg p', 'neg (p iff q)', 'true iff false', 'p iff (q iff r)', 'p iff q imp r']) {
    const ast = parseFormula(input);
    assert.equal(validity(ast), 'invalid', input);
    const model = generate(ast);
    assert.ok(model, input);
    const forces = forcingAtWorlds(ast, model);
    assert.equal(referenceForces(ast, model), false, input);
    for (let i = 0; i < model.worlds.length; i++) assert.equal(forces[i], referenceForces(ast, model, i), input);
  }
  // Agreement at the root alone is insufficient: a successor can distinguish
  // the operands even when neither atom is forced at the root.
  const model = { root: 0, worlds: [{ atoms: [], children: [1] }, { atoms: ['p'], children: [] }] };
  assert.deepEqual(forcingAtWorlds(parseFormula('p iff q'), model), [false, false]);
  assert.deepEqual(forcingAtWorlds(parseFormula('p iff p'), model), [true, true]);
});

test('static diagrams always label worlds, use straight cover edges, and stop coloring above three input letters', () => {
  const colored = countermodelSVG(generate(parseFormula('(p imp q or r) imp ((p imp q) or (p imp r))')));
  assert.match(colored, /countermodel-hue-2/);
  assert.match(colored, /countermodel-label/);
  assert.match(colored, />p, r<|>p, q</);
  assert.doesNotMatch(colored, /<path|marker-end|onclick|tabindex|<title>.*w\d/);
  const mono = countermodelSVG(generate(parseFormula('p and q and r imp s')));
  assert.match(mono, />p, q, r</);
  assert.doesNotMatch(mono, /countermodel-hue|mix-blend-mode|#3975df|#e65353|#f4c63d|#76a9fa|#fffdf8/);
  assert.match(countermodelSVG(generate(parseFormula('P12 imp q3'))), />P₁₂</);
  const single = countermodelSVG(generate(parseFormula('false')));
  assert.match(single, />∅</);
  assert.doesNotMatch(single, /countermodel-hue/);
});

test('tree layout puts the root below all successors and leaves room for labels', () => {
  const model = generate(parseFormula('neg p or neg neg p'));
  const { nodes, width, height } = layoutCountermodel(model);
  for (const node of nodes) {
    assert.ok(node.x > 0 && node.x < width);
    assert.ok(node.y > 0 && node.y + node.labels.length * 20 + 10 < height);
    for (const child of node.children) assert.ok(nodes[child].y < node.y);
  }
  assert.notEqual(nodes[1].x, nodes[2].x);
});
