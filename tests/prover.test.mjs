import test from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import SWIPL from '../vendor/package/dist/index.js';
import { parseFormula, toProlog } from '../src/formula.js';

const diagnostics = [];
const runtime = await SWIPL({ arguments: ['-q'], print: () => {}, printErr: message => diagnostics.push(message) });
const originalUrl = new URL('../fCube-11.1 Original version/fCube-11.1/fCube/fCube.pl', import.meta.url);
for (const [url, target] of [[originalUrl, '/fcube.pl'], [new URL('../src/engine.pl', import.meta.url), '/engine.pl']]) {
  runtime.FS.writeFile(target, await readFile(url, 'utf8'));
  assert.equal(runtime.prolog.query(`consult('${target}').`).once().success, true);
}

function decide(input) {
  const result = runtime.prolog.query(`fcube_validity(${toProlog(parseFormula(input))}, Verdict).`).once();
  assert.equal(result.success, true, JSON.stringify(result));
  return result.Verdict;
}

test('original fCube recognizes intuitionistic theorems', () => {
  for (const input of ['p imp p', '(p and (p imp q)) imp q', 'p and q imp p', 'p imp p or q', '(p or q) imp (q or p)', '(p and q) imp (q and p)', '(p imp q) imp ((q imp r) imp (p imp r))', '(p imp (q and r)) imp ((p imp q) and (p imp r))', 'P12 imp P12', 'true', 'false imp p', 'p imp true', 'false imp false', '(p and false) imp q', '(p imp false) imp ((p imp q) imp (p imp false))']) assert.equal(decide(input), 'valid', input);
});

test('original fCube rejects non-theorems and classical-only principles', () => {
  for (const input of ['p', 'false', 'p imp q', 'p and q imp r', 'p or (p imp false)', '((p imp false) imp false) imp p', '((p imp q) imp p) imp p', '(p imp false) or ((p imp false) imp false)', 'true imp false', '(p imp q) imp (q imp p)', '(p imp q or r) imp ((p imp q) or (p imp r))']) assert.equal(decide(input), 'invalid', input);
});

test('constants behave correctly in every connective', () => {
  for (const [input, expected] of Object.entries({
    'true and true': 'valid', 'true and false': 'invalid', 'false and true': 'invalid', 'false and false': 'invalid',
    'true or false': 'valid', 'false or true': 'valid', 'false or false': 'invalid',
    'true imp true': 'valid', 'true imp false': 'invalid', 'false imp true': 'valid', 'false imp false': 'valid',
    '(p or false) imp p': 'valid', 'p imp (p and true)': 'valid', 'p imp (p or false)': 'valid'
  })) assert.equal(decide(input), expected, input);
});

test('the Prolog source loads without syntax errors or undefined predicates', () => {
  assert.equal(diagnostics.some(message => /ERROR|Unknown procedure/.test(message)), false, diagnostics.join('\n'));
});

test('prefix negation uses intuitionistic semantics in the original prover', () => {
  const cases = {
    'neg false': 'valid', 'neg true': 'invalid', 'neg p': 'invalid',
    'p or neg p': 'invalid', 'neg neg p imp p': 'invalid',
    'p imp neg neg p': 'valid', 'neg neg neg p imp neg p': 'valid',
    'neg p imp (p imp q)': 'valid', 'neg (p and neg p)': 'valid',
    'neg (p or q) imp (neg p and neg q)': 'valid',
    '(neg p and neg q) imp neg (p or q)': 'valid',
    'neg (p and q) imp (neg p or neg q)': 'invalid',
    'neg p imp (p imp false)': 'valid', '(p imp false) imp neg p': 'valid',
  };
  for (const [input, expected] of Object.entries(cases)) assert.equal(decide(input), expected, input);
});

test('biimplication uses both intuitionistic implications in the original prover', () => {
  const cases = {
    'p iff p': 'valid', 'p iff q': 'invalid',
    'true iff true': 'valid', 'false iff false': 'valid', 'true iff false': 'invalid',
    'p and q iff (q and p)': 'valid',
    'p iff (p and true)': 'valid',
    '(p iff q) imp (q iff p)': 'valid',
    'p iff neg neg p': 'invalid',
    '(p iff q) iff ((p imp q) and (q imp p))': 'valid',
    'neg (p iff q)': 'invalid',
    'p iff (q iff r)': 'invalid',
  };
  for (const [input, expected] of Object.entries(cases)) assert.equal(decide(input), expected, input);
});
