:- module(labelutils,
          [
           label_atom/2,
           label_atom/3,
           row_labelify/2,
           term_labelify/2
          ]).

:- use_module(library(semweb/rdf11)).
:- use_module(library(sparqlprog/emulate_builtins)).

label_atom(S,A) :-
        label_atom(S,A,[]).

label_atom(S,A, _Opts) :-
        string(S),
        !,
        atom_string(A,S).
label_atom(X,A, Opts) :-
        \+ compound(X),
        atom(X),
        atom_iri(X,IRI),
        (   option(label_predicate(P),Opts)
        ->  rdf(IRI,P,Literal)
        ;   rdf(IRI,rdfs:label,Literal)),
        ensure_atom(Literal,A).

atom_iri(X,I) :-
        concat_atom([Pre,Local],:,X),
        \+ \+ rdf_current_prefix(Pre,_),
        rdf_global_id(Pre:Local,I),
        !.
atom_iri(X,X).


term_labelify(V,V) :-
        var(V),
        !.
term_labelify([],[]) :- !.
term_labelify([H|T],[H2|T2]) :-
        !,
        term_labelify(H,H2),
        term_labelify(T,T2).
term_labelify(T,T2) :-
        T =.. [P|Args],
        Args=[_|_],
        !,
        term_labelify(Args,Args2),
        T2 =.. [P|Args2].

term_labelify(T,T-A) :-
        label_atom(T,A),
        !.
term_labelify(T,T).

%! row_labelify(+Row,?LabeledRow) is det
%
% given a row term Foo(V1,V2,...,Vn)
% add an extra argument for the label for each
row_labelify(X,X2) :-
        X = _^^_,
        !,
        label_atom(X,X2).
row_labelify(X,X2) :-
        X = _@_,
        !,
        label_atom(X,X2).
row_labelify(Row,Row2) :-
        Row =.. [P|Args],
        rowargs_labelify(Args,Args2),
        Row2 =.. [P|Args2].

rowargs_labelify([],[]).
rowargs_labelify([H|T],[H2,Label|T2]) :-
        (   label_or_list_to_atom(H,Label)
        ->  true
        ;   Label=''),
        compactify_arg(H,H2),
        rowargs_labelify(T,T2).

compactify_arg(H,H2) :-
        rdf_global_id(Curie,H),
        Curie\=H,
        !,
        format(atom(H2),'~w',[Curie]).
compactify_arg(Var,'_') :-
        var(Var),
        !.
compactify_arg(Str^^_,H2) :-
        atom_string(H2,Str),
        !.
compactify_arg(L,A) :-
        is_list(L),
        !,
        maplist(compactify_arg,L,L2),
        concat_atom(L2,'|',A).
compactify_arg(H,H).

label_atom_det(L,A) :- label_atom(L,A),!.
label_atom_det(_,'').

label_or_list_to_atom(X,A) :-
        label_atom(X,A),
        !.
label_or_list_to_atom(L,A) :-
        is_list(L),
        !,
        maplist(label_atom_det,L,L2),
        concat_atom(L2,'|',A).

