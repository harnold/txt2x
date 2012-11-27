/*

\Predicate scanner/2(+Filename, +Sym_List).
Hauptpr"adikat. ASCII-File lesen, mit Grammatik Symbole erzeugen,
Symbole zur"uckgeben

\PL*/

scanner(Filename, Sym_List) :-
    scanner_read_file(Filename, Char_List),    
    phrase(scanner_doc(Sym_List), Char_List, _).

/*PL

\Predicate scanner_read_file/2(+Filename, -Char_List).

Dieses Pr"adikat wird f"ur die Dateiarbeit eingesetzt.
Eine ASCII-Datei wird ge"offnet, die Funktion \verb|scanner_read_char/3|
wird zum einlesen der einzelnen Zeichen aufgerufen,
anschliessend wird die Datei geschlossen.

\PL*/

scanner_read_file(Filename, Char_List) :-
    open(Filename, read, S),
    dl_empty(Empty_List),
    scanner_read_char(S, Empty_List, Char_Diff_List),
    close(S),
    dl_to_list(Char_Diff_List, Char_List).

/*PL

\Predicate scanner_read_char/3(+S, +Chars_In, -Chars_Out).

Aus dem Stream \verb|S| wird die ASCII-Datei Zeichen f"ur Zeichen eingelesen.
Mit jedem Aufruf von \verb|scanner_read_char/3| wird die Anzahl der noch
zu lesenden Zeichen um genau 1 kleiner, die Liste der gelesenen Zeichen
wird um 1 l"anger. Bei jedem Aufruf von \verb|dl_push_back| wird zur
Differenzliste das gerade gelesene Zeichen hinzugef"ugt.

\verb|scanner_read_char/3| ruft sich solange rekursiv auf, bis das Ende
der ASCII-Datei erreicht wurde, und ein \verb|end_of_file| gelesen wurde.

\PL*/

scanner_read_char(S, Chars_In, Chars_Out) :-
    get_char(S, C),
    (
        C = end_of_file ->
            Chars_Out = Chars_In
        ;
            dl_push_back(Chars_In, C, Chars_Out_1),
            scanner_read_char(S, Chars_Out_1, Chars_Out)
    ).

/*PL

\Predicate scanner_write_sym_file/2(+Filename, +Sym_List).

Dieses Pr"adikat gibt die Liste der erzeugten Symbole in
eine Datei mit dem Namen \verb|Filename| aus.

\PL*/

scanner_write_sym_file(Filename, Sym_List) :-
    open(Filename, write, S),
    write(S, Sym_List),
    close(S).

/*PL

\Predicate scanner_doc/1(-Sym_List).

Dokument bearbeiten, Aufruf von \verb|scanner_doc_rep/2|

\PL*/

scanner_doc(Sym_List) -->
    scanner_doc_rep([], Sym_List).

/*PL

\Predicate scanner_doc_rep/2(+In, -Out).

Pr"adikat zum Bearbeiten des Dokumentes.

Es wird \verb|scanner_doc_child| aufgerufen. \verb|scanner_doc_rep| ruft
sich selbst immer wieder auf, bis \verb|In| leer ist, d.h. keine Zeichen
mehr zu bearbeiten sind.

Scheitert \verb|scanner_doc_child|, d.h. kein Symbol in der gegebenen
Reihenfolge mehr lesbar, so wird \verb|scanner_doc_child| beim n"achsten
Aufruf von \verb|scanner_doc_rep| erneut aufgerufen.

\PL*/

scanner_doc_rep(In, Out) -->
    scanner_doc_child(In, Out_1),
    scanner_doc_rep(Out_1, Out).

scanner_doc_rep(In, Out) -->
    scanner_doc_child(In, Out).

/*PL

\Predicate scanner_doc_child/2(+In, -Out).

Der aktuell zu bearbeitende Textteil wird nach Symbolen durchsucht.
Es wird versucht Symbol f"ur Symbol in der vorgegebenen Reihenfolge
einzulesen. Ist im aktuellen Aufruf kein Lesen eines weiteren Symbols
mehr m"oglich, wird der verbleibende Resttext beim n"achsten Aufruf
von \verb|scanner_doc_child| gelesen.

In folgender Reihenfolge wird versucht ein Symbol zu lesen:

\begin{enumerate}
    \item f"uhrende Leerzeichen
    \item Leerzeile
    \item vorformatierter Text
    \item Stern-Unterstreichung
    \item doppelte Unterstreichung
    \item einfache Unterstreichung
    \item Listenanstrich
    \item Aufz"ahlungsanstrich
    \item einzubettende Objekte (Bilder)
    \item Spaltentrenner
    \item Text
\end{enumerate}

\PL*/

scanner_doc_child(In, Out) -->
    (
        scanner_indent(In, Out);
        scanner_break(In, Out);
        scanner_pre(In, Out);
        scanner_starul(In, Out);
        scanner_doubleul(In, Out);
        scanner_singleul(In, Out);
        scanner_list_bullet(In, Out);
        scanner_enum_bullet(In, Out);
        scanner_include(In, Out);
        scanner_colseparator(In, Out);
        scanner_text(In, Out)
    ).

/*PL

\Predicate scanner_indent/2(+In, -Out).

Dieses Pr"adikat versucht, Whitespaces am Anfang einer Zeile zu lesen,
und erzeugt, falls es diese findet, das Symbol \verb|sym_ident|.

\PL*/

scanner_indent(In, Out) -->
    scanner_white,
    {
        append(In, [ sym_indent ], Out)
    }.

/*PL

\Predicate scanner_pre/2(+In, -Out).

Dieses Pr"adikat liest vorformatierten Text.

Aus \verb|"""T"""| werden die Symbole \verb|sym_pre|, \verb|sym_text(T)|,
\verb|sym_pre| erzeugt. Alle gefundenen Zeichen werden als Text 1:1 "ubernommen.
Dazu wird das Pr"adikat \verb|scanner_pretext| aufgerufen.

\PL*/

scanner_pre(In, Out) -->
    scanner_presym,
    scanner_pretext(T),
    scanner_presym,
    {
        append(In, [ sym_pre, sym_text(T), sym_pre ], Out)
    }.

/*PL

\Predicate scanner_pretext/1(-T).

Dieses Pr"adikat liest alle Zeichen bis zum auftreten von \verb|"""|.
Wird von \verb|scanner_pre| aufgerufen.

\PL*/

scanner_pretext(T) -->
    scanner_cdata(T1),
    {
        ( sub_string(T1, 0, _, _, '"""') -> fail ; true )
    },
    scanner_pretext(T2), !,
    {
        string_concat(T1, T2, T)
    }.

scanner_pretext(T) -->
    scanner_cdata(T),
    {
        ( sub_string(T, 0, _, _, '"""') -> fail ; true )
    }.

scanner_presym -->
    [ '"' ], [ '"' ], [ '"' ].

/*PL

\Predicate scanner_text/2(+In, -Out).

Dieses Pr"adikat liest Text, und erzeugt das Symbol \verb|sym_text(T)|.
Das Lesen der einzelnen Zeichen wird beendet, wenn ein Zeilenende oder
ein Spaltentrenner gefunden wurde.

\PL*/

scanner_text(In, Out) -->
    scanner_cdata(T),
    {
        append(In, [ sym_text(T) ], Out)
    }.

/*PL

\Predicate scanner_break/2(+In, -Out).
Dieses Pr"adikat findet eine Leerzeile, und erzeugt dann das Symbol
\verb|sym_break|.

\PL*/

scanner_break(In, Out) -->
    [ T ],
    {
        T = '\n',
        append(In, [ sym_break ] , Out)
    }.

/*PL

\Predicate scanner_colseperator/2(+In, -Out).

Dieses Pr"adikat findet Spaltentrenner, und erzeugt dann das Symbol
\verb|sym_col_seperator|. Whitespaces zwischen dem Spaltentrenner und dem
nachfolgenden Text werden "uberlesen.

\PL*/

scanner_colseparator(In, Out) -->
    [ '|' ],
    scanner_white_opt,
    {
        append(In, [ sym_col_separator ] , Out)
    }.

/*PL

\Predicate scanner_cdata/1(-T).

Dieses Pr"adikat liest Zeichen fuer \verb|sym_text|. Das Einlesen wird beim
Auftreten von Newline oder dem Spaltentrennsymbol beendet.

\PL*/

scanner_cdata(T) -->    [ T1 ],
    {        
        ( T1 = '\n'  -> fail; true ),
        ( T1 = '|'  -> fail; true )
    }, 
    scanner_cdata(T2), !,
    {
        string_concat(T1, T2, T)
    }.

scanner_cdata(T) -->
    [ T ],
    {
        ( T = '|'  -> fail; true )
    }.

/*PL

\Predicate scanner_white/0().

Dieses Pr"adikat liest Zeichen, solange diese Whitespaces sind.

\PL*/

scanner_white -->
    [ T ],
    {
        char_type(T, white)
    },
    scanner_white.

scanner_white -->
    [ T ],
    {
        char_type(T, white)
    }.

/*PL

\Predicate scanner_starul/2(+In, -Out).

Dieses Pr"adikat sucht Unterstreichungen mit \verb|*****|. Wird diese Art der
Unterstreichung gefunden, so wird das Symbol \verb|sym_star_ul| erzeugt.

\PL*/

scanner_starul(In, Out) -->
    scanner_starulsym,
    scanner_cdata(_),
    {
        append(In, [ sym_star_ul ], Out)
    }.

scanner_starulsym -->
    [ '*' ], [ '*' ], [ '*' ], [ '*' ], [ '*' ].

/*PL

\Predicate scanner_doubleul/2(+In, -Out).

Dieses Pr"adikat sucht Unterstreichungen mit \verb|=====|. Wird diese Art der
Unterstreichung gefunden, so wird das Symbol \verb|sym_double_ul| erzeugt.

\PL*/

scanner_doubleul(In, Out) -->
    scanner_doubleulsym,
    scanner_cdata(_),
    {
        append(In, [ sym_double_ul ], Out)
    }.

scanner_doubleulsym -->
    [ '=' ], [ '=' ], [ '=' ], [ '=' ], [ '=' ].

/*PL

\Predicate scanner_singleul/2(+In, -Out).

Dieses Pr"adikat sucht Unterstreichungen mit \verb|-----|. Wird diese Art der
Unterstreichung gefunden, so wird das Symbol \verb|sym_single_ul| erzeugt.

\PL*/

scanner_singleul(In, Out) -->
    scanner_singleulsym,
    scanner_cdata(_),
    {
        append(In, [ sym_single_ul ], Out)
    }.

scanner_singleulsym -->
    [ '-' ], [ '-' ], [ '-' ], [ '-' ], [ '-' ].

/*PL

\Predicate scanner_include/2(+In, -Out).

Dieses Pr"adikat sucht einzubettende Objekte, zum Beipiel Bilder. Werden die
Zeichen \verb|<<| und \verb|>>| gefunden, so werden die Zeichen dazwischen
als Text "ubergeben.

Von diesem Pr"adikat werden folgende Symbole erzeugt: \verb|sym_begin_include|,
\verb|sym_text(T)| und \verb|sym_end_include|. Es wird
\verb|scanner_cd| aufgerufen.

\PL*/

scanner_include(In, Out) -->
    scanner_begin_include_sym,
    scanner_cd(T),
    scanner_end_include_sym,
    {
        append(In, [ sym_begin_include, sym_text(T), sym_end_include ], Out)
    }.

/*PL

\Predicate scanner_cd/1(T).

Dieses Pr"adikat wird von \verb|scanner_include| aufgerufen.
Der Text zwischen \verb|<<| und \verb|>>| wird eingelesen.

\PL*/

scanner_cd(T) -->    [ T1 ],
    {        
        ( T1 = '>'  -> fail; true )
    }, 
    scanner_cd(T2), !,
    {
        string_concat(T1, T2, T)
    }.

scanner_cd(T) -->
    [ T ],
    {
        ( T = '>'  -> fail; true )
    }.

scanner_begin_include_sym -->
    [ '<' ], [ '<' ].


scanner_end_include_sym -->
    [ '>' ], [ '>' ].

/*PL

\Predicate scanner_list_bullet/2(+In, -Out).

Dieses Pr"adikat findet Listenanstriche, und erzeugt dann das Symbol
\verb|sym_list_bullet|. Whitespaces zwischen dem Listenanstrich und dem
nachfolgenden Text werden "uberlesen.

\PL*/

scanner_list_bullet(In, Out) -->
    [ '-' ],
    scanner_white_opt,
    {
        append(In, [ sym_list_bullet ] , Out)
    }.

/*PL

\Predicate scanner_enum_bullet/2(+In, -Out).

Dieses Pr"adikat findet Aufzaehlungsanstriche, und erzeugt dann das Symbol
\verb|sym_enum_bullet|. Whitespaces zwischen dem Aufzaehlungsanstrich und
dem nachfolgenden Text werden ueberlesen.

\PL*/

scanner_enum_bullet(In, Out) -->
    [ '#' ],
    scanner_white_opt,
    {
        append(In, [ sym_enum_bullet ] , Out)
    }.

/*PL

\Predicate scanner_white_opt/2(+In, -Out).

Dieses Pr"adikat "uberliest 0..n Whitespaces. Es wird aufgerufen von
\verb|scanner_list_bullet|, \verb|scanner_enum_bullet| und
\verb|scanner_colseperator|.

\PL*/

scanner_white_opt -->
    scanner_white.

scanner_white_opt -->
    [].

/*PL
\EndProlog
*/