/**

  tests direct execution on prolog in-memory triples

*/

:- use_module(library(semweb/rdf11)).
:- use_module(library(sparqlprog)).
:- use_module(library(rdf_owl/owl)).

:- use_module(library(sparqlprog)).
:- use_module(library(sparqlprog/emulate_builtins)).

:- begin_tests(prolog_test,
               [setup(load_test_file),
                cleanup(rdf_retractall(_,_,_,_))]).

load_test_file :-
        rdf_load('tests/go_nucleus.ttl').

test_select(Q,ExpectedSPARQL) :-
        create_sparql_select(Q,SPARQL,[]),
        format(' ~q ==> ~w~n',[ Q, SPARQL ]),
        assertion( SPARQL = ExpectedSPARQL ).

test(direct_subclass_of) :-
        label(C,"nucleus"),
        setof(D,subClassOf(C,D),Ds),
        assertion(Ds = [Parent]),
        assertion(label(Parent, "intracellular membrane-bounded organelle")).

cls_label_ends_with(C,M) :-
        class(C),label(C,Label),str_ends(Label,M).
cls_label_starts_with(C,M) :-
        class(C),label(C,Label),str_starts(Label,M).

test(str_starts) :-
        setof(C,cls_label_starts_with(C,"cell"),Cs),
        assertion(Cs = [_,_,_]),
        assertion( (member(C,Cs),label(C,"cell")) ),
        assertion( (member(C,Cs),label(C,"cell part")) ).

test(str_ends) :-
        setof(C,cls_label_ends_with(C,"organelle"),Cs),
        assertion(Cs = [_,_,_,_]),
        assertion( (member(C,Cs),label(C,"organelle")) ),
        assertion( (member(C,Cs),label(C,"intracellular membrane-bounded organelle")) ).

has_dbxref(I,J):-rdf(I,'http://www.geneontology.org/formats/oboInOwl#hasDbXref',J).

has_dbxref_with_prefix(C,X,P) :- has_dbxref(C,X),str_before(X,":",P).
has_dbxref_with_prefix(C,P) :- has_dbxref_with_prefix(C,_,P).

test(str_before) :-
        % test with argument bound
        setof(C,has_dbxref_with_prefix(C,"Wikipedia"),Cs),
        assertion(Cs = [_,_,_,_]),
        member(C,Cs),
        label(C,"organelle"),
        % test with argument not-bound
        setof(P,has_dbxref_with_prefix(C,P),Ps),
        assertion( Ps = ["NIF_Subcellular","Wikipedia"] ).


:- end_tests(prolog_test).


