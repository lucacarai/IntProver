# IntProver

This interface uses the original, unchanged fCube 11.1 Prolog decision procedure included in this workspace.

Adaptation date: 5 October 2026. The browser interface, infix parser, mathematical preview, worker adapter, tests, and static deployment scripts are additions released under GPL-3.0-or-later. The fCube decision procedure has not been modified. The corresponding app source and build instructions are supplied in source.zip with each website build.

fCube copyright: Mauro Ferrari, Camillo Fiorentini, Guido Fiorino (2012–2014). fCube and this application are licensed under GNU GPL version 3 or later. See LICENSE and the original README and source header.

The browser runtime is SWI-Prolog, distributed through the official swipl-wasm package, version 8.1.4. Its license is BSD-2-Clause; see vendor/package/LICENSE.txt. Source: https://github.com/SWI-Prolog/npm-swipl-wasm

All formula checks happen locally in a browser worker. No formulas are sent to an external service.
