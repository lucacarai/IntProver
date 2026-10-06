# IntProver

This interface uses the original, unchanged fCube 11.1 Prolog decision procedure included in this workspace. Countermodels are generated separately using the unchanged fCube 4.1 verbose source, then independently checked against the original input's Kripke semantics.

Adaptation date: 5 October 2026. The browser interface, infix parser, mathematical preview, worker adapter, tests, and static deployment scripts are additions released under GPL-3.0-or-later. The fCube decision procedure has not been modified. The corresponding app source and build instructions are supplied in source.zip with each website build.

Countermodel adaptation date: 6 October 2026. A separate Prolog module isolates fCube 4.1 from 11.1. Model verification, simplification, and static SVG Hasse diagrams are new GPL-3.0-or-later additions. Both original Prolog programs remain unchanged. The recovered fCube 4.1 source, original README, and provenance are included under vendor/fcube4/ in the source download. Its SHA-256 is d7bab7a438f3216274500213ba6f789b7c1b101a5f5ca046c0cb95d8e4b5df82.

fCube 4.1 source mirror: https://github.com/ptarau/TypesAndProofs/tree/f107973a654d2449eb1447ac0047d3ac87d5554d/third_party/fCube-4.1

The blue/red/yellow colors and purple/green/orange/brown combinations follow the visual convention of Luca Carai's Correct Partition project: https://github.com/lucacarai/Correct-partition/blob/fecfd31d4f1cbbbceac5974ab87903702d6a026c/src/visual/palette.ts . The countermodel renderer and region geometry are independently implemented here.

fCube copyright: Mauro Ferrari, Camillo Fiorentini, Guido Fiorino (2012–2014). fCube and this application are licensed under GNU GPL version 3 or later. See LICENSE and the original README and source header.

The browser runtime is SWI-Prolog, distributed through the official swipl-wasm package, version 8.1.4. Its license is BSD-2-Clause; see vendor/package/LICENSE.txt. Source: https://github.com/SWI-Prolog/npm-swipl-wasm

All formula checks happen locally in a browser worker. No formulas are sent to an external service.
