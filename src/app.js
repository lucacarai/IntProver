// SPDX-License-Identifier: GPL-3.0-or-later
// Browser interface added 2026-10-05. See NOTICE.md and LICENSE.
import { parseFormula, formulaMathML } from './formula.js';
import { renderCountermodel } from './countermodel-diagram.js';

const input = document.querySelector('#formula-input');
const preview = document.querySelector('#preview');
const error = document.querySelector('#input-error');
const run = document.querySelector('#run');
const cancel = document.querySelector('#cancel');
const result = document.querySelector('#result');
const status = document.querySelector('#engine-status');
const countermodel = document.querySelector('#countermodel');
let ast = null;
let worker;
let engineReady = false;
let checking = false;
let findingModel = false;
let requestId = 0;
let timeout;

function modelNotice(message) {
  countermodel.replaceChildren();
  const text = document.createElement('p');
  text.className = 'countermodel-caption';
  text.textContent = message;
  countermodel.append(text);
  countermodel.hidden = false;
}

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
      if (data.type === 'result') {
        showResult(data.valid ? 'valid' : 'invalid', data.valid ? 'Intuitionistically valid' : 'Not intuitionistically valid');
        if (!data.valid) {
          checking = true;
          findingModel = true;
          status.textContent = 'Finding a countermodel…';
          modelNotice('Finding a countermodel…');
          const id = requestId;
          timeout = setTimeout(() => {
            if (id !== requestId || !findingModel) return;
            stopCheck();
            modelNotice('The formula is not valid, but countermodel generation took too long.');
          }, 10_000);
        }
      } else if (data.type === 'countermodel') {
        findingModel = false;
        status.textContent = '';
        if (data.model) renderCountermodel(countermodel, data.model);
        else modelNotice(data.message);
      }
      else {
        if (findingModel) modelNotice('The formula is not valid, but countermodel generation could not be completed.');
        else showResult('error', data.message || 'The check could not be completed. Please reload and try again.');
        findingModel = false;
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
    if (findingModel) modelNotice('The formula is not valid, but countermodel generation could not be completed.');
    else showResult('error', 'The prover could not start. Please reload and try again.');
    findingModel = false;
    status.textContent = 'Please reload to try again';
    updateControls();
  };
  updateControls();
}
function stopCheck() {
  clearTimeout(timeout);
  checking = false;
  findingModel = false;
  requestId++;
  startWorker();
}
function updateFormula() {
  if (checking) stopCheck();
  result.hidden = true;
  countermodel.hidden = true;
  countermodel.replaceChildren();
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
  findingModel = false;
  countermodel.hidden = true;
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
  const wasFindingModel = findingModel;
  stopCheck();
  if (wasFindingModel) modelNotice('Countermodel generation cancelled.');
  else { result.hidden = true; countermodel.hidden = true; }
});
startWorker();
