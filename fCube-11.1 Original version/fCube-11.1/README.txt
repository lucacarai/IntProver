fCube: an efficient prover for Intuitionistic propositional Logic


About fCube-11 
fCube-11 is a decision procedure, neither proof or countermodel is provided.
fCube-4 is the most recent version providing a proof or a countermodel.
fCube-11 implements the following optimizations that are missing on fCube-4:
        
* some logical optimizations that extend  the rules cperm described in the paper
          
"Simplification Rules for Intuitionistic Propositional Tableaux", TOCL 2010;
        
* logical rules for the equivalence.

    

    
Copyright (C) 2013  Mauro Ferrari,          email:  mauro.ferrari@uninsubria.it
                        Camillo Fiorentini      email:  fiorenti@dsi.unimi.it
                        Guido Fiorino           email: guido.fiorino@unimib.it

    
This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    
This program is distributed in the hope that it will be useful,
    
but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    
GNU General Public License for more details.

    
You should have received a copy of the GNU General Public License
    along with this program.  
If not, see <http://www.gnu.org/licenses/>.
                

        
                        INSTRUCTIONS
        
Syntax:
        implication:    im(,);
        negation:       non();
        equivalence:    equiv(,);
        conjuncton:     and(,);
        disjunction:    or(,).
	        
        Example: ((a&b)->~c) is im(and(a,b),non(c)) 
        
        
To decide a formula use the predicate 'decide'. 
        
        
For example 'decide(im(a,non(a))).';
        




This version requires swi-prolog.
Latest version of SWI-Prolog used to develop fCube: SWI-Prolog (Multi-threaded, 64 bits, Version 6.2.6)
fCube-11 was developed on an Apple MacBook Pro.



To decide the formula the file 'filename.txt' the easiest way is to use 'fCube.bash':
   	    	    	 
			 fCube.bash filename.txt


To decide the formulas of the ILTP library run the bash script 'test.bash' from the root of fCube tree
or the command 

			swipl 


To decide large formulas it can be necessary to reserve more space for the global stack.
Use the option -G (for more information on the stack options see SWI-Prolog manual). 

As an example 
	
		
swipl -G1g fCube < filename.txt


The structure of the directory is the following:
fCube/		
contains 'fCube.bash' and the prolog code 'fCube' and 'fCube-verbose'. 
		'fCube-verbose' outputs the proof and the countermodel;



ILTP/   	contains the formulas of the ILTP library in the format suitable for fCube. 
        	
As an example type:  
		      swipl -s fCube/fCube < ILTP/SYJ207+1.002.pitp 
		
to decide the formula  SYJ207+1.002 of  ILTP library;



otherWffs/ 	contains some formulas characterizing intermediate formulas;


script/		some utilities. In particular test.bash is useful to run fCube on the formulas of ILTP 

library
paper/		some slides presented at Lpar'10 and Cilc'09  
