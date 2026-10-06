# IntProver

A local browser interface for the original fCube 11.1 intuitionistic propositional decision procedure.

## Run

With Node.js available, run `node server.mjs`, then open http://127.0.0.1:4173. No npm installation or system Prolog installation is needed: the pinned browser runtime is included in `vendor/`. Set `PORT` to choose another local port.

## Build and publish

Run `npm ci`, `npm test`, and `npm run build` with Node.js 24. The build creates a self-contained static website in `dist/`, with the original prover at `fcube.pl`, local runtime assets, full license notices, and a corresponding `source.zip`. No application server is needed in production. With no npm installed, run `node scripts/build.mjs` directly.

`npm run preview` (or `node scripts/preview.mjs`) serves the built site at http://127.0.0.1:4174/prover/ to test deployment beneath a project subfolder. All app paths are relative and work at the domain root as well.

The included GitHub Actions workflow tests, builds, and deploys `dist/` when `main` is pushed, or when run manually. The selected destination is `lucacarai/IntProver`, with intended URL https://lucacarai.github.io/IntProver/. Once the repository exists, set Settings → Pages → publishing source to GitHub Actions. See [deployment instructions](docs/DEPLOYMENT.md).

## Input

- One proposition letter, optionally followed by digits: `p`, `Q`, `p1`, `q12`.
- Constants: `true` and `false`.
- Infix operators: `and`, `or`, `imp` (lowercase).
- Prefix negation: `neg p`, `neg neg p`, `neg (p and q)`. It binds more tightly than the binary operators; atomic inputs and repeated negation need no parentheses.
- Parentheses group formulas. Each parenthesized level allows at most one `imp` and cannot mix `and` with `or`.
- Repeated `and` or repeated `or` is allowed. `and` and `or` bind more tightly than `imp`.
- The live MathML preview inserts grouping parentheses and renders digits as subscripts. Your typed input stays unchanged.
- Examples: `p and q imp r` → `(p ∧ q) → r`; `p imp q or r` → `p → (q ∨ r)`.
- Negation examples: `neg p and q` → `¬p ∧ q`; `neg (p and q)` → `¬(p ∧ q)`; `p or neg p` → `p ∨ ¬p`.

## Decision procedure

The browser loads `fCube-11.1 Original version/fCube-11.1/fCube/fCube.pl` unchanged into the official SWI-Prolog WebAssembly runtime. `src/engine.pl` calls its `intDecide/3` predicate and maps the returned proof marker to a verdict. This is the original fCube procedure, not a classical truth table or an alternate prover.

`true` is encoded as a theorem `t → t`, and `false` as its negation, using an internal proposition inaccessible to the input grammar. This preserves intuitionistic semantics while avoiding original fCube helper predicates that are not uniformly defined for numeric constants.

`neg` maps directly to the original prover's `non/1` connective.

Checks run in a worker with cancellation and a 30-second limit. A timeout or runtime error is reported as an incomplete check, never as an invalid formula. Editing the input clears a previous verdict and cancels any running check.

## Countermodels

After fCube 11.1 establishes invalidity, the same worker loads the original fCube 4.1 verbose source from `vendor/fcube4/`, isolated in a separate Prolog module. The module calls its search predicates directly, suppressing verbose output. Both original Prolog sources remain unchanged. The recovered 4.1 README and pinned mirror provenance are included in that directory and in the source archive.

The app reconstructs persistent atomic valuations from the nested tree, checks its signed annotations, and independently evaluates the original formula using intuitionistic Kripke semantics. Auxiliary atoms are then removed from the display. Identical sibling subtrees and redundant unary worlds are simplified; the resulting model is verified again before display. Worlds are never merged solely because they have the same atomic valuation.

Diagrams are static SVGs, with straight cover edges, the root at the bottom, and full proposition labels at every world (including inherited letters). No world names are displayed. With one, two, or three distinct input proposition letters, colored points and surrounding upset regions use Correct Partition's blue/red/yellow convention; overlaps correspond to purple/green/orange/brown. Labels remain visible. With more than three input letters, the entire diagram is monochrome. `∅` means no input proposition letters hold at that world. The input formula is not forced at the bottom root.

Generation has a 5,000,000-inference limit, a separate 10-second browser timeout, and a 200-world reconstruction limit. If it fails, times out, is cancelled, or produces a model that cannot be verified, the established invalidity verdict remains visible with an explanatory message. Formula edits clear both the verdict and the model. All generation and verification happens locally.

The server binds only to the local machine. All runtime assets are local; the app requires no network access after setup. fCube remains GPL-3.0-or-later; original attribution is preserved. See NOTICE.md and LICENSE.

## Adaptation and licensing

Adaptation date: 5 October 2026. The browser interface, infix syntax, MathML preview, worker adapter, tests, and static deployment packaging are new GPL-3.0-or-later additions. The original fCube 11.1 Prolog decision procedure is unchanged. Bundled dependencies retain their own licenses. The attribution page links to the complete GPL text, original notices, SWI-Prolog license, and the source ZIP generated with that version of the website. The archive includes build instructions and a SHA-256 manifest.

Countermodel adaptation date: 6 October 2026. The original fCube 4.1 source is also unchanged. Its module adapter, independent verification, and diagram renderer are GPL-3.0-or-later additions. See NOTICE.md for source provenance and the diagram palette reference.

## Verify

Run `node --test tests/*.test.mjs` for parser, preview, and actual fCube prover checks.
