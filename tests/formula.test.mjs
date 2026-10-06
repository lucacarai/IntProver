import test from 'node:test';
import assert from 'node:assert/strict';
import { parseFormula, formatFormula, formulaMathML, toProlog } from '../src/formula.js';

test('precedence is explicit in the preview', () => {
  const cases = {
    'p and q imp r': '(p ∧ q) → r',
    'p imp q or r': 'p → (q ∨ r)',
    'p and q and r': 'p ∧ q ∧ r',
    'p or q or r': 'p ∨ q ∨ r',
    'p imp (q imp r)': 'p → (q → r)',
    '(p imp q) imp r': '(p → q) → r',
    '(p and q) or r': '(p ∧ q) ∨ r',
    'p and (q or r)': 'p ∧ (q ∨ r)',
  };
  for (const [input, output] of Object.entries(cases)) assert.equal(formatFormula(parseFormula(input)), output);
});

test('ambiguous groups and malformed input are rejected', () => {
  for (const input of ['p imp q imp r', 'p and q or r', 'p or q and r', 'p and q imp r or s', 'p imp (q imp r imp s)', '', '()', '(p', 'p)', 'p and', 'and p', 'p q', 'pp', 'p_1', '1', 'p + q', 'p → q', "p');halt.", 'True']) {
    assert.throws(() => parseFormula(input), { name: 'FormulaError' }, input);
  }
});

test('parentheses permit nested operations and constants', () => {
  for (const input of ['p imp (q imp (r imp s))', '((p imp q) imp r) imp s', '(p and q) imp (r or s)', 'true', 'false', 'P12 imp P12', '(p)', '(p or q) and (r or s)']) assert.ok(parseFormula(input));
});

test('MathML renders subscripts and inserts grouping parentheses', () => {
  const markup = formulaMathML(parseFormula('p1 and q12 imp r'));
  assert.match(markup, /<msub><mi>p<\/mi><mn>1<\/mn><\/msub>/);
  assert.match(markup, /<mo>\(<\/mo>/);
  assert.match(markup, /aria-label="\(p1 ∧ q12\) → r"/);
});

test('Prolog terms quote uppercase atoms and encode constants', () => {
  assert.equal(toProlog(parseFormula('P1 imp q')), "im('P1','q')");
  assert.equal(toProlog(parseFormula('true')), "im('$fcube_truth','$fcube_truth')");
  assert.equal(toProlog(parseFormula('false')), "non(im('$fcube_truth','$fcube_truth'))");
});

test('input and nesting limits fail as input errors', () => {
  assert.throws(() => parseFormula('p'.repeat(8001)), { name: 'FormulaError' });
  assert.throws(() => parseFormula('('.repeat(102) + 'p' + ')'.repeat(102)), { name: 'FormulaError' });
  assert.throws(() => parseFormula('neg '.repeat(102) + 'p'), { name: 'FormulaError' });
});

test('prefix negation binds tightly and does not need enclosing parentheses', () => {
  const cases = {
    'neg p': '¬p', 'neg neg p': '¬¬p', 'neg(p)': '¬p',
    'neg p and q': '¬p ∧ q', 'neg p or q': '¬p ∨ q',
    'neg p imp q': '¬p → q', 'p imp neg q': 'p → ¬q',
    'neg (p and q)': '¬(p ∧ q)', 'neg (p imp q)': '¬(p → q)',
    'neg neg (p or q)': '¬¬(p ∨ q)', 'p or neg p': 'p ∨ ¬p',
    'neg p and neg q and r': '¬p ∧ ¬q ∧ r',
  };
  for (const [input, expected] of Object.entries(cases)) assert.equal(formatFormula(parseFormula(input)), expected, input);
  assert.equal(toProlog(parseFormula('neg neg p')), "non(non('p'))");
  assert.equal(toProlog(parseFormula('neg (p and q)')), "non(and('p','q'))");
  assert.doesNotMatch(formulaMathML(parseFormula('neg neg p')), /<mo>[()]<\/mo>/);
  assert.match(formulaMathML(parseFormula('neg (p and q)')), /<mo>¬<\/mo><mrow><mo>\(<\/mo>/);
});

test('negation needs an operand and preserves ambiguity restrictions', () => {
  for (const input of ['neg', 'neg neg', 'neg ()', 'neg and p', 'p neg q', 'negp', '(neg)', 'neg p and q or r', 'neg p imp q imp r', 'neg (p and q or r)']) assert.throws(() => parseFormula(input), { name: 'FormulaError' }, input);
});

test('biimplication binds below implication and keeps explicit grouping', () => {
  const cases = {
    'p iff q': 'p ↔ q',
    'p and q iff r': '(p ∧ q) ↔ r',
    'p iff q or r': 'p ↔ (q ∨ r)',
    'p imp q iff r': '(p → q) ↔ r',
    'p iff q imp r': 'p ↔ (q → r)',
    'p iff (q iff r)': 'p ↔ (q ↔ r)',
    '(p iff q) iff r': '(p ↔ q) ↔ r',
    'neg (p iff q)': '¬(p ↔ q)',
    '(p iff q) imp (q iff p)': '(p ↔ q) → (q ↔ p)',
  };
  for (const [input, expected] of Object.entries(cases)) assert.equal(formatFormula(parseFormula(input)), expected, input);
  assert.equal(toProlog(parseFormula('p iff q')), "equiv('p','q')");
  assert.equal(toProlog(parseFormula('p iff q imp r')), "equiv('p',im('q','r'))");
  const markup = formulaMathML(parseFormula('p1 iff (q iff r)'));
  assert.match(markup, /<mo>↔<\/mo>/);
  assert.match(markup, /aria-label="p1 ↔ \(q ↔ r\)"/);
  assert.match(markup, /<mo>\(<\/mo>/);
});

test('biimplication requires operands and parentheses for repeated connectives', () => {
  for (const input of ['iff p', 'p iff', 'p iff iff q', 'p iff q iff r', 'p iff (q iff r iff s)', 'p imp q iff r imp s', 'p and q iff r or s', 'p IFF q', 'piffq']) {
    assert.throws(() => parseFormula(input), { name: 'FormulaError' }, input);
  }
});
