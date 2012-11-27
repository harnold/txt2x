/*

\Predicate dl_append/3(+Diff_List_1, +Diff_List_2, -Diff_List_3).

Verkettet die Differenzlisten \verb|Diff_List_1| und \verb|Diff_List_2| und
gibt das Ergebnis in \verb|Diff_List_3| zurück.

\PL*/

dl_append(X-Y, Y-Z, X-Z).

/*PL

\Predicate dl_empty/1(?Diff_List).

Unifiziert \verb|Diff_List| mit einer leeren Differenzliste.

\PL*/

dl_empty(X-X) :-
    var(X).

/*PL

\Predicate dl_push_back/3(+Diff_List_In, +Elem, -Diff_List_Out).

Hängt \verb|Elem| and das Ende der Differenzliste \verb|Diff_List_In| an und
gibt das Erbenis in \verb|Diff_List_Out| zurück.

\PL*/

dl_push_back(List-[ Elem | Tail ], Elem, List-Tail).

/*PL

\Predicate dl_remove_front/3(+Diff_List_In, -Elem, -Diff_List_Out).

Entfernt das erste Element aus der Differenzliste \verb|Diff_List_In| und gibt
das Element in \verb|Elem|, die neue Liste in \verb|Diff_List_Out| zurück.

\PL*/

dl_remove_front(X-Z, Elem, Y-Z) :-
    nonvar(X),
    X = [ Elem | Y ].

/*PL

\Predicate dl_member/2(+Diff_List, +Elem).

Ist erfüllt, wenn \verb|Elem| Element der Differenzliste \verb|Diff_List| ist.

\PL*/

dl_member(Diff_List, Elem) :-
    dl_remove_front(Diff_List, Elem, _).

dl_member(Diff_List, Elem) :-
    dl_remove_front(Diff_List, _, Diff_List_1),
    dl_member(Diff_List_1, Elem).

/*PL

\Predicate dl_nth0/3(+Diff_List, +Index, -Elem).

Liefert in \verb|Elem| das Element an der Position \verb|Index| der
Differenzliste \verb|Diff_List| zurück. Die Positionszählung beginnt bei
Null.

\PL*/

dl_nth0(Diff_List, 0, Elem) :-
    dl_remove_front(Diff_List, Elem, _).

dl_nth0(Diff_List, Index, Elem) :-
    Index_1 is Index - 1,
    dl_remove_front(Diff_List, _, Diff_List_1),
    dl_nth0(Diff_List_1, Index_1, Elem).

/*PL

\Predicate dl_length/2(+Diff_List, -Length).

Liefert in \verb|Length| die Länge der Differenzliste \verb|Diff_List| zurück.

\PL*/

dl_length(Diff_List, 0) :-
    dl_empty(Diff_List).

dl_length(Diff_List, Length) :-
    dl_remove_front(Diff_List, _, Diff_List_1),
    dl_length(Diff_List_1, Length_1),
    Length is Length_1 + 1.

/*PL

\Predicate dl_to_list/2(+Diff_List, -List).

Konvertiert die Differenzliste \verb|Diff_List| in eine "`normale"'
Prolog-Liste und gibt diese in \verb|List| zurück.

\PL*/

dl_to_list(Diff_List, List) :-
    Diff_List = List-[].

/*PL
\EndProlog
*/