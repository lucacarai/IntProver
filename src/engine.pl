% Adapter for the unchanged original fCube 11.1 decision procedure.
% SPDX-License-Identifier: GPL-3.0-or-later
% Browser adapter added 2026-10-05; original fCube remains unchanged.
fcube_validity(Formula, Verdict) :-
    with_output_to(string(_), intDecide(Formula, Proof, 1)),
    ( Proof == [valida] -> Verdict = valid
    ; Proof == [] -> Verdict = invalid
    ; throw(error(unexpected_fcube_result(Proof), fcube_validity/2))
    ).
