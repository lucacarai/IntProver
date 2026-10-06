// SPDX-License-Identifier: GPL-3.0-or-later
// Decode and independently verify fCube models before displaying them.
export const MAX_WORLDS = 200;

export class CountermodelError extends Error {}

export function propositionLetters(ast) {
  const letters = new Set();
  const visit = node => {
    if (node.type === 'atom') letters.add(node.name);
    else if (node.type === 'neg') visit(node.argument);
    else if (node.left) { visit(node.left); visit(node.right); }
  };
  visit(ast);
  return [...letters];
}

// Worlds are in preorder; descendants have larger indices. This allows the
// implication and negation clauses to be evaluated bottom-up in O(|A| * |W|).
export function forcingAtWorlds(ast, model) {
  const values = new Map();
  function evaluate(formula) {
    if (values.has(formula)) return values.get(formula);
    const a = formula.argument ? evaluate(formula.argument) : formula.left ? evaluate(formula.left) : null;
    const b = formula.right ? evaluate(formula.right) : null;
    const result = Array(model.worlds.length);
    for (let i = result.length - 1; i >= 0; i--) {
      const world = model.worlds[i];
      switch (formula.type) {
        case 'atom': result[i] = world.atoms.includes(formula.name); break;
        case 'true': result[i] = true; break;
        case 'false': result[i] = false; break;
        case 'and': result[i] = a[i] && b[i]; break;
        case 'or': result[i] = a[i] || b[i]; break;
        case 'neg': result[i] = !a[i] && world.children.every(child => result[child]); break;
        case 'imp': result[i] = (!a[i] || b[i]) && world.children.every(child => result[child]); break;
        case 'iff': result[i] = a[i] === b[i] && world.children.every(child => result[child]); break;
        default: throw new CountermodelError('Unknown formula connective.');
      }
    }
    values.set(formula, result);
    return result;
  }
  return evaluate(ast);
}

export function verifyCountermodel(ast, model) {
  if (!model || model.root !== 0 || !Array.isArray(model.worlds) || !model.worlds.length || model.worlds.length > MAX_WORLDS) {
    throw new CountermodelError('Unsupported countermodel size.');
  }
  const parents = Array(model.worlds.length).fill(0);
  for (const [i, world] of model.worlds.entries()) {
    if (!Array.isArray(world.atoms) || !world.atoms.every(atom => typeof atom === 'string') || !Array.isArray(world.children)) {
      throw new CountermodelError('Malformed world.');
    }
    for (const child of world.children) {
      if (!Number.isInteger(child) || child <= i || child >= parents.length || ++parents[child] !== 1) {
        throw new CountermodelError('Malformed countermodel order.');
      }
      if (!world.atoms.every(atom => model.worlds[child].atoms?.includes(atom))) {
        throw new CountermodelError('Atomic forcing does not persist.');
      }
    }
  }
  if (parents.slice(1).some(count => count !== 1)) throw new CountermodelError('Disconnected countermodel.');
  if (forcingAtWorlds(ast, model)[0]) throw new CountermodelError('The formula holds at the root.');
  return model;
}

export function decodeCountermodel(raw, ast) {
  const worlds = [];
  function visit(list, inherited = new Set(), forbidden = new Set()) {
    if (!Array.isArray(list) || worlds.length >= MAX_WORLDS) throw new CountermodelError('Unsupported countermodel.');
    const forced = new Set(inherited), denied = new Set(forbidden), absent = new Set();
    const branches = [];
    for (const entry of list) {
      if (Array.isArray(entry)) { branches.push(entry); continue; }
      const args = entry?.swff?.[0];
      if (!Array.isArray(args) || args.length !== 2 || !['t', 'f', 'fc'].includes(args[0]) || typeof args[1] !== 'string') {
        throw new CountermodelError('Unsupported countermodel annotation.');
      }
      const [sign, atom] = args;
      if (sign === 't') forced.add(atom);
      else if (sign === 'fc') denied.add(atom);
      else absent.add(atom);
    }
    if ([...forced].some(atom => denied.has(atom) || absent.has(atom))) throw new CountermodelError('Inconsistent countermodel annotation.');
    const index = worlds.length;
    const world = { atoms: [...forced], children: [] };
    worlds.push(world);
    world.children = branches.map(branch => visit(branch, forced, denied));
    return index;
  }
  visit(raw);
  verifyCountermodel(ast, { root: 0, worlds });

  const atoms = propositionLetters(ast);
  // Project away auxiliary atoms. Remove identical sibling subtrees and unary
  // stuttering worlds; never identify worlds on their atomic valuation alone.
  function simplify(i) {
    const children = new Map();
    for (const child of worlds[i].children) {
      const simplified = simplify(child);
      children.set(simplified.signature, simplified);
    }
    const valuation = atoms.filter(atom => worlds[i].atoms.includes(atom));
    const descendants = [...children.values()];
    if (descendants.length === 1 && JSON.stringify(valuation) === JSON.stringify(descendants[0].atoms)) return descendants[0];
    return { atoms: valuation, children: descendants, signature: JSON.stringify([valuation, [...children.keys()].sort()]) };
  }
  const simplifiedWorlds = [];
  function flatten(node) {
    const i = simplifiedWorlds.length;
    const world = { atoms: node.atoms, children: [] };
    simplifiedWorlds.push(world);
    world.children = node.children.map(flatten);
    return i;
  }
  flatten(simplify(0));
  return verifyCountermodel(ast, { root: 0, atoms, worlds: simplifiedWorlds });
}
