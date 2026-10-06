% SPDX-License-Identifier: GPL-3.0-or-later
% Isolate the unchanged fCube 4.1 source from fCube 11.1's predicates.
:- module(fcube4, [fcube_countermodel/2]).
:- include('/fcube4.pl').

fcube_countermodel(Formula, Model) :-
    with_output_to(string(_),
        call_with_inference_limit(
            (permanenzaSegno([swff(f, Formula)], StartingSet),
             orderEquivSet(StartingSet, OrderedSet),
             reapply(OrderedSet, Model, 1, 1)),
            5000000, Result)),
    Result \== inference_limit_exceeded.
