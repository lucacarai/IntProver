// SPDX-License-Identifier: GPL-3.0-or-later
// Inspect registered licenses in the pinned runtime, added 2026-10-05.
import SWIPL from '../vendor/package/dist/index.js';
const runtime = await SWIPL({ arguments: ['-q'] });
const result = runtime.prolog.query('license.').once();
if (!result.success) throw new Error('Runtime license audit did not complete');
