/*

\Predicate string_replace_all/4(+Old_String, +Old_Text, +New_Text,
                -New_String).

Ersetzt alle Vorkommen von \verb|Old_Text| in \verb|Old_String| durch
\verb|New_Text| und gibt das Ergebnis in \verb|New_String| zurück. Das
Prädikat ist auch dann erfolgreich, wenn \verb|Old_Text| nicht in
\verb|Old_String| vorkommt.

\PL*/

string_replace_all(Old_String, Old_Text, New_Text, New_String) :-
    string_replace_all_rep(Old_String, Old_Text, New_Text, New_String, 0).

/*PL

\Predicate string_replace_all_rep/5(+Old_String, +Old_Text, +New_Text,
                -New_String, +Start).

Mit Hilfe dieses Prädikats wird die Iteration von
\verb|string_replace_all/4| ausgeführt. In \verb|Start| wird die Position
im Text angegeben, bei der mit der Textersetzung begonnen werden soll.

\PL*/

string_replace_all_rep(Old_String, Old_Text, New_Text, New_String, Start) :-
    string_replace(Old_String, Old_Text, New_Text, New_String_1, Start, Cont),
    string_replace_all_rep(New_String_1, Old_Text, New_Text, New_String, Cont).

string_replace_all_rep(Old_String, _, _, Old_String, _).

/*PL

\Predicate string_replace/5(+Old_String, +Old_Text, +New_Text, -New_String,
                +Start, -Cont).

Ersetzt in \verb|Old_String| ab der Position \verb|Start| das erste Vorkommen
von \verb|Old_Text| durch \verb|New_Text| und liefert das Ergebnis in
\verb|New_String| zurück. Die Position, an welcher der Text ersetzt wurde, wird
in \verb|Cont| zurückgeliefert. Das Prädikat schlägt fehl, wenn
\verb|Old_Text| nicht in \verb|Old_String| enthalten ist.

\PL*/

string_replace(Old_String, Old_Text, New_Text, New_String, Start, Cont) :-
    sub_string(Old_String, 0, Start, _, String_1),
    sub_string(Old_String, Start, _, 0, String_2),
    string_replace(String_2, Old_Text, New_Text, New_String_2, Index),
    string_concat(String_1, New_String_2, New_String),
    string_length(New_Text, L_New),
    Cont is Start + Index + L_New.

/*PL

\Predicate string_replace/4(+Old_String, +Old_Text, +New_Text, -New_String,
                -Index).

Ersetzt in \verb|Old_String| das erste Vorkommen von \verb|Old_Text| durch
\verb|New_Text| und liefert das Ergebnis in \verb|New_String| zurück. Die
Position, an welcher der Text ersetzt wurde, wird in
\verb|Index| zurückgeliefert. Das Prädikat schlägt fehl, wenn
\verb|Old_Text| nicht in \verb|Old_String| enthalten ist.

\PL*/

string_replace(Old_String, Old_Text, New_Text, New_String, Index) :-
    sub_string(Old_String, Start, Length, _, Old_Text),
    Start_1 is Start + Length,
    sub_string(Old_String, 0, Start, _, New_Text_1),
    sub_string(Old_String, Start_1, _, 0, New_Text_2),
    string_concat(New_Text_1, New_Text, New_Text_3),
    string_concat(New_Text_3, New_Text_2, New_String),
    string_length(New_Text_1, Index).

/*PL

\Predicate string_to_charlist/2(+String, -Char_List).

Konvertiert \verb|String| in eine Liste von Zeichen und gibt das Ergebnis in
\verb|Char_List| zurück. Im Gegensatz zu \verb|string_to_list/2| wird z.B.
der String \verb|'AB'| nicht als \verb|[65, 66]| zurückgegeben, sondern als
\verb|['A', 'B']|.

\PL*/

string_to_charlist(String, Char_List) :-
    string_to_list(String, ASCII_List),
    string_to_charlist_rep(ASCII_List, [], _, Char_List).

/*PL

\Predicate string_to_charlist_rep/4(+ASCII_In, +Chars_In, -ASCII_Out,
                -Chars_Out).

Führt die Iteration von \verb|string_to_charlist/2| aus. In jedem Schritt
wird das jeweils erste Element aus \verb|ASCII_In| entnommen, und an
\verb|Chars_In| angefügt.

\PL*/

string_to_charlist_rep([], Chars_In, [], Chars_Out) :-
    Chars_Out = Chars_In.

string_to_charlist_rep(ASCII_In, Chars_In, ASCII_Out, Chars_Out) :-
    ASCII_In = [ ASCII_Char | ASCII_Out_1 ],
    char_code(Char, ASCII_Char),
    append(Chars_In, [ Char ], Chars_Out_1),
    string_to_charlist_rep(ASCII_Out_1, Chars_Out_1, ASCII_Out, Chars_Out).

/*PL
\EndProlog
*/