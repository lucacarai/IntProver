// SPDX-License-Identifier: GPL-3.0-or-later
// Static SVG Hasse diagrams. Palette follows Correct Partition's convention;
// see NOTICE.md. No graph library, remote assets, or interaction is needed.
export const HUE_COLORS = ['#3975df', '#e65353', '#f4c63d'];
const REGION_COLORS = ['#76a9fa', '#f98c8c', '#f8dc64'];
const MIXED_COLORS = ['#fffdf8', '#3975df', '#e65353', '#7b4ca8', '#f4c63d', '#55a65b', '#e98d38', '#765236'];
const xml = text => String(text).replace(/[&<>"']/g, char => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&apos;' })[char]);
export const atomLabel = atom => atom.replace(/\d/g, digit => '₀₁₂₃₄₅₆₇₈₉'[Number(digit)]);

function labelLines(atoms) {
  if (!atoms.length) return ['∅'];
  const lines = [''];
  for (const atom of atoms.map(atomLabel)) {
    const last = lines.length - 1;
    if (lines[last] && lines[last].length + atom.length > 25) lines.push(atom);
    else lines[last] += (lines[last] ? ', ' : '') + atom;
  }
  return lines;
}

export function layoutCountermodel(model) {
  const nodes = model.worlds.map(world => ({ ...world, labels: labelLines(world.atoms) }));
  let maxDepth = 0;
  let maxLines = 1;
  function measure(i, depth = 0) {
    const node = nodes[i];
    node.depth = depth;
    maxDepth = Math.max(maxDepth, depth);
    maxLines = Math.max(maxLines, node.labels.length);
    const ownWidth = Math.max(90, ...node.labels.map(line => line.length * 9 + 32));
    const childrenWidth = node.children.reduce((sum, child) => sum + measure(child, depth + 1), 0) + Math.max(0, node.children.length - 1) * 28;
    node.width = Math.max(ownWidth, childrenWidth);
    return node.width;
  }
  const width = Math.max(300, measure(0) + 70);
  const levelGap = Math.max(100, maxLines * 20 + 65);
  const height = Math.max(150, maxDepth * levelGap + maxLines * 20 + 105);
  function position(i, left) {
    const node = nodes[i];
    const childrenWidth = node.children.reduce((sum, child) => sum + nodes[child].width, 0) + Math.max(0, node.children.length - 1) * 28;
    let cursor = left + (node.width - childrenWidth) / 2;
    for (const child of node.children) { position(child, cursor); cursor += nodes[child].width + 28; }
    node.x = node.children.length ? (nodes[node.children[0]].x + nodes[node.children.at(-1)].x) / 2 : left + node.width / 2;
    node.y = 48 + (maxDepth - node.depth) * levelGap;
  }
  position(0, (width - nodes[0].width) / 2);
  return { nodes, width, height };
}

export function countermodelSVG(model) {
  const { nodes, width, height } = layoutCountermodel(model);
  const colored = model.atoms.length > 0 && model.atoms.length <= 3;
  const edges = nodes.flatMap((node, i) => node.children.map(child => [i, child]));
  const line = (a, b, extra = '') => `<line x1="${nodes[a].x}" y1="${nodes[a].y}" x2="${nodes[b].x}" y2="${nodes[b].y}" ${extra}/>`;
  let regions = '';
  if (colored) {
    const masks = model.atoms.map((atom, hue) => {
      const included = nodes.map((node, i) => node.atoms.includes(atom) ? i : -1).filter(i => i >= 0);
      return `<mask id="countermodel-hue-${hue}" maskUnits="userSpaceOnUse" x="0" y="0" width="${width}" height="${height}"><rect width="${width}" height="${height}" fill="black"/><g fill="white" stroke="white" stroke-width="56" stroke-linecap="round">${edges.filter(([a, b]) => nodes[a].atoms.includes(atom) && nodes[b].atoms.includes(atom)).map(([a, b]) => line(a, b)).join('')}${included.map(i => `<circle cx="${nodes[i].x}" cy="${nodes[i].y}" r="28" stroke="none"/>`).join('')}</g><g fill="black">${nodes.filter(node => !node.atoms.includes(atom)).map(node => `<circle cx="${node.x}" cy="${node.y}" r="20"/>`).join('')}</g></mask>`;
    }).join('');
    regions = `<defs>${masks}</defs><g class="countermodel-regions">${model.atoms.map((_, hue) => `<rect width="${width}" height="${height}" fill="${REGION_COLORS[hue]}" mask="url(#countermodel-hue-${hue})" style="mix-blend-mode:multiply"/>`).join('')}</g>`;
  }
  const points = nodes.map(node => {
    const mask = model.atoms.reduce((bits, atom, hue) => bits | (node.atoms.includes(atom) ? 1 << hue : 0), 0);
    const fill = colored ? MIXED_COLORS[mask] : '#ffffff';
    return `<g><circle cx="${node.x}" cy="${node.y}" r="6.5" fill="${fill}" stroke="#35323a" stroke-width="1.3"/><text x="${node.x}" y="${node.y + 28}" class="countermodel-label" text-anchor="middle">${node.labels.map((label, j) => `<tspan x="${node.x}" dy="${j ? 20 : 0}">${xml(label)}</tspan>`).join('')}</text></g>`;
  }).join('');
  return `<svg xmlns="http://www.w3.org/2000/svg" class="countermodel-svg" viewBox="0 0 ${width} ${height}" width="${width}" height="${height}" role="img" aria-label="Kripke countermodel with ${nodes.length} ${nodes.length === 1 ? 'world' : 'worlds'}. The formula does not hold at the bottom root. Every world is labelled with all proposition letters that hold there."><rect width="${width}" height="${height}" fill="${colored ? '#fffdf8' : '#ffffff'}"/>${regions}<g stroke="#69656d" stroke-width="1.5">${edges.map(([a, b]) => line(a, b)).join('')}</g>${points}</svg>`;
}

export function renderCountermodel(container, model) {
  container.replaceChildren();
  const heading = document.createElement('h2');
  heading.textContent = 'A countermodel';
  const caption = document.createElement('p');
  caption.className = 'countermodel-caption';
  caption.textContent = 'The formula does not hold at the bottom root. Labels show all proposition letters that hold; ∅ means none.';
  const diagram = document.createElement('div');
  diagram.className = 'countermodel-scroll';
  diagram.innerHTML = countermodelSVG(model);
  container.append(heading, caption, diagram);
  if (model.atoms.length > 0 && model.atoms.length <= 3) {
    const legend = document.createElement('div');
    legend.className = 'countermodel-legend';
    for (const [i, atom] of model.atoms.entries()) {
      const item = document.createElement('span');
      const swatch = document.createElement('span');
      swatch.className = 'countermodel-swatch';
      swatch.style.backgroundColor = HUE_COLORS[i];
      item.append(swatch, document.createTextNode(atomLabel(atom)));
      legend.append(item);
    }
    const hint = document.createElement('span');
    hint.className = 'countermodel-color-hint';
    hint.textContent = 'Overlapping colors indicate letters holding together.';
    legend.append(hint);
    container.append(legend);
  }
  container.hidden = false;
}
