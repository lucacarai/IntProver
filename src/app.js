// SPDX-License-Identifier: GPL-3.0-or-later
// Browser interface added 2026-10-05. See NOTICE.md and LICENSE.
import { parseFormula, formulaMathML } from './formula.js';

const input = document.querySelector('#formula-input');
const preview = document.querySelector('#preview');
const error = document.querySelector('#input-error');
const run = document.querySelector('#run');
const cancel = document.querySelector('#cancel');
const result = document.querySelector('#result');
const status = document.querySelector('#engine-status');
let ast = null;
let worker;
let engineReady = false;
let checking = false;
let requestId = 0;
let timeout;

function showResult(state, message) {
  result.hidden = false;
  result.dataset.state = state;
  const mark = document.createElement('span');
  mark.className = state === 'checking' ? 'spinner' : 'result-mark';
  mark.setAttribute('aria-hidden', 'true');
  mark.textContent = { valid: '✓', invalid: '○', error: '!' }[state] ?? '';
  const label = document.createElement('span');
  label.textContent = message;
  result.replaceChildren(mark, label);
}
function updateControls() {
  run.disabled = !ast || !engineReady || checking;
  cancel.hidden = !checking;
  run.querySelector('span').textContent = checking ? 'Running' : 'Run';
}
function startWorker() {
  worker?.terminate();
  engineReady = false;
  status.textContent = 'Getting ready…';
  worker = new Worker(new URL('./prover-worker.js', import.meta.url));
  const currentWorker = worker;
  worker.onmessage = ({ data }) => {
    if (worker !== currentWorker) return;
    if (data.type === 'ready') {
      engineReady = true;
      status.textContent = '';
    } else if (data.id === requestId || (data.type === 'error' && data.id === undefined)) {
      clearTimeout(timeout);
      checking = false;
      if (data.type === 'result') showResult(data.valid ? 'valid' : 'invalid', data.valid ? 'Intuitionistically valid' : 'Not intuitionistically valid');
      else {
        showResult('error', data.message || 'The check could not be completed. Please reload and try again.');
        status.textContent = 'Please reload to try again';
        engineReady = false;
      }
    }
    updateControls();
  };
  worker.onerror = () => {
    if (worker !== currentWorker) return;
    clearTimeout(timeout);
    checking = false;
    engineReady = false;
    showResult('error', 'The prover could not start. Please reload and try again.');
    status.textContent = 'Please reload to try again';
    updateControls();
  };
  updateControls();
}
function stopCheck() {
  clearTimeout(timeout);
  checking = false;
  requestId++;
  startWorker();
}
function updateFormula() {
  if (checking) stopCheck();
  result.hidden = true;
  ast = null;
  input.removeAttribute('aria-invalid');
  error.hidden = true;
  if (!input.value.trim()) {
    preview.innerHTML = '<p class="preview-placeholder">Your formula will appear here.</p>';
  } else {
    try {
      ast = parseFormula(input.value);
      preview.innerHTML = formulaMathML(ast);
    } catch (e) {
      input.setAttribute('aria-invalid', 'true');
      error.textContent = `Invalid input: ${e.message}`;
      error.hidden = false;
      preview.innerHTML = '<p class="preview-placeholder">Add or adjust your formula to see its preview.</p>';
    }
  }
  updateControls();
}
input.addEventListener('input', updateFormula);
document.querySelector('#formula-form').addEventListener('submit', event => {
  event.preventDefault();
  if (!ast || !engineReady || checking) return;
  checking = true;
  const id = ++requestId;
  showResult('checking', 'Checking your formula…');
  updateControls();
  worker.postMessage({ id, input: input.value });
  timeout = setTimeout(() => {
    if (id !== requestId || !checking) return;
    stopCheck();
    showResult('error', 'This check took too long. Try a smaller formula.');
  }, 30_000);
});
cancel.addEventListener('click', () => {
  stopCheck();
  result.hidden = true;
});
startWorker();
