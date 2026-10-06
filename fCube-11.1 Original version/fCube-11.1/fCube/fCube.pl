/*************************************************************************************
	 fCube: an efficient prover for Intuitionistic propositional Logic

    Copyright (C) 2012  Mauro Ferrari, 		email:	mauro.ferrari@uninsubria.it
			Camillo Fiorentini 	email:	fiorenti@dsi.unimi.it
			Guido Fiorino 		email: guido.fiorino@unimib.it

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
		

	
			INSTRUCTIONS
	Syntax:
	implication: 	im(,);
	negation: 	non();
	equivalence:	equiv(,);
	conjuncton:	and(,);
	disjunction:	or(,).
	Example: ((a&b)->~c) is im(and(a,b),non(c)) 
 	To decide a formula use the predicate 'decide'. 
   	For example 'decide(im(a,non(a))).';
        



This version requires swi-prolog.     
*************************************************************************************/

/****************************

Ottenuto da fCube-11 

Spostato il predicato time su decide. Adesso su intDecide non esiste piu' il predicato time 

****************************/

gnu:-	writeln('This is Fcube\nCopyright (C) 2014'),
	writeln('Mauro Ferrari,      email: mauro.ferrari@uninsubria.it,'),
	writeln('Camillo Fiorentini, email: fiorenti@dsi.unimi.it'),
	writeln('Guido Fiorino,      email: guido.fiorino@unimib.it'),
	writeln('This program comes with ABSOLUTELY NO WARRANTY.'),
    	writeln('This is free software, and you are welcome to redistribute it'),
    	writeln('under  conditions  GNU  Public License, see <http://www.gnu.org/licenses/> for details.'). 


/*
applica la semplificazione di Massacci, con A lista dei candidati, cioè le formule appena ottenute
per applicazione della regola
*/
semplificazioneCerta(A, B, NewerSet, ATOMS):- 
					newsimplification(A, B, NewSet, AtomsOfSimpl),
					!,
					(
					/*
					 * coerente(NewSet),
					 */
					newpermanenzaSegno(NewSet, NewerSet, AtomsOfPerm),
					union(AtomsOfSimpl, AtomsOfPerm, ATOMS),
					!
					;
					NewerSet = NewSet,
					ATOMS = AtomsOfSimpl
					).

semplificazioneBreve(A, B, NewSet, ATOMS):- 
					newsimplification(A, B, NewSet, ATOMS),
					!.


semplificazioneBranch(A, B, LastSet, ATOMS):- 
				semplificazione(A, B, LastSet, ATOMS).
				
/*
 * TheMoreNewSet e' l'insieme risultante dalle semplificazioni. Contiene solo formule
 * non atomiche, inoltre non contiene come sottoformule nessuna delle varprop
 * presenti in ATOMS.
 * ATOM e' un insieme di atomi segnati T o Fc. Sono stati tutti rimpiazzati in TheMoreNewSet
 */

semplificazione(A, B, TheMoreNewSet, ATOMS):-      
		      		/*
                                 * SimpSet e' l'insieme risultante dalle semplificazioni,
				 * SimpAtoms sono atomi segnati T o Fc e sono stati tutti 
                                 * rimpiazzati in SimpSet, quindi non vi occorrono
                                 */
				 
				newsimplification(A, B, SimpSet, SimpAtoms),
				
				/*
				 * writeln('Insieme iniziale:'),
				 * printSWFFSet(SimpSet,1),
				*/
				
				/*
				 * SimpSet + SimpAtoms e' l'insieme di formule in questione;
				 * SimpSet e' l'insieme da esplorare e su cui fare le semplificazioni
				 * TpermReplSet e' l'insieme di formule non atomiche risultante dalle
                                 * semplificazioni su SimpSet
				 * TpermReplAtoms e' l'insieme di formule atomiche segnate 
				 * T o Fc esse non compaiono in TpermReplSet e include le atomiche
				 * in SimpAtoms, quindi TpermReplSet + TpermReplAtoms rappresenta
				 * l'insieme delle formule in mano
				 */
				
				tPermanenceReplacement(SimpSet, SimpAtoms, TpermReplSet, TpermReplAtoms),
				
				/*
				 * arrivati qui TpermReplSet e' la parte delle formule non atomiche
				 * e TpermReplAtoms e' la parte di formule atomiche e vale che 
				 * nessuna di queste occorre come sottoformula in TpermReplSet
				 */
				
				/*
				 * writeln('Insieme dopo tsemplificazione:'),
				 * writeln('Non atomiche:'),
				 * printSWFFSet(TpermReplSet,1),
				 * writeln('Atomiche:'),
				 * printSWFFSet(TpermReplAtoms,1),
				*/
				
				!,
				
				(
				/*
				coerente(TpermReplSet),
				*/
				/*
				 * NewerSet contiene solo formule non atomiche e 
				 * AtomsOfPerm contiene solo atomi segnati T o Fc
				 * inoltre nessuna formula in AtomsOfPerm occorre come 
				 * sottoformula in NewerSet
				 */
				 
				
				newpermanenzaSegno(TpermReplSet, NewerSet, AtomsOfPerm),
				
				union(TpermReplAtoms, AtomsOfPerm, AtomsOfSimplAndPerm),
				/*
				 * Adesso NewerSet + AtomsOfSimplAndPerm e' l'insieme di
				 * formule in questione
				 */
				!,
				(
				/*
				 * coerente(NewerSet),
				 */
				!,
				/*
				 * TheMoreNewSet e' l'insieme risultante dalla clSimplification
				 * e AtomsOfCl sono segnati F quindi possono occorrere come 
				 * sottoformule di TheMoreNewSet
				 */
				clSimplification(NewerSet, TheMoreNewSet, AtomsOfCl),
				union(AtomsOfSimplAndPerm, AtomsOfCl, ATOMS), 
				!
				;
				TheMoreNewSet = NewerSet,
				ATOMS = AtomsOfSimplAndPerm
				)
				;
				TheMoreNewSet = TpermReplSet,
				ATOMS = TpermReplAtoms
				).
				


/* 
 * Dopo la semplificazione di B abbiamo un nuovo insieme, NewSet, che potrebbe avere atomi costanti.
 * Si calcola gli atomi con segno costante. Tali atomi, se esistono diventano i nuovi candidati per la
 * semplificazione, quindi si procede
 */
permanenzaSegno(NewSet, NewerSet, Atoms):- 	
		       	atomiConSegnoCostanteInSwffSet(NewSet, ListaAtomiConSegnoCostante), 
			!,
			iteraSemplificazione(ListaAtomiConSegnoCostante, NewSet, NewerSet, Atoms),
			!.

/* se non ci sono candidati, allora non c'è nulla da semplificare e la lista atomi e' vuota*/
iteraSemplificazione([], S, S, []).

/*
	I candidati in [A|L] vengono concatenati all'insieme ottenuto dalla semplificazione di Massacci.
	Si ottiene TempSet a cui si applica la semplificazione di Massacci, ottenendo NewTempSet.
	A questo punto si puo' iterare il procedimento ricalcolando la permanenza del segno.
*/

iteraSemplificazione([A|L], NewSet, NewerSet, ATOMS):-	
			    append([A|L],NewSet,TempSet),
			    !, 
			    newsimplification([A|L], TempSet, NewTempSet, SimplAtoms),
			    !,
			    /* chiama permanenza del segno se simplification ha 
			       fatto qualche rimpiazzamento
			    */
			    chiamaPermanenzaSegno(TempSet, NewTempSet, NewerSet, PermAtoms),
			    union(SimplAtoms, PermAtoms, ATOMS),
			    !.

chiamaPermanenzaSegno(TempSet, TempSet, TempSet, []).
chiamaPermanenzaSegno(_, NewTempSet, NewerSet, ATOMS):-	
			 	     	       permanenzaSegno(NewTempSet, NewerSet, ATOMS),
			 	     	       !.
						
/*
NOTA: 1) TRA LE FUNZIONI LEGATE ALLA XMANENZA DEL SEGNO OCCORREREBBE METTERNA UNA CHE FILTRI 
LE SWFF ATOMICHE DOPPIE IN [A|L] CIOÈ IN ListaAtomiConSegnoCostante
*/





uguali(X,X).



/*findWFFalpha, data una lista mette, se contiene una formula di tipo alpha 
la mette nella lista a secondo argomento e nel terzo ci mette la prima lista privata della formula alpha.
*/

findWFFalpha([],[],[]).
findWFFalpha([H|T],[H],T):-tipoalpha(H).
findWFFalpha([H|T],X,[H|Y]):-findWFFalpha(T,X,Y).


/* formule di tipo 1*/
tipoalpha(swff(t,and(_,_))).
tipoalpha(swff(t,equiv(_,_))).
tipoalpha(swff(f,or(_,_))).
/*tipoalpha(swff(t,im(X,_))):-atom(X).*/ /* valutare se toglierlo e gestire tale formula sempre a parte come caso speciale */
tipoalpha(swff(t,im(and(_,_),_))).
tipoalpha(swff(t,im(equiv(_,_),_))).
tipoalpha(swff(t,im(or(_,_),_))).
tipoalpha(swff(fc,or(_,_))).
tipoalpha(swff(t,non(_))).

/*formule di tipo 2*/
tipobeta(swff(f,and(_,_))).
tipobeta(swff(f,equiv(_,_))).
tipobeta(swff(t,or(_,_))).


/*formule di tipo 3*/
tipo3(swff(f,im(_,_))).
tipo3(swff(f,non(_))).

/*formule tipo4*/
tipo4(swff(t,im(im(_,_),_))).
tipo4(swff(t,im(non(_),_))).

/*formule tipo5*/
tipo5(swff(fc,im(_,_))).
tipo5(swff(fc,non(_))).

/*formule tipo6*/
tipo6(swff(fc,and(_,_))).
tipo6(swff(fc,equiv(_,_))).


/****************************************************

	PREDICATI PER LA PERMANENZA DEL SEGNO

****************************************************/

/*
Dato un insieme di swff determina la lista di formule atomiche con segno costante.
Questo predicato implementa la regola sui segni costanti in un insieme
*/

atomiConSegnoCostanteInSwffSet(SwffSet, ListOfAtomicSwffs):-
					segnoAtomiInSetOfSwff(SwffSet, TempSetOfVarPos, TempSetOfVarNeg),
					!,
					list_to_set(TempSetOfVarPos, SetOfVarPos),
					list_to_set(TempSetOfVarNeg, SetOfVarNeg),
					atomiConSegnoCost(SetOfVarNeg, SetOfVarPos, SwffAtomsWithConstantSign),
					subtract(SwffAtomsWithConstantSign, SwffSet, ListOfAtomicSwffs),
					!.


/* I SEGUENTI SONO PREDICATI DI SUPPORTO AL PRECEDENTE */

/*
Stabilisce il segno degli atomi in un insieme di formule segnate:
il primo argomento è un insieme di swff
il secondo argomento è la lista delle variabili segnate True
il terzo argomento e' la lista delle variabili  segnate False
*/


segnoAtomiInSetOfSwff([],[],[]).

/* 
	se la formula in cima alla lista e' atomica 
*/

segnoAtomiInSetOfSwff([swff(_,1)|T], PositiveInCoda, NegativeInCoda):-
							segnoAtomiInSetOfSwff(T, PositiveInCoda, NegativeInCoda).
segnoAtomiInSetOfSwff([swff(_,0)|T], PositiveInCoda, NegativeInCoda):-
							segnoAtomiInSetOfSwff(T, PositiveInCoda, NegativeInCoda).

segnoAtomiInSetOfSwff([swff(t,X)|T],[X | PositiveInCoda], NegativeInCoda):-
							atom(X),
							segnoAtomiInSetOfSwff(T, PositiveInCoda, NegativeInCoda).

segnoAtomiInSetOfSwff([swff(f,X)|T], PositiveInCoda, [X | NegativeInCoda]):-		
							atom(X),
							segnoAtomiInSetOfSwff(T, PositiveInCoda, NegativeInCoda).

segnoAtomiInSetOfSwff([swff(fc,X)|T], PositiveInCoda, [X| NegativeInCoda]):-	
								atom(X),
								segnoAtomiInSetOfSwff(T, PositiveInCoda, NegativeInCoda).


segnoAtomiInSetOfSwff([A|T], VarPositive, VarNegative):-   	
								segnoAtomiInSwff(A,VarPosInA,VarNegInA),
                                                		segnoAtomiInSetOfSwff(T,VarPosInCoda,VarNegInCoda),
                                                		append(VarPosInA, VarPosInCoda, VarPositive),
								append(VarNegInA,VarNegInCoda,VarNegative).


segnoAtomiInSwff(swff(t,A),VarPosInA,VarNegInA):-	segnoAtomiInSwffTrue(A,VarPosInA,VarNegInA).
segnoAtomiInSwff(swff(f,A),VarPosInA,VarNegInA):-	segnoAtomiInSwffFalse(A,VarPosInA,VarNegInA).
segnoAtomiInSwff(swff(fc,A),VarPosInA,VarNegInA):-	segnoAtomiInSwffFalse(A,VarPosInA,VarNegInA).
/*
stabilisce segno degli atomi in una formula segnata.
Il segno di un atomo puo' essere positivo o negativo 
*/
/*passo base*/
segnoAtomiInSwffTrue(X,[X],[]):-atom(X).
/*passo induttivo*/
segnoAtomiInSwffTrue(and(X,Y),Z,Atomi):-	segnoAtomiInSwffTrue(X,L,AtomiX),
						segnoAtomiInSwffTrue(Y,M,AtomiY), 
						append(L,M,Z),
						append(AtomiX,AtomiY,Atomi).

segnoAtomiInSwffTrue(equiv(X,Y),Z,Z):-		variabili(X,VarX),
						variabili(Y,VarY),
						union(VarX,VarY,Z).
						
segnoAtomiInSwffTrue(or(X,Y),Z,Atomi):-		segnoAtomiInSwffTrue(X,L,AtomiX),
						segnoAtomiInSwffTrue(Y,M,AtomiY), 
						append(L,M,Z),
						append(AtomiX,AtomiY,Atomi).

segnoAtomiInSwffTrue(im(X,Y),Z,Atomi):-		segnoAtomiInSwffFalse(X,L,AtomiX),
						segnoAtomiInSwffTrue(Y,M,AtomiY), 
						append(L,M,Z),
						append(AtomiX,AtomiY,Atomi).

segnoAtomiInSwffTrue(non(X),L,Atomi):-		segnoAtomiInSwffFalse(X,L,Atomi).


segnoAtomiInSwffFalse(X,[],[X]):-atom(X).


segnoAtomiInSwffFalse(and(X,Y),Z,Atomi):-	segnoAtomiInSwffFalse(X,L,AtomiX),
						segnoAtomiInSwffFalse(Y,M,AtomiY), 
						append(L,M,Z),
						append(AtomiX,AtomiY,Atomi).

segnoAtomiInSwffFalse(equiv(X,Y),Z,Z):-		variabili(X,VarX),
						variabili(Y,VarY),
						union(VarX,VarY,Z).

segnoAtomiInSwffFalse(or(X,Y),Z,Atomi):-	segnoAtomiInSwffFalse(X,L,AtomiX),
						segnoAtomiInSwffFalse(Y,M,AtomiY), 
						append(L,M,Z),
						append(AtomiX,AtomiY,Atomi).

segnoAtomiInSwffFalse(im(X,Y),Z,Atomi):-	segnoAtomiInSwffTrue(X,L,AtomiX),
						segnoAtomiInSwffFalse(Y,M,AtomiY), 
						append(L,M,Z),
						append(AtomiX,AtomiY,Atomi).

segnoAtomiInSwffFalse(non(X),L,Atomi):-		segnoAtomiInSwffTrue(X,L,Atomi).







/*lista le variabili in una swff*/

variabili(X,[X]):-	atom(X).

variabili(and(X,Y),L):-	variabili(X,M),
			variabili(Y,N),
			append(M,N,L).

variabili(equiv(X,Y),L):-variabili(X,M),
			 variabili(Y,N),
			 append(M,N,L).


variabili(or(X,Y),L):-	variabili(X,M),
			variabili(Y,N),
			append(M,N,L).

variabili(im(X,Y),L):-	variabili(X,M),
			variabili(Y,N),
			append(M,N,L).

variabili(non(X),L):-	variabili(X,L).


/*atomiConSegnoCost,stabilisce l'elenco delle variabili che hanno segno costante:
atomiConSegnoCost(SetOfVarNeg, SetOfVarPos, SwffAtomsWithConstantSign)
*/

atomiConSegnoCost(SetOfVarNeg, SetOfVarPos, SwffAtomsWithConstantSign):-
				subtract(SetOfVarPos, SetOfVarNeg, ConstantVarPos),
				subtract(SetOfVarNeg, SetOfVarPos, ConstantVarNeg),
				buildPositiveAtomic(ConstantVarPos, ConstantPositiveAtomic),
				buildNegativeAtomic(ConstantVarNeg, ConstantNegativeAtomic),
				union(ConstantPositiveAtomic, ConstantNegativeAtomic, SwffAtomsWithConstantSign).

buildPositiveAtomic([], []).
buildPositiveAtomic([ PropVar | Tail ], [ swff(t, PropVar) | Res]):-	buildPositiveAtomic( Tail, Res).

buildNegativeAtomic([], []).
buildNegativeAtomic([ PropVar | Tail ], [ swff(fc, PropVar) | Res]):-	buildNegativeAtomic( Tail, Res).

/*
STAMPE
printSWFFSet stampa una lista di formule. Il secondo parametro e' l'allineamento
printSWFF stampa una formula segnata, cioe' un termine che comincia con swff;
printWFF stampa una formula proposizionale
*/

printSWFFSet([],_).

printSWFFSet([X|Y],SPAZIO):-!,tab(SPAZIO*3),printSWFF(X),!,writeln(';'),printSWFFSet(Y,SPAZIO),!.

printSWFF(swff(S,0)):-upcase_atom(S,K),write(K),write(' 0').
printSWFF(swff(S,1)):-upcase_atom(S,K),write(K),write(' 1').
printSWFF(swff(S,X)):-upcase_atom(S,K),write(K),write(' '),printWFF(X).


printWFF(X):-atom(X),write(X).
printWFF(im(X,Y)):-write('('),printWFF(X),!,write('->'),printWFF(Y),!,write(')').
printWFF(or(X,Y)):-write('('),printWFF(X),!,write('|'),printWFF(Y),!,write(')').
printWFF(and(X,Y)):-write('('),printWFF(X),!,write('&'),printWFF(Y),!,write(')').
printWFF(non(X)):-write('~'),printWFF(X),!.
printWFF(equiv(X,Y)):-write('('),printWFF(X),!,write('='),printWFF(Y),!,write(')').


/****************************************************************

                 SEMPLIFICAZIONI BOOLEANE DI UNA FORMULA

valTerm(termine, valore): 	valuta ricorsivamente un termine:
				se termine è atomico allora vale se stesso;
				se termine è non atomico viene valutato seguendo la tavola di verità del connettivo principale.
************************************************************************************************/

/*passo base: il valore di un termine atomico è se stesso */
valTerm(0,0).
valTerm(1,1).
valTerm(X,X):-atom(X). 

/*passo induttivo: valore di un termine and */
valTerm(and(X,Y),RISP):-	valTerm(X,VALX),!,
                        	andTable(VALX,Y,RISP) /*guarda la tabella di verita' dell'AND*/
		                ,!.

valTerm(equiv(X,Y),RISP):-	valTerm(X, VALX),
				valTerm(Y, VALY),
                        	equivTable(VALX,VALY,RISP), /*guarda la tabella di verita' dell'EQUIV*/
		                !.

valTerm(or(X,Y),RISP):- 	valTerm(X,VALX),!,/*valuta il termine di sx*/
                        	orTable(VALX,Y,RISP) /*guarda la tabella di verita' dell'OR*/
		        	,!.

valTerm(im(X,Y),RISP):-valTerm(X,VALX),!,/*valuta il termine di sx*/
		       imTable(VALX,Y,RISP) /*guarda la tabella di verita' dell'OR*/
		       ,!.

valTerm(non(X),RISP):-valTerm(X,VALX), !,nonTable(VALX,RISP).

nonTable(0,1).
nonTable(1,0).
nonTable(VALX,non(VALX)).


andTable(0,_,0). /*se il congiunto di sx vale 0 allora la risposta vale 0 */
andTable(1,Y,RISP):-valTerm(Y,RISP),!. /* se il congiunto di sx vale 1 allora la risposta vale il valore del congiunto di dx*/
andTable(VALX,Y,RISP):-valTerm(Y,VALY),!, /*se il congiunto di sx è un termine qualsiasi allora si valuta il congiunto di dx */ 
	               andTable2(VALX,VALY,RISP).  /* e si guarda la tabella dell'and lungo la  colonna del secondo congiunto*/
andTable2(_,0,0). /* se il congiunto di dx vale 0, la risposta è 0 */ 
andTable2(VALX,1,VALX). /* se vale 1, la risposta è il valore del congiunto di sx */
andTable2(VALX,VALX,VALX).
andTable2(VALX,VALY,and(VALX,VALY)). /* altrimenti il valore è l'and del valore dei 2 congiunti */


orTable(1,_,1). /*se il congiunto di sx vale 1 allora la risposta vale 1 */
orTable(0,Y,RISP):-valTerm(Y,RISP). /* se il congiunto di sx vale 1 allora la risposta vale il valore del congiunto di dx*/
orTable(VALX,Y,RISP):-valTerm(Y,VALY), !,/*se il congiunto di sx è un termine qualsiasi allora si valuta il congiunto di dx */ 
	               orTable2(VALX,VALY,RISP).  /* e si guarda la tabella dell'and lungo la  colonna del secondo congiunto*/
orTable2(_,1,1). /* se il congiunto di dx vale 1, la risposta è 1 */ 
orTable2(VALX,0,VALX). /* se vale 0, la risposta è il valore del congiunto di sx */
orTable2(VALX,VALX,VALX).
orTable2(VALX,VALY,or(VALX,VALY)). /* altrimenti il valore è l'and del valore dei 2 congiunti */

/*Semplificazioni per l'implica*/

/*se l'antecedente vale 0 allora l'implicazione e' una tautologia, quindi la risposta vale 1 */
imTable(0,_,1). 

/* se l'antecedente vale 1 allora la risposta vale il valore del conseguente*/
imTable(1,Y,RISP):-	valTerm(Y,RISP),!. 

/*se l'antecedente è un termine qualsiasi, allora si valuta il conseguente */ 
imTable(VALX,Y,RISP):-				valTerm(Y,VALY),!, 
/*si decide in base al valore del conseguente*/	imTable2(VALX,VALY,RISP).  

/* se il conseguente vale: */
imTable2(_,1,1). /* 1, la risposta è 1 */ 
imTable2(VALX,0,non(VALX)). /* 0, siamo nel caso VALX -> false, cioe' non(VALX)*/
imTable2(VALX,VALX,1). /* come l'antecedente, siamo nel caso VALX->VALX, una tautologia */
imTable2(VALX,VALY,im(VALX,VALY)). /* una wff, allora il valore è VALX->VALY */


/**********************************************************

valutazione di una swff

**********************************************************/


valSWFF(swff(S,X),swff(S,Y)):-valTerm(X,Y).



/***********************************************************

  SOSTITUZIONE DI MASSACCI DI UNA FORMULA SEGNATA DENTRO UN'ALTRA FORMULA SEGNATA

***********************************************************/



/*
	data T X e S Y, esegue S Y[X/1], dove S è il segno di Y 
  	data Fc X e S Y, esegue S Y[X/0], dove ...
*/

massacci(swff(t,X),swff(S,Y),swff(S,RISP)):-massacciTrue(X,Y,RISP).
massacci(swff(fc,X),swff(S,Y),swff(S,RISP)):-massacciFalsoCerto(X,Y,RISP).


/*
  	data F X e S Y, esegue S Y{X/0}, 
	dove { } indica un rimpiazzamento che si ferma se si trova un connettivo implica o non
	e S e' il segno T o F MA NON Fc perche' Fc e' sinomimo di T non
*/

massacci(swff(f,X),swff(t,Y),swff(t,RISP)):-massacciFalso(X,Y,RISP).
massacci(swff(f,X),swff(f,Y),swff(f,RISP)):-massacciFalso(X,Y,RISP).
massacci(swff(f,_),swff(fc,Y),swff(fc,Y)). /* nelle formule Fc non vi è rimpiazzamento */

massacciTrue(X,X,1).
massacciTrue(_,1,1).
massacciTrue(_,0,0).
massacciTrue(_,Y,Y):-atom(Y).
massacciTrue(X,and(SX,DX),and(Y,Z)):-	massacciTrue(X,SX,Y),
	                             	massacciTrue(X,DX,Z).

massacciTrue(X,equiv(SX,DX),equiv(Y,Z)):-	massacciTrue(X,SX,Y),
	                             		massacciTrue(X,DX,Z).

massacciTrue(X,or(SX,DX),or(Y,Z)):-	massacciTrue(X,SX,Y),
	                             	massacciTrue(X,DX,Z).
massacciTrue(X,im(SX,DX),im(Y,Z)):-	massacciTrue(X,SX,Y),
	                             	massacciTrue(X,DX,Z).
massacciTrue(X,non(SX),non(Y)):-	massacciTrue(X,SX,Y).

/* data F X e S Y, esegue S Y[X/0] */
massacciFalsoCerto(X,X,0).
massacciFalsoCerto(_,0,0).
massacciFalsoCerto(_,1,1).
massacciFalsoCerto(_,Y,Y):-atom(Y).
massacciFalsoCerto(X,and(SX,DX),and(Y,Z)):-	massacciFalsoCerto(X,SX,Y),!,
	                             		massacciFalsoCerto(X,DX,Z),!.

massacciFalsoCerto(X,equiv(SX,DX),equiv(Y,Z)):-	massacciFalsoCerto(X,SX,Y),!,
	                             		massacciFalsoCerto(X,DX,Z),!.

massacciFalsoCerto(X,or(SX,DX),or(Y,Z)):-	massacciFalsoCerto(X,SX,Y),!,
	                             		massacciFalsoCerto(X,DX,Z),!.
massacciFalsoCerto(X,im(SX,DX),im(Y,Z)):-	massacciFalsoCerto(X,SX,Y),!,
	                             		massacciFalsoCerto(X,DX,Z),!.
massacciFalsoCerto(X,non(SX),non(Y)):-		massacciFalsoCerto(X,SX,Y),!.


/* data F X e S Y, esegue S Y{X/0} */
massacciFalso(X,X,0).
massacciFalso(_,0,0).
massacciFalso(_,1,1).
massacciFalso(_,Y,Y):-atom(Y).
massacciFalso(X,and(SX,DX),and(Y,Z)):-	massacciFalso(X,SX,Y),!,
	                             	massacciFalso(X,DX,Z),!.
massacciFalso(X,or(SX,DX),or(Y,Z)):-	massacciFalso(X,SX,Y),!,
	                             	massacciFalso(X,DX,Z),!.
massacciFalso(_,im(SX,DX),im(SX,DX)). /* su implica e non il rimpiazzamento si ferma */
massacciFalso(_,equiv(SX,DX),equiv(SX,DX)). /* su implica equiv e non il rimpiazzamento si ferma */
massacciFalso(_,non(SX),non(SX)).





/*	
 *	substitute(F,SETOFSWFF,NEWSETOFSWFF,SETOFCANDIDATES)	
 *	F formula da rimpiazzare; 
 *	SETOFSWFF insieme in cui eseguire il rimpiazzamento;
 *	NEWSETOFSWFF insieme di formule risultante; 
 *	SETOFCANDIDATES nuovi candidati da usare per eseguire un nuovo rimpiazzamento.
*/

substitute(swff(_,0), SETOFSWFF, SETOFSWFF, []):- !.
substitute(swff(_,1), SETOFSWFF, SETOFSWFF, []):- !.
substitute(F, SETOFSWFF, SETOFSWFF, []):-	
/*
 *	se F non appartiene all'insieme non si fanno sostituzioni
 */ 
					not(memberchk(F,SETOFSWFF)),
					!.

substitute(F, SETOFSWFF, NEWSETOFSWFF, SETOFCANDIDATES, ATOMS):-	
/*
 *	se F appartiene all'insieme  si fanno sostituzioni
 */ 
				      	goToSubstitute(F, SETOFSWFF, NEWSETOFSWFF, SETOFCANDIDATES, ATOMS).

					                           
					   
/*	
	goToSubstitute(F,[H|T],[RISP|NI],NEWCANDIDATES)
	rimpiazza F in [H|T]. 
	
	TheReplacementResult[RISP|NI] e' il risultato del rimpiazzamento.
	NEWCANDIDATES sono le nuove swff generate dal rimpiazzamento di F in [H|T]

*/

goToSubstitute(_,[],[],[], []).
goToSubstitute(swff(Sign, Wff), [swff(Sign,Wff) | T], RIS, NC, ATOMS):- !,
				    goToSubstitute(swff(Sign, Wff), T, NI, NC, TempAtoms),
				    (
				    atom(Wff),
				    memberchk(Sign, [t,fc]),
				    !,
				    RIS = NI,
				    ATOMS = [swff(Sign, Wff) | TempAtoms]
				    ;
				    RIS = [swff(Sign, Wff) | NI],
				    ATOMS = TempAtoms
				    ).

goToSubstitute(F, [H|T], TheReplacementResult, NEWCANDIDATES, ATOMS):-	
/*
 *	esegue il rimpiazzamento H[F/val], risultato in RR
 */								
						    massacci(F,H,RR),
						    !, 
/*
 *	semplificazione di RR, risultato in RISP
 */
						    valSWFF(RR,RISP),
/* 
 * TODO: se RISP e' formula contraddittoria 
 * 	 allora TheReplacementResult = [RISP | T] e
 * 	        NEWCANDIDATES = [] 
 *	 altrimenti passo ricorsivo di rimpiazzamento di F in T.
 *	 possiamo così evitare la chiamata a coerente fatta sopra.
 */							   
 						    goToSubstitute(F, T, NI, NC, ATOMS),
						    !,
						    buidReplacementResult(RISP,NI,TheReplacementResult),
						    !,
/*
 *	Se RISP <> da H, 
 *	allora RISP e' un nuovo candidato
 */		
						    updatecandidates(NC,H,RISP,NEWCANDIDATES). 
/* forse qui va un ! */ 

 
buidReplacementResult(swff(t,1),NI,NI).
buidReplacementResult(swff(f,0),NI,NI).
buidReplacementResult(swff(fc,0),NI,NI).
buidReplacementResult(RISP,NI,[RISP|NI]).

/* 
 * Se H non e' stata modificata dal rimpiazzamento, allora non e' una formula candidata 
 */                                                                  	
updatecandidates(NC,H,H,NC):-!.  

/*
 *	inutile mettere queste formule tra i candidati 
 */
updatecandidates(NC,_,swff(t,1),NC).  
updatecandidates(NC,_,swff(f,0),NC).
updatecandidates(NC,_,swff(fc,0),NC).
 

/*
 *	inutile mettere queste formule tra i candidati, l'insieme è inconsistente 
 */
updatecandidates(_,_,swff(t,0), []). 
updatecandidates(_,_,swff(f,1), []).
updatecandidates(_,_,swff(fc,1), []).
updatecandidates(NC,_,RIS,[RIS|NC]).


/**************************************************************

	Predicati usati per implementare la regolarita'

**************************************************************/


/* valore della wfff X nella lista di swff M che funge da modello:
   NOTA BENE: formule del tipo swff(t,1) etc NON VENGONO CONSIDERATE 
*/

realizzata(swff(t,WFF),M):- atom(WFF),!, memberchk(swff(t,WFF),M).

/*una F-atomica è realizzata se la corrispondente T non appartiene al modello*/
realizzata(swff(f,WFF),M):- atom(WFF),!, not(memberchk(swff(t,WFF),M)). 

realizzata(swff(t,and(SX,DX)),M):- realizzata(swff(t,SX),M),!,realizzata(swff(t,DX),M),!.
realizzata(swff(t,equiv(SX,DX)),M):- realizzata(swff(t,im(SX,DX)),M),!,realizzata(swff(t,im(DX,SX)),M),!.
realizzata(swff(t,or(SX,_)),M):- realizzata(swff(t,SX),M),!.
realizzata(swff(t,or(_,DX)),M):- realizzata(swff(t,DX),M),!.
realizzata(swff(t,im(_,DX)),M):- realizzata(swff(t,DX),M),!.
realizzata(swff(t,im(SX,_)),M):- realizzata(swff(f,SX),M),!.
realizzata(swff(t,non(WFF)),M):- realizzata(swff(f,WFF),M),!.

realizzata(swff(f,or(SX,DX)),M):- realizzata(swff(f,SX),M),!,realizzata(swff(f,DX),M),!.
realizzata(swff(f,and(SX,_)),M):- realizzata(swff(f,SX),M),!.
realizzata(swff(f,and(_,DX)),M):- realizzata(swff(f,DX),M),!.

realizzata(swff(f,equiv(SX,DX)),M):- realizzata(swff(f, and(im(SX,DX), im(DX,SX))), M),!.

realizzata(swff(f,im(SX,DX)),M):- realizzata(swff(t,SX),M),!,realizzata(swff(f,DX),M),!.
realizzata(swff(f,non(WFF)),M):- realizzata(swff(t,WFF),M),!.


/*********************************************************************************

		PREDICATI PER IMPLEMENTARE L'INTUIZIONISMO

*********************************************************************************/

decide(X):-				gnu,
					time(intDecide(X,_,1)).

intDecide(X,[],NUMERO):-		writeln('\n'),
					permanenzaSegno([swff(f,X)],StartingSet, _),
					orderEquivSet(StartingSet, OrderedStartingSet),
					reapply(OrderedStartingSet, _, 1, 1),
					!,
					writeln(' '), 
					write(NUMERO),
					writeln(' search result = unprovable (fCube-11)').
					
					
					
intDecide(_,[valida],NUMERO):-		writeln(' '),
					write(NUMERO),
					writeln(' search result = provable (fCube-11)').

/*
			reapply(RESULT,MODEL) 
	
	VERIFICA L'INSIEME RESULT PRIMA DI TENTARE DI COSTRUIRE IL CONTROMODELLO
	se RESULT E' coerente lo suddivide in 2 insiemi. BACK e RESTO.
	reapply fallisce se RESULT rappresenta una formula valida
*/	

reapply(SET, MODEL, SPAZIO, IdxNewAtom):-	
	     
	     coerente(SET),
	     
	     !,
	     buildBack(SET,BACK,RESTO),
	     !,  
	     intControModello(BACK, RESTO, ModelOfTheRule, SPAZIO+1, WhichBranch, IdxNewAtom),
	     !,
	     kripke(SET, BACK, WhichBranch, ModelOfTheRule, MODEL),
	     !.

/*SIBLINGS=nosiblings significa che */	
/*una delle formule di tipo 4 è stata*/
/*espansa con il ramo safe.*/
/*Questo ha rilevanza per come si*/
/*costruisce il contromodello*/
					
/* reapply(_,_,SPAZIO,_):-	tab(3*SPAZIO-3), writeln('CLOSED SET'), fail.	*/

/*
		COSTRUISCE CONTROMODELLO INTUIZIONISTA

intControModello(BACK,RESTO,COUNTERMODEL,SPAZIO, jumpbranch | safebranch,IdxNewAtom): 
costruisce il contromodello a BACK unione RESTO. 
Se il contromodello non esiste 
allora COUNTERMODEL contiene [no countermodel]. 
intControModello viene chiamato su un insieme coerente.
SPAZIO: variabile usata per la stampa;
jumpbranch | safebranch : specifica se la conclusione di rule ha Sc o no. L'informazione e' usata da 
continuaIterazione per trattare T->-> e T->non;
IdxNewAtom e' un intero che serve a generare sistematicamente nuovi atomi per T->->.
*/

intControModello([], RESTO, Contromodello, _, safebranch, _):-
			   /*
			     Passo base:
			     Se non ci sono regole da applicare allora Atoms e' il
			     contromodello di RESTO +  Atoms
			     */		   
			   filtraNonAtomiche(RESTO, Contromodello).
			   
			   
			   /* se non ci sono regole da applicare 
                              allora dato che RESTO è coerente, il contromodello è RESTO 
			      e la conclusione è considerata safe
			    */

intControModello( [ swff(fperm, list(Wff,Atoms))], RESTO, MODEL, SPAZIO, WhichBranch, 
		    IdxNewAtom):-
		    !,	
		    rule(swff(fperm,list(Wff,Atoms)), RESTO, RESULT, WhichBranch, IdxNewAtom, AtomsOfResult),
		    	/*		      
				write('Main SWFF: '), 
				printSWFF(swff(f,Wff)),
				write(' with constant atoms: '),
				write(Atoms),  
				writeln('\n'),
				printSWFFSet(RESULT,SPAZIO),
				writeln('\n'),
		          */      
		    	
		   succ(IdxNewAtom, NextIdx),
		   reapply(RESULT, _, SPAZIO, NextIdx),
		   !,
		   /**************
		   filtraNonAtomiche(RightSuccessor, AtomicRightSuccessor),
		   rimuoviAtomiOpposti(Atoms, AtomicRightSuccessor, RightSuccessorFiltered),
		   !,
		   union(Atoms, RightSuccessorFiltered, LeftSuccessor),
		   /*adesso il fratello e' costruito correttamente*/
		   /*filtra le non Atomiche dall'insieme nodo che e' padre*/	
		   /*incolla i due modelli in uno*/
		   union([swff(f, Wff) | AtomsOfResult], [LeftSuccessor,AtomicRightSuccessor ],MODEL).
	           ************************/
		   MODEL =  [swff(f, Wff) | AtomsOfResult].


intControModello([H], RESTO, MODEL, SPAZIO, WhichBranch, IdxNewAtom):-
			     !,	

			     rule(H, RESTO, RESULT, WhichBranch, IdxNewAtom, ATOMS),
			     /*
			      write('Main SWFF: '), 
			      printSWFF(H),
			      writeln('\n'),
			      printSWFFSet(RESULT,SPAZIO),
			      writeln(' '),
			     */
			      
			      succ(IdxNewAtom,NextIdx),

			      reapply(RESULT, ModelOfResult, SPAZIO, NextIdx),
			      union(ATOMS, ModelOfResult, MODEL),
			      !.
							
intControModello([H,T|BACK], RESTO, MODEL, SPAZIO, WhichBranch, IdxNewAtom):-	
			     append([T|BACK], RESTO, SET),

			     intControModello([H], SET, MODELH, SPAZIO, HWhichBranch, IdxNewAtom),
			     !,
			     
			     /* ci domandiamo se davvero
			        abbiamo bisogno di fare
			        backtracking su [T|BACK]
			     */
 	
      		    	     continuaIterazione([T|BACK], [H|RESTO], MODELH, MODEL, SPAZIO, HWhichBranch,
			     				  IdxNewAtom, WhichBranch),
			     !.
				
						
/* 
se H e' di tipo 4 ed il contromodello MODELH e' stato ottenuto applicando il ramo safe,
allora non c'e' bisogno di alcuna iterazione ed il contromodello restituito è [] 
*/

continuaIterazione(_,[H|_], MODELH, MODELH, _, safebranch, _, safebranch):- tipo4(H).

/*
se l'intero insieme di formule sia realizzato da MODELH, 
allora questo è il modello dell'intero insieme e non c'e' bisogno di andare avanti 
con l'iterazione. L'applicazione della regola puo' essere considerata safe
*/

/*	nota che questa condizione se attivata riguarda H di tipo 3 o 4. 
	Nel caso di tipo 4 riguarda l'applicazione non safe della regola
*/

continuaIterazione([T|BACK], [_ | RESTO], MODELH, MODELH, _, jumpbranch, _, safebranch):-

/*ricostruisce l'insieme nodo, non considera H*/	append([T|BACK], RESTO, Set),
/*estrae le formule segnate F	*/			falseSWFF(Set, FSWFF),
/*se tutte le F-swff di SET sono classiche e*/ 		tutteClassiche(FSWFF),
/*realizzate fermiamo il backtrack*/			insiemeRealizzato(FSWFF, MODELH).
/*altrimenti lo proseguiamo. 
  Nota che quando fermiamo il backtrack 
  è come se avessimo applicato una regola safe
*/
														

/*
se  il contromodello MODELH e' stato ottenuto applicando il ramo Sc,
allora andiamo avanti con il backtrack  
*/
continuaIterazione([T|BACK], [H|RESTO], MODELH, MODEL, SPAZIO, jumpbranch, IdxNewAtom, WhichBranch):- 
                   /*
		   writeln('Found a backtacking point:\n'),
                   union([H,T|BACK], RESTO, NodeSet),
                   printSWFFSet(NodeSet,SPAZIO-1),
                   writeln(' '),
		   */
/*L'insieme complessivo continua ad essere [T|BACK] + [H|RESTO] */
                   intControModello([T|BACK], [H|RESTO], MODELRESTO, SPAZIO, WhichBranch, IdxNewAtom),
                   !,
                   gluesiblings(WhichBranch, BACK, MODELH, MODELRESTO, MODEL),
                   !.


						
gluesiblings(jumpbranch,[], MODELH, MODELRESTO, [MODELH,MODELRESTO]).
gluesiblings(jumpbranch, _, MODELH, MODELRESTO, MODEL):- append([MODELH], MODELRESTO, MODEL).
gluesiblings(safebranch, _, _, MODELRESTO, MODELRESTO).	 
/*
	falseSWFF(Set,FSWFF),estrae le formule segnate F
*/
falseSWFF([],[]).
falseSWFF([swff(f,X)|T],[swff(f,X)|R]):- !,falseSWFF(T,R),!.
falseSWFF([_|T],R):- !,falseSWFF(T,R),!.

/*
tutteClassiche(FSWFF), stabilisce se tutte le F-swff di SET sono classiche
*/
tutteClassiche([]).
tutteClassiche([H|T]):- isSwffClassic(H,1), tutteClassiche(T),!.

/*
insiemeRealizzato(FSWFF,MODELH), stabilisce se MODELH realizza le formule classiche di FSWFF
*/
insiemeRealizzato([],_).
insiemeRealizzato([H|T],MODELH):-	realizzata(H,MODELH),insiemeRealizzato(T,MODELH),!.	


/************************************************************************

		COSTRUZIONE DI UNA PARTE DEL CONTROMODELLO

kripke(SET,BACK,WhichBranch,ModelOfTheRule,MODEL)
SET è l'insieme di formule. Ha un ruola solo quando è un saturato,
BACK 	nei casi in cui WhichBranch= jumpbranch permette di sapere se TheModelOfRESULT 
     	è una lista che rappresenta esattamente uno stato oppure una lista in cui ogni componente è una lista 
     	che rappresenta uno stato
WhichBranch 	vale safebranch se RESULT è ottenuto da un ramo safe, 
		vale jumpbranch se RESULT è ottenuto da un ramo di jump
TheModelOfRESULT il modello relativo a RESULT
MODEL il modello restituito,
************************************************************************/

kripke(_,_,safebranch,MODEL,MODEL).
kripke(SET,[_],jumpbranch,TheModelOfRESULT,MODEL):-		filtraNonAtomiche(SET, FilteredSet),
								append(FilteredSet, [TheModelOfRESULT], MODEL).
kripke(SET,[_,_|_],jumpbranch,TheModelOfRESULT,MODEL):-		filtraNonAtomiche(SET, FilteredSet),
								append(FilteredSet, TheModelOfRESULT, MODEL).
kripke(_,_,_,_,_):- 						writeln('CHIAMATA A KRIPKE NON CORRISPONDE'),
								abort.

/*
STAMPA IL MODELLO DI KRIPKE
*/

printKripke([],_).
printKripke([swff(S,WFF)|T],SPAZIO):-		printSWFFSet([swff(S,WFF)],SPAZIO),
						!,
						printKripke(T,SPAZIO),
						!.
printKripke([[X|Y]|Z],SPAZIO):-			writeln('-- end world -- '),
						printKripke([X|Y],SPAZIO+1),
						!,
						printKripke(Z,SPAZIO),
						!.

printKripke([[]|Z],SPAZIO):-			writeln(' '),
						printKripke([swff(t,emptyNode)],SPAZIO+1),
						!,
						printKripke(Z,SPAZIO),
						!.

printKripke(_,_):-				writeln('printKripke NON CORRISPONDE'),abort.



/*
coerente e' vero se la lista e' vuota oppure oppure ha solo un elemento oppure 
Y e' coerente e Y non contiene una formula di segno opposto a X 
*/

coerente([]).

coerente(L):-	not(memberchk(swff(t,0),L)),
		not(memberchk(swff(f,1),L)),
		not(memberchk(swff(fc,1),L)).

				

/*
 *
 * buildBack(SET,BACK,RESTO): costruisce l'insieme di backtrack. Se SET contiene almeno una
 * swff di tipo 1 o 2 allora BACK ha solo 1 formula. Se non contiene formule di tipo 1 o 2
 * allora vengono collezionate in BACK tutte quelle di tipo 3 e 4.  Se questi tipi di swff
 * non sono presenti in SET, allora si cerca una formula di tipo 5 o 6. Se neppure formule di
 * questo tipo esistono allora SET non è espandibile.
 *
*/

buildBack(SET,[B|ACK],RESTO):- cercaTipiAlphaBeta(SET,[B|ACK],RESTO).

/*
 * se cercaPermanenceFormula(SET,[B|ACK],RESTO) ha successo, 
 * allora B contiene una F-> formula a cui applicare una delle permanence rules
 */
buildBack(SET,[swff(fperm,list(X,TheConstantAtoms))],RESTO):- 	
						cercaPermanenceFormula(SET,[swff(f,X)],RESTO,TheConstantAtoms).
					

buildBack(SET,[B|ACK],RESTO):- cercaBack(SET,[B|ACK],RESTO).
buildBack(SET,[B|ACK],RESTO):- cercaTipi5e6(SET,[B|ACK],RESTO).  
buildBack(SET,[],SET). /*  attenzione: questo caso unfica anche con tutti gli altri precedenti, 
                        *   non è in esclusione */

/*
	glueModels: incolla i contromodelli
*/

glueModels(RADICE,SX,DX,[RADICE,SX,DX]).


/*

STABILISCE SE UNA SWFF E' CLASSICA

*/

isSwffClassic(swff(f, WFF),RISP) :- isWffClassic(WFF,RISP),!.
isSwffClassic(swff(t, WFF),RISP) :- isWffClassic(WFF,RISP),!.
isSwffClassic(swff(fc, _),0). /* le Fc non sono classiche */


isWffClassic(1,1):- writeln('isWFFClassic chiamato con wff uguale a 1'). 
isWffClassic(0,1) :- writeln('isWFFClassic chiamato con wff uguale a 0'). 
				/* le formule 1 e 0 sono classiche, questo caso non dovrebbe mai verificarsi */
isWffClassic(WFF,1):-atom(WFF),!.
isWffClassic(and(LEFT,RIGHT),1) :- isWffClassic(LEFT,1),!, isWffClassic(RIGHT,1),!.
isWffClassic(or(LEFT,RIGHT),1) :- isWffClassic(LEFT,1),!, isWffClassic(RIGHT,1),!.
isWffClassic(WFF,0):- not(isWffClassic(WFF,1)),!. /* in tutti gli altri casi non è wff classica */

/*
cercaTipiAlphaBeta(X,BACK,RESTO):
cerca una formula di tipo 1 o 2 da espandere. Restituisce in BACK una formula e in RESTO le restanti formule di X
cioè X=BACK unione RESTO
*/

cercaTipiAlphaBeta(X,BACK,RESTO):- 	cercaTipiAlphaBetaModel(X,X,BACK,RESTO).

/*
cercaTipiAlphaBetaModel usa il primo argomento come modello, quindi non viene mai modificato
*/

/*passi base*/
cercaTipiAlphaBetaModel(_,[],[],[]).
cercaTipiAlphaBetaModel(MODEL,[swff(S,1)|T],BACK,RESTO):-	cercaTipiAlphaBetaModel(MODEL,T,BACK,RESTOdiT), 
								append(RESTOdiT,[swff(S,1)],RESTO).
cercaTipiAlphaBetaModel(MODEL,[swff(S,0)|T],BACK,RESTO):-	cercaTipiAlphaBetaModel(MODEL,T,BACK,RESTOdiT), 
								append(RESTOdiT,[swff(S,0)],RESTO).
cercaTipiAlphaBetaModel(MODEL,[swff(S,A)|T],BACK,RESTO):-	atom(A),!,
								cercaTipiAlphaBetaModel(MODEL,T,BACK,RESTOdiT), 
								append(RESTOdiT,[swff(S,A)],RESTO).
/*Arrivati qui sappiamo che A non è atomica */

/* CASO T->atom: si potrebbe trattare come caso speciale e  tirar via dall'insieme di formule di tipo alpha,
cosi' da non farlo corrispondere anche al caso seguente:
L'insieme BACK conterra' una T (p->A) se T p è in X 
*/ 

cercaTipiAlphaBetaModel(MODEL,[swff(t,im(X,Y))|B],[swff(t,im(X,Y))],B):- 	atom(X), 
										memberchk(swff(t,X),MODEL).

cercaTipiAlphaBetaModel(_,[A|B],[A],B):-					tipoalpha(A).

/*arrivati qua sappimo che A è di tipo beta*/

cercaTipiAlphaBetaModel(MODEL,[A|B],BACK,RESTO):-	tipobeta(A),
/* A classica ma non realizzata,*/			isSwffClassic(A,1),
/* A e' swff tipo beta da espandere*/			not(realizzata(A,MODEL)), !, 
/* vediamo se troviamo una swff alpha*/			findWFFalpha(B,BACKdiB,RESTOdiB), 
/* predicato di supporto*/				sistema(A,B,BACKdiB,RESTOdiB,BACK,RESTO).


cercaTipiAlphaBetaModel(_,[A|B],BACK,RESTO):-		tipobeta(A),
/* Arrivati qui sappiamo che A e' di tipo beta */	isSwffClassic(A,0),!,
/* Arrivati qui sappiamo che A non e' classica*/
/* quindi e' da espandere*/
/* vediamo se troviamo una swff alpha*/			findWFFalpha(B,BACKdiB,RESTOdiB), 
/* predicato di supporto*/				sistema(A,B,BACKdiB,RESTOdiB,BACK,RESTO).

/*arrivati qua sappiamo che A è di tipo beta ed è realizzata dal modello sottostante, 
quindi non c'e' bisogno di espanderla, cerchiamo un'altra formula nell'insieme B*/

cercaTipiAlphaBetaModel(MODEL,[A|B],BACK,RESTO):- 	cercaTipiAlphaBetaModel(MODEL,B,BACK,RESTOdiB), 
							append(RESTOdiB,[A],RESTO).

/*in B non c'e' wff di tipo alpha. Allora l'insieme di backtrack è fatto dalla wff A, che è di tipo beta, 
la parte restante è nell'insieme B
*/

sistema(A,B,[],_,[A],B).

/*se una wff di tipo alpha è stata trovata in B, allora l'insieme di backtracking è fatto dalla formula
alpha appena trovata, RESTO è A+RESTOdiB*/

sistema(A,_,BACKdiB,RESTOdiB,BACKdiB,RESTO):-		append([A],RESTOdiB,RESTO).



/*
cercaBack(X,BACK,RESTO) mette in BACK le formule di X che sono di tipo 3 e 4, le restanti le mette in RESTO.
Si comporta come segue:  colleziona in T3 le formule di tipo3 di X, colleziona in T4 le formule di tipo 4 di X,
costruisce l'insieme di backtracking secondo la seguente strategia: se T3 ha una F-formula che è l'unica F-formula di X,
allora non c'e' biogno di fare backtrack e quindi BACK=T3; se X non contiene F-formule 
allora BACK conterra esattamente una formula di T4. Se i precedenti casi non valgono allora 
BACK=T3 unione T4.
*/

cercaBack(X,BACK,RESTO):- 	prendeTipo3(X,T3,R3),
				prendeTipo4(R3,T4,R4),
				costruisciBack(T3,T4,R4,BACK,RESTO).


prendeTipo3([],[],[]). 		/* l'insieme di ricerca è vuoto */
prendeTipo3([A|T],[A|T3],R3):-	tipo3(A),
				!,
				prendeTipo3(T,T3,R3).
/*se arriviamo qui A non è di tipo 3, quindi le swff di tipo 3 si trovano in T e A e' una delle formule di RESTO */
 
prendeTipo3([A|T],T3,[A|R3]):-	prendeTipo3(T,T3,R3).		

prendeTipo4([],[],[]). 		/* l'insieme di ricerca è vuoto */
prendeTipo4([A|T],[A|T4],R4):-	tipo4(A),
				!,
				prendeTipo4(T,T4,R4).
/*se arriviamo qui A non è di tipo 4, quindi le swff di tipo 4 si trovano in T e A e' una delle formule di RESTO */
 
prendeTipo4([A|T],T4,[A|R4]):-	prendeTipo4(T,T4,R4).		


costruisciBack([A],T4,R4,[A],RESTO):-	haZeroFFormule(R4), /* L'insieme X ha esattamente una swff di tipo 3 */
					!,
					append(T4,R4,RESTO).  

costruisciBack([],[A|T4],R4,[A],RESTO):-	haZeroFFormule(R4), /* X ha zero F-swff, in BACK metto una swff di tipo 4 */
						!,
						append(T4,R4,RESTO).

/* qui si deve gestire anche il caso che X non abbia swff di tipo 3 e 4 */

costruisciBack(T3,T4,R4,BACK,R4):-		append(T3,T4,BACK).
						
						
					

/*
cercaTipi5e6(X,BACK,RESTO) cerca una formula di tipo 5 o 6 da espandere. 
Restituisce in BACK una formula e in RESTO le restanti formule di X
cioè X=BACK unione RESTO
*/

/*passi base*/
cercaTipi5e6([],[],[]).
cercaTipi5e6([swff(S,1)|T],BACK,RESTO):-			cercaTipi5e6(T,BACK,RESTOdiT), 
								append(RESTOdiT,[swff(S,1)],RESTO).

cercaTipi5e6([swff(S,0)|T],BACK,RESTO):-			cercaTipi5e6(T,BACK,RESTOdiT), 
								append(RESTOdiT,[swff(S,0)],RESTO).

cercaTipi5e6([swff(S,A)|T],BACK,RESTO):-			atom(A),!,
								cercaTipi5e6(T,BACK,RESTOdiT), 
								append(RESTOdiT,[swff(S,A)],RESTO).
/*Arrivati qui sappiamo che A non è atomica, 
  verifichiamo non sia una T(p->B) cioe' una swff che si comporta come un'atomica perche' nell'insieme
  manca T p 
*/

cercaTipi5e6([swff(t,im(A,Y))|T],BACK,RESTO):-			atom(A),!,
								cercaTipi5e6(T,BACK,RESTOdiT), 
								append(RESTOdiT,[swff(t,im(A,Y))],RESTO).


cercaTipi5e6([A|B],[A],B):-					tipo5(A).

/*arrivati qua sappimo che A non e' di tipo 5*/

cercaTipi5e6([A|B],BACK,RESTO):-				tipo6(A),
	/*trovata una swff tipo 6 da espandere*/			 
	/*vediamo se troviamo una swff tipo 5*/			findWFFtipo5(B,BACKdiB,RESTOdiB), 
	/*predicato di supporto*/				sistema(A,B,BACKdiB,RESTOdiB,BACK,RESTO).


/* arrivati qui sappiamo che A non e' neppure di tipo 6, quindi sara' del tipo swff(t,im(p,H)),
cioè una formula che si comporta come un'atomica */

cercaTipi5e6([A|B],BACK,[A|RESTOdiB]):-	cercaTipi5e6(B,BACK,RESTOdiB).



findWFFtipo5([],[],[]).
findWFFtipo5([H|T],[H],T):-		tipo5(H).
findWFFtipo5([H|T],X,[H|Y]):-		findWFFtipo5(T,X,Y).




/* 
	REGOLE INTUIZIONISTE

rule(H,S,RESULT, safebranch | jumpbranch): 
H e' la main swff a cui applicare la regola;
S e' l'insieme;
NEWS e' l'insieme rislutato dopo la semplificazione
safebranch se la conclusione non ha Sc, altrimenti jumpbranch
*/

/*regola T and*/
rule(swff(t,and(X,Y)), S, NEWS, safebranch, _, ATOMS):-	
				!,
				estraiListaTAnd(and(X,Y), ListaAnd),
				union(ListaAnd, S, S1),
				semplificazioneBreve(ListaAnd, S1, NEWS, ATOMS).


rule(swff(t,equiv(X,Y)), S, NEWS, safebranch, _, ATOMS):- 
				   !,
				   semplificazioneCerta([ swff(t,im(X,Y)), swff(t,im(Y,X)) ],
							[ swff(t,im(X,Y)), swff(t,im(Y,X)) | S], 
							NEWS, ATOMS).


/*regola T or */
rule(swff(t,or(X,Y)), S, NEWS, safebranch, _, ATOMS):- 	
		      	       		      !,
					      estraiListaTOr(or(X,Y), ListaOr),
					      trattaListaTor(ListaOr, S, NEWS, ATOMS).

/*regola T or */
rule(swff(t,or(X,Y)),S,NEWS,safebranch,_, ATOMS):-	
					  !,
					  messageOnClosedSet([swff(t,or(X,Y)) | S]),
					  semplificazioneBranch([swff(t,Y)], [swff(t,Y)|S], NEWS, ATOMS)
						/*
						, 
						write('Right branch of T or, ')
						*/	
						.
/*regola T im Atom */
rule(swff(t,im(A,Y)),S,NEWS,safebranch,_, ATOMS):- 	
					  atom(A),
					  !,
					  semplificazioneCerta([swff(t,Y)], [swff(t,Y)|S], NEWS, ATOMS).

/*regola T im and*/
rule(swff(t,im(and(A,B),Y)),S,NEWS,safebranch,_, ATOMS):- 
				!,
				semplificazioneBreve( [swff(t,im(A,im(B,Y)))],
						      [swff(t,im(A,im(B,Y)))|S],
						      NEWS, ATOMS).	

/*regola T im equiv*/
rule(swff(t,im(equiv(A,B),Y)), S, NEWS, safebranch,_, ATOMS):-
			       !, 
			       semplificazioneCerta(   [swff(t,im(im(A,B),im(im(B,A), Y)))],
						       [swff(t,im(im(A,B),im(im(B,A), Y)))|S], NEWS, ATOMS).

/*regola T im or*/
rule(swff(t,im(or(A,B),Y)),S,NEWS,safebranch,_, ATOMS):-
				!,
				semplificazioneBreve([swff(t,im(A,Y)), swff(t,im(B,Y))],
						     [swff(t,im(A,Y)), swff(t,im(B,Y)) | S], NEWS, ATOMS).

/*regola T im im*/
rule(swff(t,im(im(_,_),C)),S,NEWS,safebranch,_, ATOMS):- 	
						semplificazione([swff(t,C)],[swff(t,C)|S], NEWS, ATOMS),
						write('Right branch of T->->, ').	

/*regola T im im*/
rule(swff(t,im(im(A,B),C)),S,NEWS, WhichBranch, IdxNewAtom, ATOMS):- 	
		!,
		messageOnClosedSet([swff(t,im(im(A,B),C))|S]),
		write('Left branch of T->->, '),
		partecerta(S,SCERTO),
	       	assegnaTipoBranch(S, WhichBranch),
		!,
		(
		atom(B),
		!,
		semplificazione([swff(t,A), swff(f,B), swff(t,im(B, C))],
						     [swff(t,A), swff(f,B), swff(t,im(B, C)) | SCERTO], 
						     NEWS, ATOMS)
		;
		
		atom_concat(newAt,IdxNewAtom,NewAtom),
		semplificazione([swff(t,A)], 
				[ swff(t,A),swff(f,NewAtom),swff(t,im(B,NewAtom)),swff(t,im(NewAtom,C)) 
				  | SCERTO], NEWS, ATOMS)
		).



/*regola T im non*/
rule(swff(t,im(non(_),C)),S,NEWS,safebranch,_, ATOMS):-	
					       semplificazione([swff(t,C)], [swff(t,C)|S], NEWS, ATOMS),
					       write('Right branch of T->not, ').	


/*regola T im non*/
rule(swff(t,im(non(A),B)),S,NEWS, WhichBranch, _, ATOMS):- 	
				 !,
				 messageOnClosedSet([swff(t,im(non(A),B))|S]),
				 write('Left branch of T->not, '),
				 partecerta(S,SCERTO),
				 assegnaTipoBranch(S, WhichBranch),
				 !,
			         semplificazione([swff(t,A)],[swff(t,A)|SCERTO], NEWS, ATOMS).

/*regola T non */
rule(swff(t,non(X)),S,NEWS,safebranch,_, ATOMS):-	
					 !,
					 semplificazioneBreve([swff(fc,X)], [swff(fc,X)|S], NEWS, ATOMS).


/* F or*/
rule(swff(f,or(X,Y)), S, NEWS, safebranch,_, ATOMS):- 	
		      	       !,
			       estraiListaFOr(or(X,Y), ListaOr),
       			       union(ListaOr, S, S1),
			       semplificazioneBreve(ListaOr, S1, NEWS, ATOMS).

rule(swff(f,and(X,_)),S,NEWS,safebranch,_, ATOMS):-  	
					   write('Left branch of F and, '),
					   semplificazioneBranch([swff(f,X)],[swff(f,X)|S],NEWS, ATOMS).

rule(swff(f,and(X,Y)),S,NEWS,safebranch,_, ATOMS):-	
					   !,
					   messageOnClosedSet([swff(f,and(X,Y))|S]),
					   write('Rigth branch of F and, '),
					   semplificazioneBranch([swff(f,Y)],[swff(f,Y)|S],NEWS, ATOMS). 

rule(swff(f,equiv(X,Y)),S,NEWS, safebranch, _, ATOMS):-  	
				write('Left branch of F equiv, '),
				semplificazioneBranch([swff(f,im(X,Y))],[swff(f,im(X,Y))|S],NEWS, ATOMS).

rule(swff(f,equiv(X,Y)),S,NEWS, safebranch, _, ATOMS):-  	
			        !,		
				messageOnClosedSet([swff(f,equiv(X,Y))|S]),
				write('Right branch of F equiv, '),
				semplificazioneBranch([swff(f,im(Y,X))],[swff(f,im(Y,X))|S],NEWS, ATOMS).

/* F im */
rule(swff(f,im(X,Y)),S,NEWS, WhichBranch, _, ATOMS):- 	
			     !,
			     write('F->, '),
			     partecerta(S,SCERTO),
			     assegnaTipoBranch(S, WhichBranch),
			     !,
			     semplificazione([swff(t,X),swff(f,Y)],[swff(t,X),swff(f,Y)|SCERTO], NEWS, ATOMS).

/* Fperm im: implementa le regole permanence per F-> */
rule(swff(fperm,list(im(XL, XR), ConstantAtoms)), S, NEWS, safebranch,_, Atoms):- 	
			    !,
			    writeln(''),
			    write('Permanence rule applied to the F-> swff: '),
			    printSWFF(swff(f,im(XL,XR))),
			    mainConsequent(ConstantAtoms, [swff(f,im(XL,XR))], SetWithTheNewFimplica, Atoms),
			    union(SetWithTheNewFimplica, S, NEWS).
					
/* F non */
rule(swff(f,non(X)),S,NEWS, WhichBranch, _, ATOMS):-	
			    !,
			    write('F non, '),
			    partecerta(S,SCERTO),
			    assegnaTipoBranch(S, WhichBranch),
			    !,
			    semplificazione([swff(t,X)],[swff(t,X)|SCERTO],NEWS, ATOMS).

/* Fperm non: implementa le regole permanence per F-non */
rule(swff(fperm,list(non(X), ConstantAtoms)), S, NEWS, safebranch, _, Atoms):-	
			     !,
			     write('Permanence rule applied to the F~ swff: '),
			     printSWFF(swff(f,non(X))),
			     mainConsequent(ConstantAtoms, [swff(f,non(X))], SetWithTheNewFimplica, Atoms),
			     union(SetWithTheNewFimplica, S, NEWS). 

/* Fc or*/
rule(swff(fc,or(X,Y)),S, NEWS, safebranch, _, ATOMS):-	
		         !,
			 semplificazioneBreve([swff(fc,X),swff(fc,Y)],[swff(fc,X),swff(fc,Y)|S],NEWS, ATOMS).


/* Fc and */ 
rule(swff(fc,and(X,_)),S, NEWS, WhichBranch, _, ATOMS):- 	
			  partecerta(S,SCERTO),
			  assegnaTipoBranch(S, WhichBranch),
			  semplificazioneCerta([swff(fc,X)],[swff(fc,X)|SCERTO], NEWS, ATOMS). 		

/* Fc and */
rule(swff(fc,and(X,Y)),S, NEWS, WhichBranch, _, ATOMS):- 	
			  !,
			  messageOnClosedSet([swff(fc,and(X,Y))|S]),
			  partecerta(S,SCERTO),
			  assegnaTipoBranch(S, WhichBranch),
			  semplificazioneCerta([swff(fc,Y)],[swff(fc,Y)|SCERTO],NEWS, ATOMS).

/* Fc equiv */ 
rule(swff(fc, equiv(X,Y)),S, NEWS,WhichBranch,_, ATOMS):- 	
	      		     partecerta(S,SCERTO),
			     assegnaTipoBranch(S, WhichBranch),
			     semplificazioneCerta( [swff(fc,im(X,Y))],
						   [swff(fc,im(X,Y)) | SCERTO], NEWS, ATOMS). 

/* Fc equiv */
rule(swff(fc, equiv(X,Y)), S, NEWS, WhichBranch, _, ATOMS):- 	
	      		   !,
			   messageOnClosedSet([swff(fc, equiv(X,Y))|S]),
			   partecerta(S,SCERTO),
			   assegnaTipoBranch(S, WhichBranch),
			   semplificazioneCerta([swff(fc,im(Y,X))],[swff(fc,im(Y,X))|SCERTO], NEWS, ATOMS).


/* Fc im */
rule(swff(fc,im(X,Y)), S, NEWS, WhichBranch, _, ATOMS):-	
		       !,
		       partecerta(S,SCERTO),
		       assegnaTipoBranch(S, WhichBranch),
		       !,
		       semplificazioneBreve([swff(t,X),swff(fc,Y)],[swff(t,X),swff(fc,Y)|SCERTO],NEWS, ATOMS). 

/* Fc non */
rule(swff(fc,non(X)), S, NEWS, WhichBranch, _, ATOMS):- 	
		      !,
		      write('Fc non, '),
		      partecerta(S,SCERTO),
		      assegnaTipoBranch(S, WhichBranch),
		      !,
		      semplificazioneBreve([swff(t,X)],[swff(t,X)|SCERTO],NEWS, ATOMS).




/*

	partecerta: produce Sc dato S. Non vengono copiati T e Fc atomiche

*/



partecerta([],[]).	/* passo base */

partecerta([swff(t,X)|T], RESTO):-	     atom(X),
			  	   	     !,
			  	   	     partecerta(T,RESTO).

partecerta([swff(t,X)|T],[swff(t,X)|RESTO]):- 
					      partecerta(T,RESTO),
					      !.

partecerta([swff(fc,X)|T], RESTO):- 	      atom(X),
			   		      !,
			   		      partecerta(T,RESTO),
					      !.

partecerta([swff(fc,X)|T],[swff(fc,X)|RESTO]):- partecerta(T,RESTO),!.

partecerta([swff(f,_)|T],RESTO):- partecerta(T,RESTO),!.




/*
PREDICATI DI SUPPORTO
*/

haZeroFFormule([]). 			/* Un insieme vuoto ha zero F-swff */
haZeroFFormule([swff(t,_)|L]):-		haZeroFFormule(L).
haZeroFFormule([swff(fc,_)|L]):-	haZeroFFormule(L).



appartenenza(X,L,1):-	memberchk(X,L),!.
appartenenza(X,L,0):-   not(memberchk(X,L)). 


wff(X):- wffIsCorrect(X),printWFF(X).

wffIsCorrect(X):-atom(X).
wffIsCorrect(and(X,Y)):- wffIsCorrect(X), wffIsCorrect(Y).
wffIsCorrect(equiv(X,Y)):- wffIsCorrect(X), wffIsCorrect(Y).
wffIsCorrect(or(X,Y)):- wffIsCorrect(X), wffIsCorrect(Y).
wffIsCorrect(im(X,Y)):- wffIsCorrect(X), wffIsCorrect(Y).
wffIsCorrect(non(X)):- wffIsCorrect(X).

				
estraeTSWff([],[]).
estraeTSWff([swff(t,X)|T],[swff(t,X)|RES]):-	estraeTSWff(T,RES),!.
estraeTSWff([swff(f,_)|T],RES):-		estraeTSWff(T,RES),!.
estraeTSWff([swff(fc,_)|T],RES):-		estraeTSWff(T,RES),!. /* caso aggiunto in V13*/
estraeTSWff(_,_):-				writeln('*** CASO NON PREVISTO IN  estraeTSWff ***'),abort.



/*fromSetTotSwff([],_):-	writeln('ERRORE IN fromSetTotSwff'),abort.*/

fromSetTotSwff([],swff(t,1)). /* modificato in V13 */
fromSetTotSwff([swff(t,X)],swff(t,X)).
fromSetTotSwff([swff(fc,X)],swff(t,non(X))).	/* caso aggiunto in V13 */
fromSetTotSwff([swff(t,X)|RES],swff(t,and(X,Y))):-		fromSetTotSwff(RES,swff(t,Y)),!.
fromSetTotSwff([swff(fc,X)|RES],swff(t,and(non(X),Y))):-	fromSetTotSwff(RES,swff(t,Y)),!. /* caso aggiunto in V13*/
fromSetTotSwff(X,_):- write('ERRORE IN fromSetTotSwff('),write(X),write(')'),abort.

				


/*fromSetTofSwff([],_):-	writeln('ERRORE IN fromSetTofSwff'),abort.*/

fromSetTofSwff([],swff(f,0)).
fromSetTofSwff([swff(f,X)],swff(f,X)).
fromSetTofSwff([swff(f,X)|RES],swff(f,or(X,Y))):-	fromSetTofSwff(RES,swff(f,Y)),!.
fromSetTofSwff(X,_):- write('ERRORE IN fromSetTofSwff('),write(X),write(')'),abort.


/*fromSetTofcSwff([],_):-	writeln('ERRORE IN fromSetTofSwff'),abort.*/

fromSetTofcSwff([],swff(fc,0)).
fromSetTofcSwff([swff(fc,X)],swff(fc,X)).
fromSetTofcSwff([swff(fc,X)|RES],swff(fc,or(X,Y))):-	fromSetTofcSwff(RES,swff(fc,Y)),!.
fromSetTofcSwff(X,_):- write('ERRORE IN fromSetTofSwff('),write(X),write(')'),abort.


convertFcIntoTSWff([],[]).
convertFcIntoTSWff([swff(fc,X)|T],[swff(t,non(X))|R]):-	convertFcIntoTSWff(T,R),!.
convertFcIntoTSWff([swff(t,X)|T],[swff(t,X)|R]):-	convertFcIntoTSWff(T,R),!.
convertFcIntoTSWff([swff(f,X)|T],[swff(f,X)|R]):-	convertFcIntoTSWff(T,R),!.
convertFcIntoTSWff(X,_):-	write('ERRORE IN convertFcIntoTSWff('),write(X),write(')'),abort.



/* 
	PERMANENZA DEL SEGNO PER FORMULE CLASSICHE	
 */

/*
				Preso Set ne esegue la semplificazione classica, 
				il risultato è in NewSet.
*/

clSimplification(Set, NewSet, ATOMS):-	buildFalseAtomicSwffs(Set,SetOfFalseAtomicSwffs),
					union(Set,SetOfFalseAtomicSwffs,SimpSet),
					newsimplification(SetOfFalseAtomicSwffs, SimpSet, NewSet, ATOMS).

/*					
					Costruisce le swff atomiche date le variabili con segno costante 
					nella parte classica di Set
*/
buildFalseAtomicSwffs(Set,SetOfFalseAtomicSwffs):-	clVarsOfASet(Set,Posive,Negative),
							subtract(Negative,Posive,TheFalseVars),
							fromFalseVarsToFalseAtomicSwffs(TheFalseVars,SetOfFalseAtomicSwffs).

/*				Dato l'insieme a primo argomento calcola le variabili positive e quelle negative
				che compaiono nella parte classica, mettendole a secondo e terzo argomento
*/
clVarsOfASet([],[],[]).
clVarsOfASet([A|T],PositiveVars,NegativeVars):-	clVarsInSWFF(A,PosVarsInA,NegVarsInA),
						clVarsOfASet(T,PosVarsInT,NegVarsInT),
						union(PosVarsInA,PosVarsInT,PositiveVars),
						union(NegVarsInA,NegVarsInT,NegativeVars).


clVarsInSWFF(swff(t,A), PosVarsInA, NegVarsInA):- clVarsInSWFFTrue(A, PosVarsInA, NegVarsInA),
				    		  !.

clVarsInSWFF(swff(f,A), [], []):- 	atomic(A), 
					!.

clVarsInSWFF(swff(f,A), PosVarsInA, NegVarsInA):- clVarsInSWFFFalse(A, PosVarsInA, NegVarsInA),
				    		  !.

clVarsInSWFF(swff(fc,_), [], []).
/*
					data la swff, mette le variabili classiche positive nell'insieme a 
					primo argomento, quelle negative a secondo.
*/

clVarsInSWFFTrue(1,[],[]).

clVarsInSWFFTrue(0,[],[]).
			

clVarsInSWFFTrue(X, [X], []):-		atom(X).




clVarsInSWFFTrue(and(X,Y),PosVars,NegVars):-	clVarsInSWFFTrue(X,PVarsX,NVarsX),
						clVarsInSWFFTrue(Y,PVarsY,NVarsY),
						union(PVarsX,PVarsY,PosVars),
						union(NVarsX,NVarsY,NegVars).

clVarsInSWFFTrue(equiv(X,Y),PosVars,NegVars):-	clVarsInSWFFTrue(X,PVarsX,NVarsX),
						clVarsInSWFFTrue(Y,PVarsY,NVarsY),
						union(PVarsX,PVarsY,PosVars),
						union(NVarsX,NVarsY,NegVars).

clVarsInSWFFTrue(or(X,Y),PosVars,NegVars):-	clVarsInSWFFTrue(X,PVarsX,NVarsX),
						clVarsInSWFFTrue(Y,PVarsY,NVarsY),
						union(PVarsX,PVarsY,PosVars),
						union(NVarsX,NVarsY,NegVars).

clVarsInSWFFTrue(im(_,Y),PosVars,NegVars):-	clVarsInSWFFTrue(Y,PosVars,NegVars).
clVarsInSWFFTrue(non(_),[],[]).


clVarsInSWFFFalse(1,[],[]).
clVarsInSWFFFalse(swff(f,0),[],[]).
clVarsInSWFFFalse(X,[], [X]):-		atom(X).

clVarsInSWFFFalse(and(X,Y),PosVars,NegVars):-	clVarsInSWFFFalse(X,PVarsX,NVarsX),
						clVarsInSWFFFalse(Y,PVarsY,NVarsY),
						union(PVarsX,PVarsY,PosVars),
						union(NVarsX,NVarsY,NegVars).


clVarsInSWFFFalse(or(X,Y),PosVars,NegVars):-	clVarsInSWFFFalse(X,PVarsX,NVarsX),
						clVarsInSWFFFalse(Y,PVarsY,NVarsY),
						union(PVarsX,PVarsY,PosVars),
						union(NVarsX,NVarsY,NegVars).



clVarsInSWFFFalse(im(_,_),[],[]).
clVarsInSWFFFalse(equiv(_,_),[],[]).
clVarsInSWFFFalse(non(_),[],[]).



fromFalseVarsToFalseAtomicSwffs([],[]).	/* Se non ci sono variabili classiche costanti nulla è costruito */

fromFalseVarsToFalseAtomicSwffs([A|T],[swff(f,A)|SetOfFalseAtomicSwffsInT]):-
				fromFalseVarsToFalseAtomicSwffs(T,SetOfFalseAtomicSwffsInT).


cercaPermanenceFormula(Set, [TheMainPremise], Resto, [Atom|MoreAtoms]):-	
			    partecerta(Set,Sc), /* Sc e' la parte certa di S */
			    length(Sc,SizeSc),
			    SizeSc > 0,
			    subtract(Set,Sc,Sf), /* Sf contiene solo F-formule */
			    length(Sf,SizeSf), /* se c'e' solo una F-formula allora */
			    SizeSf > 1,     /* l'eventuale applicazione di F-> e F-not è invertibile */
			    prendeTipo3(Sf,Tipo3,_), /*_ contiene solo F-atomic formulas*/
			    findMainPremise(Sc,Tipo3,TheMainPremise,[Atom|MoreAtoms]),
			    subtract(Set,[TheMainPremise],Resto).

findMainPremise(Sc, [Swff | _], Swff, TheConstantAtoms):-
		    atomiConSegnoCostanteInSwffSet([Swff | Sc], [Atom | MoreAtoms]),
		    atomiConSegnoCostanteInSwffSet([Swff], [SwffAtom | SwffMoreAtoms]),
		    intersection([Atom | MoreAtoms], [SwffAtom | SwffMoreAtoms], [ HeadAtom | TailAtoms]),
		    list_to_set([ HeadAtom | TailAtoms], TheConstantAtoms),
		    !.	 

findMainPremise(Sc, [_| TailTipo3], Swff,TheConstantAtoms):- 
		    findMainPremise(Sc, TailTipo3, Swff,TheConstantAtoms).



/*
Per ogni atomo in Atoms, rimuove l'eventuale opposto in RightSuccessor. Opposti indesiderati vengono
generati da PermanenzaSegno.
*/

rimuoviAtomiOpposti(Atoms,Model,FilteredModel):-	atomiOpposti(Atoms,AtomiOpposti),
							modelloFiltrato(Model,AtomiOpposti,FilteredModel).
							
modelloFiltrato([],_,[]).

/*
*
*        Versione 2.0
*
*/

modelloFiltrato([swff(_,Wff) | T ],AtomiOpposti,FilteredModel):-	not(atomic(Wff)),
									!,
									modelloFiltrato(T,AtomiOpposti,FilteredModel).

modelloFiltrato([swff(S,Wff) | T ],AtomiOpposti,FilteredModel):-	memberchk(swff(S,Wff),AtomiOpposti),!,
									modelloFiltrato(T,AtomiOpposti,FilteredModel).

modelloFiltrato([swff(S,Wff) | T ],AtomiOpposti,[swff(S,Wff)|FilteredModel]):-	modelloFiltrato(T,AtomiOpposti,FilteredModel).

modelloFiltrato([ [X | Y] | Z], AtomiOpposti, [ FilteredFirst| FilteredTail ] ):-
						!,
						modelloFiltrato([ X | Y ], AtomiOpposti, FilteredFirst),
						!,
						modelloFiltrato(Z, AtomiOpposti, FilteredTail),
						!.

modelloFiltrato([ [] | Z], AtomiOpposti, [ FilteredFirst | FilteredTail ] ):-
						modelloFiltrato([], AtomiOpposti, FilteredFirst),
						modelloFiltrato(Z, AtomiOpposti, FilteredTail).

		
atomiOpposti([],[]).
atomiOpposti([swff(t,X) | TailAtoms],[swff(fc,X) | TailOpposti]):- atomiOpposti(TailAtoms,TailOpposti).
atomiOpposti([swff(fc,X) | TailAtoms],[swff(t,X) | TailOpposti]):- atomiOpposti(TailAtoms,TailOpposti).


mainConsequent([], L, L, []):- !.
mainConsequent(_,[],[],[]):- !.
mainConsequent([SignedAtom | TailOfAtoms], [ TheSwff ], ResTail, Atoms):-
			   substitute(SignedAtom,[SignedAtom,TheSwff], Res, _, ResAtoms),
			   mainConsequent(TailOfAtoms, Res, ResTail,  TailAtoms),
			   union(ResAtoms, TailAtoms, Atoms).



/*equivTable(X,X,1).*/
equivTable(0,0,1).
equivTable(0,1,0).
equivTable(0,X,non(X)).
equivTable(1,0,0).
equivTable(1,1,1).
equivTable(1,X,X).
equivTable(X,0,non(X)).
equivTable(X,1,X).
equivTable(X,Y,equiv(X,Y)).										


filtraNonAtomiche([],[]):- !.

/* Nel modello teniamo le atomiche */
filtraNonAtomiche([ swff(S,Wff) | T ], [swff(S,Wff) | Result ]):- 	atomic(Wff),
									!,
									filtraNonAtomiche(T, Result).
/* Eliminiamo le NON atomiche */
filtraNonAtomiche([ swff(_,_) | T ], Result ):- 			!,
									filtraNonAtomiche(T, Result).
									

/* Se arriviamo qui il primo elemento della lista è una lista e quindi non filtriamo nulla */
filtraNonAtomiche(H, H ).



messageOnClosedSet(SetToPrint). /*:-		writeln('\nBack to the branching point:\n'),
						printSWFFSet(SetToPrint, 1),
						writeln(' ').*/
			

estraiListaTAnd(and(X,Y), ListaAnd):- !,
			  	      estraiListaTAnd(X, ListaX),
			  	      estraiListaTAnd(Y, ListaY),
				      union(ListaX, ListaY, ListaAnd).

estraiListaTAnd(X, [swff(t, X)]).


estraiListaTOr(or(X,Y), ListaAnd):- !,
			  	      estraiListaTOr(X, ListaX),
			  	      estraiListaTOr(Y, ListaY),
				      union(ListaX, ListaY, ListaAnd).

estraiListaTOr(X, [swff(t, X)]).


estraiListaFOr(or(X,Y), ListaOr):- !,
			  	      estraiListaFOr(X, ListaX),
			  	      estraiListaFOr(Y, ListaY),
				      union(ListaX, ListaY, ListaOr).

estraiListaFOr(X, [swff(f, X)]).

estraiListaFAnd(and(X,Y), ListaOr):- !,
			  	      estraiListaFAnd(X, ListaX),
			  	      estraiListaFAnd(Y, ListaY),
				      union(ListaX, ListaY, ListaOr).

estraiListaFAnd(X, [swff(f, X)]).


trattaListaTor([swff(t, X)], S, NEWS, ATOMS):- 	
						semplificazioneBranch([swff(t,X)],[swff(t,X)|S],NEWS, ATOMS)
						/*
						,
						write('Branch of T or, Disjunct: '),
						printWFF(X),
						write(' of ')
						*/.	

trattaListaTor([swff(t,X), swff(t,Y) | ListaOr], S, NEWS, ATOMS):-
					  (
						semplificazioneBranch([swff(t,X)], [swff(t,X)|S], NEWS, ATOMS)
						/*
						,
						write('Branch of T or, Disjunct: '),
						printWFF(X),
						write(' of ')
					       	*/
						
						;
						
					     	messageOnClosedSet([swff(t, X) | S]),
						trattaListaTor([swff(t, Y) | ListaOr], S, NEWS, ATOMS)
					   ).


/*
 * estende le regole di permanence, rimpiazzando variabili con segno costante dentro F->-formule che sono
 * sottoformule di T-formule. Nota che questo significa che le F->-formule sono sottoformule di
 * T->-formule ed in particolare sono nella parte dell'antecedente.
 */


tPermanenceReplacement(S, SimpAtoms, NewS, Atoms):-
/*
 *  Esplora Sc e costruisce la lista delle varprop che occorrono
 *  positivamente e quelle che occorrono negativamente;
 */
			   
			  partecerta(S, Sc),
			  segnoAtomiInSetOfSwff(Sc, ScVarPos, ScVarNeg),
			  !,
			  list_to_set(ScVarPos, SetOfVarPos),
			  list_to_set(ScVarNeg, SetOfVarNeg),
				
/*
 * Di ogni F-formula in S individua le T-sottoformule e le esplora come sopra. 
 * Nota che se SetOfVarPos = SetOfVarNeg allora sappiamo che non possiamo fare alcun rimpiazzamento 
 * nelle F-> che sono in Sc, gli unici potenziali rimpiazzamenti sono quelli in F-> che sono
 * subformule di formule T-fomule le quali a loro volta sono sottoformule di formule in Sf.
 */
			   
			  subtract(S, Sc, Sf),
			  theTsubformulasOfASet(Sf, ListOfTWffs),
			  /*
			  writeln('Le T-sottoformule delle F-formule'),
			  writeln(ListOfTWffs),
			  */
			  segnoAtomiInSetOfSwff(ListOfTWffs, TempSubTWffsVarPos, TempSubTWffsVarNeg),
			  list_to_set(TempSubTWffsVarPos, SubTWffsVarPos),
			  list_to_set(TempSubTWffsVarNeg, SubTWffsVarNeg),

			  union(SetOfVarPos, SubTWffsVarPos, VarPos),
			  union(SetOfVarNeg, SubTWffsVarNeg, VarNeg),
			  subtract(VarPos, VarNeg, VarPosConstant),
			  subtract(VarNeg, VarPos, VarNegConstant),
			  
/*
 * se ci sono varprop con segno costante, queste possono essere rimpiazzate con la costante logica opportuna
 * all'interno delle F-> formule che siano sottoformula di una T-(sotto)formula di S.
 * Il rimpiazzamento nelle F-> che sono sottoformule di Sc non richiede nulla di particolare.
 * Il rimpiazzamento nelle F-> che sono sottoformule di formule in Sf richiede che la F-> sia sottoformula 
 * di una T-formula. Se la F A->B non e' sottoformula di una T-formula, ricadiamo nel caso
 * delle permanence rules di ToCL e quindi occorre analizzare B per stabilire il segno delle sue varprop 
 * e poi eventualmente si può procedere.
 * Qui NewSc e' l'insieme che non contiene formule atomiche, e in Atoms ci sono formule atomiche
 * segnate T o Fc e non occorrono come sottoformule    
 */
			   
			   rimpiazzaNelleFimplicaDiSc(Sc, VarPosConstant, VarNegConstant, NewSc, MoreAtoms),
/*
 * NewSc contiene le formule di Sc che non si sono trasformate in atomiche, MoreAtoms le formule di Sc
 * che per effetto del rimpiazzamento si sono trasformate in atomiche. Nota che potrebbero comparire 
 * come sottoformule delle formule in NewSc, quindi bisona applicare almeno simplification.
 * Le atomiche ottenute vanno ad aggiungersi a quelle che gia' si avevano, cioè quelle in SimpAtoms.
 */
			   union(NewSc, MoreAtoms, ScTarget),
			   union(ScTarget, Sf, Target),
			   newsimplification(MoreAtoms, Target, NewS, NewMoreAtoms),
			   union(SimpAtoms, NewMoreAtoms, Atoms).
/*
 * Nota che per avere il contromodello costruito giusto dovrebbe essere sufficiente inserire 
 * in NewSc Fc non(p) se p positivo e Fc p se p negativo. Inoltre, se ad S sono state applicate le permanence 
 * rules allora nell'esplorazione non dovrebbe mai accadere di trovare varprop con segno costante negativo
 */

/*
 *	Determina le T-sottoformule del primo argomento che si suppone contenere solo F-formule
 */

theTsubformulasOfASet([], []).

theTsubformulasOfASet([swff(_, Wff) | Tail], ListOfTSwffs):- 
			       	      	     theTsubformulasOfAFwff(Wff, TheTSubfOfWff),
			       		     theTsubformulasOfASet(Tail, TheTSubfOfTail),
					     union(TheTSubfOfWff, TheTSubfOfTail, ListOfTSwffs).

/*
 * il primo argomento e' una F-formula 
 *
 */

theTsubformulasOfAFwff(X, []):- atom(X),
			  	!.

theTsubformulasOfAFwff(and(X,Y), List):- 
				     !,
				     theTsubformulasOfAFwff(X, ListX),
				     theTsubformulasOfAFwff(Y, ListY),
				     union(ListX, ListY, List).

theTsubformulasOfAFwff(or(X,Y), List):- 
				     !,
				     theTsubformulasOfAFwff(X, ListX),
				     theTsubformulasOfAFwff(Y, ListY),
				     union(ListX, ListY, List).

theTsubformulasOfAFwff(im(X,Y), [ swff(t, X) | ListY]):- 
				      	       !,
				     	       theTsubformulasOfAFwff(Y, ListY).

theTsubformulasOfAFwff(equiv(X,Y), List):- 
				     !,
				     theTsubformulasOfAFwff(im(X,Y), ListX),
				     theTsubformulasOfAFwff(im(Y,X), ListY),
				     union(ListX, ListY, List).

theTsubformulasOfAFwff(non(X), [swff(t, X)]).


/*
 * Di ogni formula in Sc viene fatto il rimpiazzamento nelle sue sottoformule di tipo F->.
 * Nota che le Fc X vengono trattate come T non(X). 
 * Separiamo espressamente il trattamento dei due segni per ripristinare
 * il segno Fc quando il risultanto del rimpiazzamento non sia zero oppure uno,
 * nel qual caso lasciamo il segno T.
 *
 * Atoms contiene atomi segnati T o Fc. Essi sono stati ottenuti da formule in Sc le quali per
 * rimpiazzamento sono diventate atomiche.
 * 
 * se Xtemp e' formula atomica allora siamo davanti ad una costante che per 
 * Se non ci sono varprop con segno costante non c'e' nulla da fare.
 * Se non ci sono formule da esplorare non c'e' nulla da fare.
 */

rimpiazzaNelleFimplicaDiSc(Sc, [], [], Sc, []):- !.
rimpiazzaNelleFimplicaDiSc([], _, _, [], []):- !.
 

rimpiazzaNelleFimplicaDiSc(  [ swff(Sign, X) | Tail], VarPosConstant, VarNegConstant, WffRepl, Atoms):-
			 (
		          Sign = t,
		          !,
		          rimpiazzaNelleFimplicaDiTWff(X, VarPosConstant, VarNegConstant, Xtemp),
		          rimpiazzaNelleFimplicaDiSc(Tail, VarPosConstant, VarNegConstant, TailRepl, TailAtoms),
		          valTerm(Xtemp, Xrepl),
			  (
			     Xrepl = 1,
			     !,
			     Atoms = TailAtoms,
			     WffRepl = TailRepl
			     
			     ;
			     
			     Xrepl = 0, /* abbiamo swff(t, 0) */
			     !,
			     fail
			     
			     ;
			     
			     atom(Xrepl),
			     !,
			     Atoms = [ swff(t, Xrepl) | TailAtoms ],
			     WffRepl = TailRepl
			     
			     ;
			  
			     Atoms = TailAtoms,
			     WffRepl = [ swff(t, Xrepl) | TailRepl ]
			  )
			  
			  ;
			  
			  /* Caso Sign = Fc */
			  rimpiazzaNelleFimplicaDiTWff(non(X), VarPosConstant, VarNegConstant, Xtemp),
			  rimpiazzaNelleFimplicaDiSc(Tail, VarPosConstant, VarNegConstant, TailRepl, TailAtoms),
		          
			  /* nota che l'outmost connective di Xtemp e' non, ma l'outmost
                           * connective di Xrepl potrebbe non esserlo per effetto della valutazione.
 			   * Questo significa che Xrepl e' una costante logica
			   */
			      
			  valTerm(Xtemp, Xrepl),
			  (
			  /* 
			   * se Xrepl inizia con non allora nota che necessariamente Wff non e' zero o uno
                           * ed inoltre possiamo scrivere la formula come Fc Wff
			   */
			     Xrepl = non(Wff),
			     !,
			     (
			     /* Decidiamo se Wff e' o meno atomica */
			     atom(Wff),
			     !,
			     Atoms = [ swff(fc, Wff) | TailAtoms ],
			     WffRepl = TailRepl
			     ;
			     Atoms = TailAtoms ,
			     WffRepl = [ swff(fc, Wff) | TailRepl]
			     )
			     ;
			     /*
			      * Xrepl e' una costante logica 
                              */
			     Xrepl = 1, /* abbiamo swff(t,1) quindi swff(fc,0) */
			     !,
			     Atoms = TailAtoms,
			     WffRepl =  TailRepl 
			     ;
			     fail /* abbiamo swff(t,0) quindi swff(fc 1) */
			   )
			   ).
			  



rimpiazzaNelleFimplicaDiTWff(X, _, _, X):- 
				      	   atom(X),
				      	   !.

rimpiazzaNelleFimplicaDiTWff(and(X,Y), VarPosConstant, VarNegConstant, and(Xrepl, Yrepl)):-
				       !,
				       rimpiazzaNelleFimplicaDiTWff(X, VarPosConstant, VarNegConstant, Xrepl),
				       rimpiazzaNelleFimplicaDiTWff(Y, VarPosConstant, VarNegConstant, Yrepl).


rimpiazzaNelleFimplicaDiTWff(or(X,Y), VarPosConstant, VarNegConstant, or(Xrepl, Yrepl)):-
				       !,
				       rimpiazzaNelleFimplicaDiTWff(X, VarPosConstant, VarNegConstant, Xrepl),
				       rimpiazzaNelleFimplicaDiTWff(Y, VarPosConstant, VarNegConstant, Yrepl).

rimpiazzaNelleFimplicaDiTWff(im(X,Y), VarPosConstant, VarNegConstant, im(Xrepl, Yrepl)):-
				       !,
				       rimpiazzaNelleFimplicaDiFWff(X, VarPosConstant, VarNegConstant, Xrepl),
				       rimpiazzaNelleFimplicaDiTWff(Y, VarPosConstant, VarNegConstant, Yrepl).

/* 
 *  Non c'e' di sicuro nulla da rimpiazzare dato che le variabili che occorrono in una equiv hanno
 *  segno sia positivo che negativo quindi le varprop nelle equiv-formule non sono tra quelle
 *  con segno costante e quindi inutile tentare di rimpiazzarle
 */

rimpiazzaNelleFimplicaDiTWff(  equiv(X,Y), VarPosConstant, VarNegConstant, equiv(X, Y)).
			      

rimpiazzaNelleFimplicaDiTWff(non(X), VarPosConstant, VarNegConstant, non(Xrepl)):-
				       !,
				       rimpiazzaNelleFimplicaDiFWff(X, VarPosConstant, VarNegConstant, Xrepl).


/*
 * Il primo argomento e' una Wff che si intende segnata F
 * Se non si e' trovato l'implica allora non si puo' fare alcun rimpiazzamento
 */

rimpiazzaNelleFimplicaDiFWff(X, _, _, X):- 
						atom(X),
						!.	       

rimpiazzaNelleFimplicaDiFWff(and(X,Y), VarPosConstant, VarNegConstant, and(ReplX, ReplY)):-
				       !,
				       rimpiazzaNelleFimplicaDiFWff(X, VarPosConstant, VarNegConstant, ReplX),
				       rimpiazzaNelleFimplicaDiFWff(Y, VarPosConstant, VarNegConstant, ReplY).


rimpiazzaNelleFimplicaDiFWff(or(X,Y), VarPosConstant, VarNegConstant, or(ReplX, ReplY)):-
				      !,
				      rimpiazzaNelleFimplicaDiFWff(X, VarPosConstant, VarNegConstant, ReplX),
				      rimpiazzaNelleFimplicaDiFWff(Y, VarPosConstant, VarNegConstant, ReplY).

rimpiazzaNelleFimplicaDiFWff(im(X,Y), VarPosConstant, VarNegConstant, Result):-
				      !,
				      goToReplaceFalse(im(X,Y), VarPosConstant, VarNegConstant, Result).

/*
 * vedi commento fatto poco sopra
 */

rimpiazzaNelleFimplicaDiFWff( equiv(X,Y), VarPosConstant, VarNegConstant, equiv(X, Y)).
			 


rimpiazzaNelleFimplicaDiFWff(non(X), VarPosConstant, VarNegConstant, Result):-
				     !,
				     goToReplaceFalse(non(X), VarPosConstant, VarNegConstant, Result).



goToReplaceFalse(X, _, VarNegConstant, Result):-
	       atom(X),
	       !,
	       (
	       memberchk(X, VarNegConstant),
	       !,
	       Result = 0
	       
	       ;

	       Result = X
	       ).

goToReplaceFalse(and(X,Y), VarPosConstant, VarNegConstant, and(ResX, ResY)):-
		      !,
		      goToReplaceFalse(X, VarPosConstant, VarNegConstant, ResX),
		      goToReplaceFalse(Y, VarPosConstant, VarNegConstant, ResY).

/*
 * vedi commendo fatto sopra
 *
 */

goToReplaceFalse(equiv(X,Y), VarPosConstant, VarNegConstant, equiv(X, Y)).


goToReplaceFalse(or(X,Y), VarPosConstant, VarNegConstant, or(ResX, ResY)):-
		      !,
		      goToReplaceFalse(X, VarPosConstant, VarNegConstant, ResX),
		      goToReplaceFalse(Y, VarPosConstant, VarNegConstant, ResY).


goToReplaceFalse(im(X,Y), VarPosConstant, VarNegConstant, im(ResX, ResY)):-
		      !,
		      goToReplaceTrue(X, VarPosConstant, VarNegConstant, ResX),
		      goToReplaceFalse(Y, VarPosConstant, VarNegConstant, ResY).

goToReplaceFalse(non(X), VarPosConstant, VarNegConstant, non(ResX)):-
		      goToReplaceTrue(X, VarPosConstant, VarNegConstant, ResX).



goToReplaceTrue(X, VarPosConstant, _, Result):-
	       atom(X),
	       !,
	       (
	       memberchk(X, VarPosConstant),
	       !,
	       Result = 1
	       
	       ;

	       Result = X
	       ).

goToReplaceTrue(and(X,Y), VarPosConstant, VarNegConstant, and(ResX, ResY)):-
		      !,
		      goToReplaceTrue(X, VarPosConstant, VarNegConstant, ResX),
		      goToReplaceTrue(Y, VarPosConstant, VarNegConstant, ResY).

/*
 * vedi commendo fatto sopra
 */

goToReplaceTrue(equiv(X,Y), VarPosConstant, VarNegConstant, equiv(X, Y)).


goToReplaceTrue(or(X,Y), VarPosConstant, VarNegConstant, or(ResX, ResY)):-
		      !,
		      goToReplaceTrue(X, VarPosConstant, VarNegConstant, ResX),
		      goToReplaceTrue(Y, VarPosConstant, VarNegConstant, ResY).


goToReplaceTrue(im(X,Y), VarPosConstant, VarNegConstant, im(ResX, ResY)):-
		      !,
		      goToReplaceFalse(X, VarPosConstant, VarNegConstant, ResX),
		      goToReplaceTrue(Y, VarPosConstant, VarNegConstant, ResY).

goToReplaceTrue(non(X), VarPosConstant, VarNegConstant, non(ResX)):-
		      goToReplaceFalse(X, VarPosConstant, VarNegConstant, ResX).



launchvalTermNew( swff(Sign,X), AtomiPos, AtomiNeg, swff(Sign,Res)):- 
		  valTermNew(X, AtomiPos, AtomiNeg, Res).
       
/*
 * 
 * valTermNew(Wff, AtomiPos, AtomiNeg, NewWff)
 * 
 * dove Wff, AtomiPos, AtomiNeg e' l'input, NewWff e' l'output
 *
 * 1- si esplora la formula ricorsivamente:
 * 2- se la formula e'  varprop allora se essa appartiene alla lista delle variabili costanti
 *    allora la si rimpiazza con la costante logica e la formula ritornata e' la costante 
 *    logica
 * 3- se ha connettivo si valuta la parte sx e si ottiene sx1.
 * 4- in base al connettivo si decide se fare la chiamata ricorsiva o meno
 */



/*
 * passo base: il valore di un termine atomico è se stesso 
 */


valTermNew(X, AtomiPos, AtomiNeg, Res):- 
	      	    	 atomic(X),
			 !,
			 (
			 memberchk(X, AtomiPos),
			 !,
			 Res = 1
			 ;
			 memberchk(X, AtomiNeg),
			 !,
			 Res = 0
			 ;
			 Res = X
			 ).

/*passo induttivo: valore di un termine and */
valTermNew(and(X,Y), AtomiPos, AtomiNeg, RISP):-	
		     	       valTermNew(X, AtomiPos, AtomiNeg, VALX),
			       !,
                               newandTable(VALX,Y, AtomiPos, AtomiNeg, RISP),
			       !.

valTermNew(equiv(X,Y), AtomiPos, AtomiNeg, RISP):-	
		       		 valTermNew(X, AtomiPos, AtomiNeg, VALX),
				 valTermNew(Y, AtomiPos, AtomiNeg, VALY),
                        	 equivTable(VALX, VALY, RISP), /*guarda la tabella di verita' dell'EQUIV*/
		                 !.

valTermNew(or(X,Y), AtomiPos, AtomiNeg, RISP):- 	
		    	      valTermNew(X, AtomiPos, AtomiNeg, VALX),
			      !,
                              neworTable(VALX, Y, AtomiPos, AtomiNeg, RISP),
			      !.

valTermNew(im(X,Y), AtomiPos, AtomiNeg, RISP):-
		    valTermNew(X, AtomiPos, AtomiNeg, VALX),
		    !,
		    newimTable(VALX, Y, AtomiPos, AtomiNeg, RISP),
		    !.

valTermNew(non(X), AtomiPos, AtomiNeg, RISP):-
		   valTermNew(X, AtomiPos, AtomiNeg, VALX), 
		   !,
		   nonTable(VALX,RISP).

newandTable(0, _, _, _, 0). /*se il congiunto di sx vale 0 allora la risposta vale 0 */

newandTable(1, Y, AtomiPos, AtomiNeg, RISP):- 
		     	    valTermNew(Y, AtomiPos, AtomiNeg, RISP),
		     	    !. 

newandTable(VALX, Y, AtomiPos, AtomiNeg, RISP):-
		     	       valTermNew(Y, AtomiPos, AtomiNeg, VALY),
			       !, 
	        	       andTable2(VALX, VALY, RISP).  

/*
 * Tabella per l'or
 */

neworTable(1, _, _, _, 1). 
neworTable(0, Y, AtomiPos, AtomiNeg, RISP):-
	      	 	   valTermNew(Y, AtomiPos, AtomiNeg, RISP). 

neworTable(VALX, Y, AtomiPos, AtomiNeg, RISP):-
		    	      valTermNew(Y, AtomiPos, AtomiNeg, VALY), 
		 	      !,
	         	      orTable2(VALX, VALY, RISP).  
/*
 * Semplificazioni per l'implica
 */

/*
 * se l'antecedente vale 0 allora l'implicazione e' una tautologia, quindi la risposta vale 1 
 */

newimTable(0, _, _, _, 1). 

/* 
 * se l'antecedente vale 1 allora la risposta vale il valore del conseguente
 */

newimTable(1, Y, AtomiPos, AtomiNeg, RISP):-	
	      	 	   valTermNew(Y, AtomiPos, AtomiNeg, RISP),
			   !. 

/*se l'antecedente è un termine qualsiasi, allora si valuta il conseguente */ 
newimTable(VALX, Y, AtomiPos, AtomiNeg, RISP):-
	      	 valTermNew(Y, AtomiPos, AtomiNeg, VALY),
		 !, 
		 imTable2(VALX, VALY, RISP).  

/*
 * In NewSet ci sono solo formule non atomiche e Atoms contiene solo atomi che non occorrono
 * neppure come sottoformula in NewSet
 */

newpermanenzaSegno(Set, NewSet, Atoms):-
                   	segnoAtomiInSetOfSwff(Set, TempSetOfVarPos, TempSetOfVarNeg),
		   	!,
			list_to_set(TempSetOfVarPos, SetOfVarPos),
			list_to_set(TempSetOfVarNeg, SetOfVarNeg),
                        /*
			* calcola l'insieme delle varprop costanti +
                        * calcola l'insieme delle varprop costanti -
                        * se almeno uno dei due non e' vuoto
                        * allora procede 
			*/
			subtract(SetOfVarPos, SetOfVarNeg, PositiveAtoms),
			subtract(SetOfVarNeg, SetOfVarPos, NegativeAtoms),
			(
			   NegativeAtoms = PositiveAtoms,
			   !,
			   NewSet = Set,
			   Atoms = []
			
			   ;
			   /*
			    * l'insieme complessivo e' NewSet + Atoms,
			    *  NewSet non contiene formule atomiche e 
			    * Atoms non compaiono neppure come sottoformule in NewSet
			    */
			   
			   launchatomSimplification(Set, PositiveAtoms, NegativeAtoms, NewSet, TempAtoms),
			   createSwffsFromWffs(PositiveAtoms, t, PositiveFormulas),
			   createSwffsFromWffs(NegativeAtoms, fc,NegativeFormulas),
			   union(TempAtoms, PositiveFormulas, Temp2Atoms),
			   union(Temp2Atoms, NegativeFormulas, Atoms)
			
			).

launchatomSimplification(Set, PositiveAtoms, NegativeAtoms, NewSet, Atoms):-
			atomSimplification(Set, PositiveAtoms, NegativeAtoms, TempSet, TempAtoms),
			newsimplification(TempAtoms, TempSet, NewSet, Atoms). 

atomSimplification([], _, _, [], []):- !.
atomSimplification([ H | T ], PositiveAtoms, NegativeAtoms, NewSet, Atoms):-
		       	      
			      launchvalTermNew(H, PositiveAtoms, NegativeAtoms, Hsimpl),
			      Hsimpl = swff(Sign, X),
			      (
			      Sign = t,
			      X = 0,
			      !,
			      fail
			      ;
			      Sign = f,
			      X = 1,
			      !,
			      fail
			      ;
			      Sign = fc,
			      X = 1,
			      !,
			      fail
			      ;
			      atomSimplification(T, PositiveAtoms, NegativeAtoms, SimpT, AtomsT)
			      ),
			      /*atomSimplification(T, PositiveAtoms, NegativeAtoms, SimpT, AtomsT),*/
			      (
			      /*
 			       * se e' X ha connettivi 
			       */
				not(atomic(X)),
				!,
				Atoms =  AtomsT,
				NewSet = [ Hsimpl | SimpT ]
			      ;
			        X = 1, 
				Sign = t,
				!,
				Atoms = AtomsT,
				NewSet = SimpT
			      ;
			       X = 0,
			       memberchk(Sign, [f, fc]),
			       !,
			       Atoms = AtomsT,
			       NewSet = SimpT
			       ;
			       fail    
			      ).


newsimplification(ListaCandidati, Set, NonAtomicSwffs, AtomicSwffs):-
				  newsubstitute(ListaCandidati, Set, TempNonAtomicSwffs, TempAtomicSwffs),
                                  subtract(TempNonAtomicSwffs, Set, Diff1),
				  subtract(TempAtomicSwffs, Set, Diff2),
				  union(Diff1, Diff2, NewCandidates),
				  (
				  NewCandidates = [],
				  !,
				  NonAtomicSwffs = TempNonAtomicSwffs,
				  AtomicSwffs = TempAtomicSwffs
				  ;
				  union(TempNonAtomicSwffs, TempAtomicSwffs, NewList),
				  list_to_set(NewList, NewSet),
				  newsimplification(NewCandidates, NewSet, NonAtomicSwffs, AtomicSwffs)
				  ). 
				  

/*	
 *	newsubstitute(ListaCandidati, InsiemeDiSwff, NonAtomiche, Atomiche):
 *
 *	ListaCandidati e' l'insieme delle formule per cui si deve tentare il rimpiazzamento in
 *	InsiemediSwff. 
 *	Tipicamente la ListaCandidati e' la lista delle nuove formule generate in InsiemeDiSwff per
 *	applicazione di una regola. 
 *      Non bisogna sostituire una formula segnata con se stessa, altrimenti sparisce dall'insieme.
 *      Al termine di newsubstitute in NonAtomiche e Atomiche c'è il risultato del rimpiazzamento.
 *	Le formule di ListaCandidati non comapiono come sottoformule ne' in NonAtomiche ne' in Atomiche.       
*/

newsubstitute(_, [], [], []):- !.

newsubstitute(TheCandidates, [swff(Sign, Wff) | SwffSet], NewSet, Atoms):-
				 
/*
 *      se la formula segnata Sign Wff compare come candidato  si toglie dai candidati
 *      la formula. Se non facciamo cosi' rimpiazziamo tutte le formule candidate con se stesse
 *      e le perdiamo  
 */
                                  (
				  memberchk(swff(Sign, Wff), TheCandidates),
				  !,
				  subtract(TheCandidates, [swff(Sign, Wff)], TheUpCandidates)
				  ;
				  TheUpCandidates = TheCandidates
				  ), 
				  (
				  Sign = t,
				  !,
				  simplyfyWff(TheUpCandidates, Wff, WffResult)
				  ;
				  Sign = f,
				  !,
				  simplyfyWff(TheUpCandidates, Wff, WffResult)
				  ;
				  Sign = fc,
				  !,
				  weakSimplyfyWff(TheUpCandidates, Wff, WffResult)
				 ),

				 (
				  Sign = t,
				  WffResult = 0,
				  !,
				  fail
				  ;
				  Sign = f,
				  WffResult = 1,
				  !,
				  fail
				  ;
				  Sign = fc,
				  WffResult = 1,
				  !,
				  fail
				  ;
				  newsubstitute(TheCandidates, SwffSet, TempNewSet, TempNewAtoms)
				  ),
				 
				 (
				 WffResult = 1,
				 Sign = t,
				 !,
				 NewSet = TempNewSet,
				 Atoms =  TempNewAtoms
				 ;
				 WffResult = 0,
				 memberchk(Sign,[f,fc]),
				 !,
				 NewSet = TempNewSet,
				 Atoms =  TempNewAtoms
				 ;
				 atomic(WffResult),
				 memberchk(Sign,[t,fc]),
				 !, 	  
				 NewSet = TempNewSet,
				 Atoms = [ swff(Sign, WffResult) | TempNewAtoms]
				 ;
				 NewSet = [ swff(Sign, WffResult) | TempNewSet],
				 Atoms = TempNewAtoms
				 ).
				
		 

/*
 * Per ogni sottoformula di Wff, cerca di vedere essa sia tra i candidati.
 * Quando il connettivo principale di Wff e' implica, le sue sottoformule possono essere sostituite solo 
 * da candidati segnati T o Fc 
 * 
 */


simplyfyWff(TheCandidates, Wff, Res):- memberchk(swff(Sign,Wff), TheCandidates),
			   	       !,
				       (
			   	         memberchk(Sign, [f,fc]),
					 !,
					 Res = 0
					 ;
					 Res = 1
				       ).
			   
simplyfyWff(TheCandidates,  non(A), WffResult):- 
			    weakSimplyfyWff(TheCandidates, non(A), WffResult),
			    !.
 
simplyfyWff(TheCandidates, im(A,B), WffResult):- 
			    weakSimplyfyWff(TheCandidates, im(A,B), WffResult),
			    !.

/*
 * chiama direttamente weak simplify: si potrebbe fare qualcosa di piu' sofisticato
 * perche' potremmo avere ad esempio F (A-> B) tra i candidati e quindi il risultato sarebbe 
 * WffResult = 0. Ci sarebbero quindi dei casi da testare prima di fare la chiamata.
 */

simplyfyWff(TheCandidates, equiv(A,B), WffResult):-
			   (
			       /* If A->B\in TheCandidates */
			       memberchk(swff(Sign, im(A,B)), TheCandidates),
			       !,
			       /* Then */
			       (
			          memberchk(Sign, [f,fc]),
			          !,
			          WffResult = 0
				  ;
				  /* The sign is t */
				  weakSimplyfyWff(TheCandidates, im(B,A), WffResult)
			       )
				
			       ;
				
			       /* Else if B->A \in TheCandidates */
			       memberchk(swff(Sign, im(B,A)), TheCandidates),
			       !,
			       /* Then */
			       (
				  memberchk(Sign, [f,fc]),
			          !,
			          WffResult = 0
				  ;
				  weakSimplyfyWff(TheCandidates, im(A,B), WffResult)
			       )
			       
			       ;
				
			       weakSimplyfyWff(TheCandidates, equiv(A,B), WffResult)
                           ).



simplyfyWff(TheCandidates,  and(A, B), WffResult):- 
			    simplyfyWff(TheCandidates, A, WffResultA),
			    (
			    WffResultA = 0,
			    !,
			    WffResult = 0
			    
			    ;
			    
			    simplyfyWff(TheCandidates, B, WffResultB),
			               (
			                WffResultA = 1,
			                !,
			                WffResult = WffResultB
			                
					;
			                
					WffResultA = WffResultB,
			                !,
			                WffResult = WffResultB
			                
					;
			    		
					WffResultB = 1,
			                !,
			                WffResult = WffResultA
					;
			    		
					WffResultB = 0,
			                !,
			                WffResult = 0
					;
					
                                        composeWff(TheCandidates, and(WffResultA, WffResultB), WffResult)
					/*WffResult = and(WffResultA, WffResultB)*/
				       )
			    ),
			    !.

simplyfyWff(TheCandidates,  or(A, B), WffResult):- 
			    simplyfyWff(TheCandidates, A, WffResultA),
			    (
			    WffResultA = 1,
			    !,
			    WffResult = 1
			    
			    ;
			    
			    simplyfyWff(TheCandidates, B, WffResultB),
			               (
			                WffResultA = 0,
			                !,
			                WffResult = WffResultB
			                
					;
			                
					WffResultA = WffResultB,
			                !,
			                WffResult = WffResultB
			                
					;
			    		
					WffResultB = 0,
			                !,
			                WffResult = WffResultA
					;
			    		
					WffResultB = 1,
			                !,
			                WffResult = 1

					;
					composeWff(TheCandidates, or(WffResultA, WffResultB), WffResult)
					/*WffResult = or(WffResultA, WffResultB)*/
				       )
			    ),
			    !.




simplyfyWff(_,  Wff, Wff):- atomic(Wff).

/*
 *
 */

weakSimplyfyWff(TheCandidates, Wff, Res):- member(swff(Sign,Wff), TheCandidates),
				       (
			   	         Sign =  fc,
					 !,
					 Res = 0
					 ;
					 Sign = t,
					 !,
					 Res = 1
					 ;
					 fail
				       ).
			   

weakSimplyfyWff(TheCandidates,  non(A), WffResult):- 
			    weakSimplyfyWff(TheCandidates, A, WffA),
			    (
			    WffA = 0,
			    !,
			    WffResult = 1
			    ;
			    WffA = 1,
			    !,
			    WffResult = 0
			    ;
			    weakComposeWff(TheCandidates, non(WffA), WffResult)
			    /*WffResult = non(WffA)*/
			    ),
			    !
			    .
 
weakSimplyfyWff(TheCandidates, im(A,B), WffResult):- 
			    weakSimplyfyWff(TheCandidates, A, WffA),
			    (
			    WffA = 0,
			    !,
			    WffResult = 1
			    ;
			    weakSimplyfyWff(TheCandidates, B, WffB),
			    (
			    WffB = 1,
			    !,
			    WffResult = 1
			    ;
			    WffB = WffA,
			    !,
			    WffResult = 1
			    ;
			    WffA = 1,
			    !,
			    WffResult = WffB
			    ;
			    WffB = 0,
			    !,
			    weakComposeWff(TheCandidates, non(WffA), WffResult)
			    /*WffResult = non(WffA)*/
			    ;
			    weakComposeWff(TheCandidates, im(WffA, WffB), WffResult) 
			    /*WffResult = im(WffA,WffB)*/
			    ),
			    !
			    ).


weakSimplyfyWff(TheCandidates, equiv(A,B), WffResult):-
			   (
			       /* If A->B\in TheCandidates */
			       memberchk(swff(Sign, im(A,B)), TheCandidates),
			       not(Sign = f),
			       !,
			       /* Then */
			       (
			          Sign = fc,
			          !,
			          WffResult = 0
				  ;
				  
				  weakSimplyfyWff(TheCandidates, im(B,A), WffResult)
			        )
				
			       ;
				
			       /* Else if B->A \in TheCandidates */
			       memberchk(swff(Sign, im(B,A)), TheCandidates),
			       not(Sign = f),
			       !,
			       /* Then */
			       (
				  Sign = fc,
			          !,
			          WffResult = 0
				  ;

				  weakSimplyfyWff(TheCandidates, im(A,B), WffResult)
			       )
			       
			       ;
				
			    weakSimplyfyWff(TheCandidates, A, WffA),
			    weakSimplyfyWff(TheCandidates, B, WffB),
			    (
			    WffA = WffB,
			    !,
			    WffResult = 1
			    ;
			    WffA = 1,
			    !,
			    WffResult = WffB
			    ;
			    WffB = 1,
			    !,
			    WffResult = WffA
			    ;
			    WffB = 0,
			    !,
			    weakComposeWff(TheCandidates, non(WffA), WffResult)
			    /*WffResult = non(WffA)*/
			    ;
			    WffA = 0,
			    !,
			    weakComposeWff(TheCandidates, non(WffB), WffResult)
			    /*WffResult = non(WffB)*/
			    ;
			    weakComposeWff(TheCandidates, equiv(WffA, WffB), WffResult)
		    	    /*WffResult = equiv(WffA, WffB)*/
			    ) 
                           ).  



weakSimplyfyWff(TheCandidates,  and(A, B), WffResult):- 
			    weakSimplyfyWff(TheCandidates, A, WffResultA),
			    (
			    WffResultA = 0,
			    !,
			    WffResult = 0
			    
			    ;
			    
			    weakSimplyfyWff(TheCandidates, B, WffResultB),
			               (
			                WffResultA = 1,
			                !,
			                WffResult = WffResultB
			                
					;
			                
					WffResultA = WffResultB,
			                !,
			                WffResult = WffResultB
			                
					;
			    		
					WffResultB = 1,
			                !,
			                WffResult = WffResultA

					;
			    		
					WffResultB = 0,
			                !,
			                WffResult = 0
					;
					weakComposeWff(TheCandidates, and(WffResultA, WffResultB), WffResult)
					/*WffResult = and(WffResultA, WffResultB)*/
				       )
			    ),
			    !.

weakSimplyfyWff(TheCandidates,  or(A, B), WffResult):- 
			    weakSimplyfyWff(TheCandidates, A, WffResultA),
			    (
			    WffResultA = 1,
			    !,
			    WffResult = 1
			    
			    ;
			    
			    weakSimplyfyWff(TheCandidates, B, WffResultB),
			               (
			                WffResultA = 0,
			                !,
			                WffResult = WffResultB
			                
					;
			                
					WffResultA = WffResultB,
			                !,
			                WffResult = WffResultB
			                
					;
			    		
					WffResultB = 0,
			                !,
			                WffResult = WffResultA
					;
			    		
					WffResultB = 1,
			                !,
			                WffResult = 1

					;
					weakComposeWff(TheCandidates, or(WffResultA, WffResultB), WffResult)
					/*WffResult = or(WffResultA, WffResultB)*/
				       )
			    ),
			    !.


weakSimplyfyWff(_,  Wff, Wff):- atomic(Wff).
createSwffsFromWffs([], _, []).
createSwffsFromWffs([Atom | PositiveAtoms], Sign, [swff(Sign,Atom) | List]):-
			    		    createSwffsFromWffs(PositiveAtoms, Sign, List). 

assegnaTipoBranch(S, WhichBranch):-
			   (
			     not(memberchk(swff(f,_), S)),
			     !,
			     WhichBranch = safebranch
			     ;
			     WhichBranch = jumpbranch
			   ).

composeWff(TheCandidates, TheWff, WffResult):-
			  (
			   memberchk(swff(Sign, TheWff), TheCandidates),
			   !,
			   (
			     memberchk(Sign, [f,fc]),
			     !,
			     WffResult = 0
			   ;
			     WffResult = 1
			   ) 			     
			  ;
			   WffResult = TheWff
			  ).

weakComposeWff(TheCandidates, TheWff, WffResult):-
			  (
			   member(swff(Sign, TheWff), TheCandidates),
                           
			   (
			    Sign =  fc,
			    !,
			    WffResult = 0
			   ;
			    Sign = t,
			    !,
			    WffResult = 1
			   ;
			   /* tra i candidati Wff compare con segno f ma le f-formule non sono utilizzabili*/
			    WffResult = TheWff
		           )
			  ;
			   WffResult = TheWff
			  ). 



orderEquiv(equiv(X,Y), Res):-	orderEquiv(X, ResX),
		       		orderEquiv(Y, ResY),
				(
				ResX @< ResY,
				!,
				Res = equiv(ResX,ResY)
				;
				Res = equiv(ResY, ResX)
				).

orderEquiv(and(X,Y), Res):-	orderEquiv(X, ResX),
		       		orderEquiv(Y, ResY),
				(
				ResX @< ResY,
				!,
				Res = and(ResX,ResY)
				;
				Res = and(ResY, ResX)
				).

orderEquiv(or(X,Y), Res):-	orderEquiv(X, ResX),
		       		orderEquiv(Y, ResY),
				(
				ResX @< ResY,
				!,
				Res = or(ResX,ResY)
				;
				Res = or(ResY, ResX)
				).

orderEquiv(im(X,Y), im(ResX, ResY)):-	orderEquiv(X, ResX),
		       			orderEquiv(Y, ResY).

orderEquiv(non(X), non(ResX)):-	orderEquiv(X, ResX).

orderEquiv(X, X):- atom(X).

orderEquivSet([], []).
orderEquivSet([ swff(Sign,H) | T ], [ swff(Sign, H1) | T1 ]):-
								orderEquiv(H, H1),
								orderEquivSet(T, T1).
