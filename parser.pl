/*

\Predicate parser/2(+Sym_List, -Doc).

Startet den Parsing-Vorgang. Aus der Symbolliste \verb|Sym_List| wird eine
Dokumentenstruktur erzeugt und in \verb|Doc| zurückgeliefert.

\PL*/

parser(Sym_List, Doc) :-
    phrase(parser_doc(Doc_1), Sym_List, _),
    parser_postprocess(Doc_1, Doc).

/*PL

\Predicate parser_postprocess/2(+Doc_In, -Doc_Out).

Startet den Postprocessing-Schritt. In diesem Teil werden alle Textelemente
darauf untersucht, ob sie Email-Adressen oder URLs enthalten. Diese werden
als eigene Elemente erkannt und die Dokumentenstruktur entsprechend
modifiziert.

\PL*/

parser_postprocess(Doc_In, Doc_Out) :-
    parser_pp_element(Doc_In, Doc_Out_List_1, parser_pp_email),
    [ Doc_Out_1 ] = Doc_Out_List_1,
    parser_pp_element(Doc_Out_1, Doc_Out_List, parser_pp_url),
    [ Doc_Out ] = Doc_Out_List.

/*PL

\Predicate parser_extract_url/4(+Text, -Url, +Start, -Length).

Untersucht, ob \verb|Text| beginnend ab Position \verb|Start| eine URL
enthält. Ist dies der Fall, wird die URL in \verb|Url| und ihre Länge in
\verb|Length| zurückgeliefert. Andernfalls scheitert das Prädikat.

\PL*/

parser_extract_url(Text, Url, Start, Length) :-
    string_to_charlist(Text, Text_List),
    parser_extract_url_rep(Text_List, Url, 0, Start),
    string_length(Url, Length).

/*PL

\Predicate parser_extract_url_rep/4(+Text_List, -Url, +Index_In, -Index_Out).

Führt die Iteration für \verb|parser_extract_url/4| über den Text aus. In
jedem Schritt, in dem keine URL gefunden werden konnte, wird der Startindex
um eins weitergesetzt, bis das Ende des Textes erreicht ist.

\PL*/

parser_extract_url_rep(Text_List, Url, Index_In, Index_Out) :-
    (
        phrase(parser_url(Url), Text_List, _),
        Index_Out = Index_In
    ;
        Index_1 is Index_In + 1,
        Text_List = [ _ | Text_List_1 ],
        Text_List_1 \= [],
        parser_extract_url_rep(Text_List_1, Url, Index_1, Index_Out)
    ).

/*PL

\Predicate parser_extract_email/4(+Text, -Email, -Start, -Length).

Untersucht, ob \verb|Text| beginnend ab Position \verb|Start| eine Email-Adresse
enthält. Ist dies der Fall, wird die Email-Adresse in \verb|Url| und ihre Länge 
in \verb|Length| zurückgeliefert. Andernfalls scheitert das Prädikat.

\PL*/

parser_extract_email(Text, Email, Start, Length) :-
    string_to_charlist(Text, Text_List),
    parser_extract_email_rep(Text_List, Email, 0, Start),
    string_length(Email, Length).

/*PL

\Predicate parser_extract_email_rep/4(+Text_List, -Email, +Index_In, -Index_Out).

Führt die Iteration für \verb|parser_extract_email/4| über den Text aus. In
jedem Schritt, in dem keine Email-Adresse gefunden werden konnte, wird der
Startindex um eins weitergesetzt, bis das Ende des Textes erreicht ist.

\PL*/

parser_extract_email_rep(Text_List, Email, Index_In, Index_Out) :-
    (
        phrase(parser_email(Email), Text_List, _),
        Index_Out = Index_In
    ;
        Index_1 is Index_In + 1,
        Text_List = [ _ | Text_List_1 ],
        Text_List_1 \= [],
        parser_extract_email_rep(Text_List_1, Email, Index_1, Index_Out)
    ).

/*PL

\Predicate parser_pp_email/2(+T, -Elem_List_Out).

Untersucht den Text \verb|T| auf enthaltene Email-Adressen und ersetzt diese
durch entsprechende email-Elemente. Die neue Elementliste wird in
\verb|Elem_List_Out| zurückgegeben.

\PL*/

parser_pp_email(T, Elem_List_Out) :-
    sub_string(T, _, _, _, '@'),
    parser_extract_email(T, Email, Start, Length),
    sub_string(T, 0, Start, _, T1),
    Start_T2 is Start + Length,
    sub_string(T, Start_T2, _, 0, T2),
    parser_pp_element(text(T2), T2_List, parser_pp_email),
    append([ text(T1) ], [ email(Email) ], Out_1),
    append(Out_1, T2_List, Elem_List_Out).

/*PL

\Predicate parser_pp_url/2(+T, -Elem_List_Out).

Untersucht den Text \verb|T| auf enthaltene URLs und ersetzt diese durch
entsprechende url-Elemente. Die neue Elementliste wird in
\verb|Elem_List_Out| zurückgegeben.

\PL*/

parser_pp_url(T, Elem_List_Out) :-
    (
        sub_string(T, _, _, _, 'http');
        sub_string(T, _, _, _, 'ftp');
        sub_string(T, _, _, _, 'file')
    ),
    parser_extract_url(T, Url, Start, Length),
    sub_string(T, 0, Start, _, T1),
    Start_T2 is Start + Length,
    sub_string(T, Start_T2, _, 0, T2),
    parser_pp_element(text(T2), T2_List, parser_pp_url),
    append([ text(T1) ], [ url(Url) ], Out_1),
    append(Out_1, T2_List, Elem_List_Out).

/*PL

\Predicate parser_pp_element/3(+Elem_In, -Elem_List_Out, +PP_Func).

Führt den Postprocessing-Schritt für das Element \verb|Elem_In| mit der
Funktion \verb|PP_Func| aus. Die daraus resultierende Elementliste wird in
\verb|Elem_List_Out| zurückgegeben.

Wenn das Element kein Textelement ist und untergeordnete Elemente besitzt,
wird das Prädikat \verb|parser_pp_element_list/3| mit der Liste der
untergeordneten Elemente aufgerufen.

\PL*/

parser_pp_element(text(T), Elem_List_Out, PP_Func) :-
    (
        call(PP_Func, T, Elem_List_Out) ;
        Elem_List_Out = [ text(T) ]
    ).

parser_pp_element(Elem_In, Elem_List_Out, PP_Func) :-
    Elem_In =.. [ Elem_Name | Child_List ],
    (
        Child_List = [],
        Elem_List_Out = [ Elem_In ]
    ;
        parser_pp_element_list(Child_List, Child_List_Out, PP_Func),
        Elem_Out =.. [ Elem_Name | Child_List_Out ],
        Elem_List_Out = [ Elem_Out ]
    ).

/*PL

\Predicate parser_pp_element_list/3(+Elem_List_In, -Elem_List_Out, +PP_Func).

Ruft \verb|parser_pp_element/3| nacheinander für alle Elemente der Liste
\verb|Elem_List_In| auf und sammelt die daraus entstandenen Elemente, die es
in \verb|Elem_List_Out| zurückgibt.

\PL*/

parser_pp_element_list([], [], _).

parser_pp_element_list(Elem_List_In, Elem_List_Out, PP_Func) :-
    Elem_List_In = [ First_Elem | Rest_Elem_List ],
    parser_pp_element(First_Elem, First_Elem_PP_List, PP_Func),
    parser_pp_element_list(Rest_Elem_List, Rest_Elem_PP_List, PP_Func),
    append(First_Elem_PP_List, Rest_Elem_PP_List, Elem_List_Out).

/*PL

\Predicate parser_append_child/3(+In, +Child, -Out).

Fügt an das Dokument-Element \verb|In| das Element \verb|Child| als
zusätzliches untergeordnetes Element an und gibt das veränderte Element in
\verb|Out| zurück.

\PL*/

parser_append_child(In, Child, Out) :-
    In  =.. [ Elem_Name | Old_Child_List ],
    append(Old_Child_List, [ Child ], New_Child_List),
    Out =.. [ Elem_Name | New_Child_List ].

/*PL

\Predicate parser_doc/1(-Doc).

Startsymbol für den Parser, steht für das gesamte Dokument.

\PL*/

parser_doc(Doc) -->
    parser_doc_rep(doc, Doc).

/*PL

\Predicate parser_doc_rep/2(+In, -Out).

Führt die Iteration für \verb|parser_doc/1| über die Child-Elemente des
Dokuments aus.

Alle Parser-Regeln, die sich auf Elemente des Dokuments beziehen, erhalten
das übergeordnete Element (mit eventuell bereits angefügten Child-Elementen)
als Parameter \verb|In| und geben den neuen Teilbaum mit neu hinzugefügten
Child-Elementen über \verb|Out| zurück. Diese beiden Parameter werden im
Folgenden nicht immer wieder erläutert.

\PL*/

parser_doc_rep(In, Out) -->
    parser_doc_child(In, Out_1),
    parser_doc_rep(Out_1, Out).

parser_doc_rep(In, Out) -->
    parser_doc_child(In, Out).

/*PL

\Predicate parser_doc_child/2(+In, -Out).

Regel für alle Elemente, die Child-Element von \verb|doc| sein können.

\PL*/

parser_doc_child(In, Out) -->
    (
        parser_sec(In, Out);
        parser_subsec(In, Out);
        parser_subsubsec(In, Out);
        parser_enum(In, Out);
        parser_list(In, Out);
        parser_pre(In, Out);
        parser_image(In, Out);
        parser_table(In, Out);
        parser_title(In, Out);
        parser_para(In, Out);
        parser_linebreak(In, Out)
    ).

/*PL

\Predicate parser_title/2(+In, -Out).

Regel für ein Titel-Element.

\PL*/

parser_title(In, Out) -->
    parser_title_text(T),
    {
        parser_append_child(In, title(T), Out)
    }.

/*PL

\Predicate parser_title_text/1(-T).

Regel für Titeltext. Jeder explizit eingerückte Text wird als Titeltext
betrachtet, dieser wird in \verb|T| zurückgegeben.

\PL*/

parser_title_text(T) -->
    [ sym_indent   ],
    [ sym_text(T1) ],
    parser_title_text(T2), !,
    {
        string_concat(T1, T2, T)
    }.

parser_title_text(T) -->
    [ sym_indent  ],
    [ sym_text(T) ].

/*PL

\Predicate parser_sec/2(+In, -Out).

Regel für Abschnitte der Ebene 1. Diese bestehen aus einer Überschrift und den
entsprechenden Child-Elementen.

\PL*/

parser_sec(In, Out) -->
    parser_sec_heading(sec, Out_1),
    parser_sec_rep(Out_1, Out_2),
    {
        parser_append_child(In, Out_2, Out)
    }.

/*PL

\Predicate parser_sec_rep/2(+In, -Out).

Iteriert über die Child-Elemente eines Abschnitts der Ebene 1.

\PL*/

parser_sec_rep(In, Out) -->
    parser_sec_child(In, Out_1),
    parser_sec_rep(Out_1, Out).

parser_sec_rep(In, Out) -->
    parser_sec_child(In, Out).

/*PL

\Predicate parser_sec_child/2(+In, -Out).

Regel für alle Elemente, die Child-Elemente von \verb|sec| sein können.

\PL*/

parser_sec_child(In, Out) -->
    (
        parser_subsec(In, Out);
        parser_subsubsec(In, Out);
        parser_enum(In, Out);
        parser_list(In, Out);
        parser_pre(In, Out);
        parser_image(In, Out);
        parser_table(In, Out);
        parser_para(In, Out);
        parser_linebreak(In, Out)
    ).

/*PL

\Predicate parser_sec_heading/2(+In, -Out).

Regel für eine Überschrift der Ebene 1. Diese besteht aus einer Textzeile,
die mit Stern-Symbolen (*) unterstrichen ist.

\PL*/

parser_sec_heading(In, Out) -->
    parser_cdata(T),
    [ sym_star_ul ],
    {
        parser_append_child(In, heading(T), Out)
    }.

/*PL

\Predicate parser_subsec/2(+In, -Out).

Regel für Abschnitte der Ebene 2. Diese bestehen aus einer Überschrift und den
entsprechenden Child-Elementen.

\PL*/

parser_subsec(In, Out) -->
    parser_subsec_heading(subsec, Out_1),
    parser_subsec_rep(Out_1, Out_2),
    {
        parser_append_child(In, Out_2, Out)
    }.

/*PL

\Predicate parser_subsec_rep/2(+In, -Out).

Iteriert über die Child-Elemente eines Abschnitts der Ebene 2.

\PL*/

parser_subsec_rep(In, Out) -->
    parser_subsec_child(In, Out_1),
    parser_subsec_rep(Out_1, Out).

parser_subsec_rep(In, Out) -->
    parser_subsec_child(In, Out).

/*PL

\Predicate parser_subsec_child/2(+In, -Out).

Regel für alle Elemente, die Child-Elemente von \verb|subsec| sein können.

\PL*/

parser_subsec_child(In, Out) -->
    (
        parser_subsubsec(In, Out);
        parser_enum(In, Out);
        parser_list(In, Out);
        parser_pre(In, Out);
        parser_image(In, Out);
        parser_table(In, Out);
        parser_para(In, Out);
        parser_linebreak(In, Out)
    ).

/*PL

\Predicate parser_subsec_heading/2(+In, -Out).

Regel für eine Überschrift der Ebene 2. Diese besteht aus einer Textzeile,
die mit Minus-Symbolen (-) unterstrichen ist.

\PL*/

parser_subsec_heading(In, Out) -->
    parser_cdata(T),
    [ sym_double_ul ],
    {
        parser_append_child(In, heading(T), Out)
    }.

/*PL

\Predicate parser_subsubsec/2(+In, -Out).

Regel für Abschnitte der Ebene 3. Diese bestehen aus einer Überschrift und den
entsprechenden Child-Elementen.

\PL*/

parser_subsubsec(In, Out) -->
    parser_subsubsec_heading(subsubsec, Out_1),
    parser_subsubsec_rep(Out_1, Out_2),
    {
        parser_append_child(In, Out_2, Out)
    }.

/*PL

\Predicate parser_subsubsec_rep/2(+In, -Out).

Iteriert über die Child-Elemente eines Abschnitts der Ebene 3.

\PL*/

parser_subsubsec_rep(In, Out) -->
    parser_subsubsec_child(In, Out_1),
    parser_subsubsec_rep(Out_1, Out).

parser_subsubsec_rep(In, Out) -->
    parser_subsubsec_child(In, Out).

/*PL

\Predicate parser_subsubsec_child/2(+In, -Out).

Regel für alle Elemente, die Child-Elemente von \verb|subsubsec| sein können.

\PL*/

parser_subsubsec_child(In, Out) -->
    (
        parser_enum(In, Out);
        parser_list(In, Out);
        parser_pre(In, Out);
        parser_table(In, Out);
        parser_para(In, Out);
        parser_linebreak(In, Out)
    ).

/*PL

\Predicate parser_subsubsec_heading/2(+In, -Out).

Regel für eine Überschrift der Ebene 3. Diese besteht aus einer Textzeile,
die mit Gleich-Symbolen (=) unterstrichen ist.

\PL*/

parser_subsubsec_heading(In, Out) -->
    parser_cdata(T),
    [ sym_single_ul ],
    {
        parser_append_child(In, heading(T), Out)
    }.

/*PL

\Predicate parser_image/2(+In, -Out).

Regel für ein eingefügtes Bild-Element. Dieses besteht aus dem Dateinamen des
Bildes, welcher in \verb|<<| und \verb|>>| eingeschlossen ist.

\PL*/

parser_image(In, Out) -->
    [ sym_begin_include ],
    parser_filename(image, Out_1),
    [ sym_end_include ],
    {
        parser_append_child(In, Out_1, Out)
    }.

/*PL

\Predicate parser_filename/2(+In, -Out).

Regel für einen Dateinamen. Diese bestehen einfach aus Text.

\PL*/

parser_filename(In, Out) -->
    parser_cdata(T),
    {
        parser_append_child(In, filename(T), Out)
    }.

/*PL

\Predicate parser_para/2(+In, -Out).

Regel für einen Absatz. Ein Absatz ist für den Parser zunächst einfach ein
zusammenhängender Textblock. Email-Adressen und URLs werden später im
Postprocessing-Schritt extrahiert.

\PL*/

parser_para(In, Out) -->
    parser_text(para, Out_1),
    {
        parser_append_child(In, Out_1, Out)
    }.

/*PL

\Predicate parser_linebreak/2(+In, -In).

Regel für einen Zeilenumbruch.

\PL*/

parser_linebreak(In, In) -->
    [ sym_break ].

/*PL

\Predicate parser_enum/2(+In, -Out).

Regel für eine Aufzählung.

\PL*/

parser_enum(In, Out) -->
    parser_enum_rep(enum, Out_1),
    {
        parser_append_child(In, Out_1, Out)
    }.

/*PL

\Predicate parser_enum_rep/2(+In, -Out).

Iteriert über die Child-Elemente (\verb|enumitem|) einer Aufzählung.

\PL*/

parser_enum_rep(In, Out) -->
    parser_enumitem(In, Out_1),
    parser_enum_rep(Out_1, Out).

parser_enum_rep(In, Out) -->
    parser_enumitem(In, Out).

/*PL

\Predicate parser_enumitem/2(+In, -Out).

Regel für einen Punkt einer Aufzählung. Er besteht aus dem
Nummerierungs-Symbol (\#) und dem nachfolgenden Text.

\PL*/

parser_enumitem(In, Out) -->
    [ sym_enum_bullet ],
    parser_text(enumitem, Out_1),
    {
        parser_append_child(In, Out_1, Out)
    }.

/*PL

\Predicate parser_table/2(+In, -Out).

Regel für eine Tabelle. Eine Tabelle kann optional eine Titelzeile
(\verb|tablehdrow|) besitzen.

\PL*/

parser_table(In, Out) -->
    parser_tablehdrow(table, Out_1),
    parser_table_rep(Out_1, Out_2),
    {
        parser_append_child(In, Out_2, Out)
    }.

parser_table(In, Out) -->
    parser_table_rep(table, Out_1),
    {
        parser_append_child(In, Out_1, Out)
    }.

/*PL

\Predicate parser_table_rep/2(+In, -Out).

Iteriert über die Zeilen einer Tabelle. Die einzelnen Zeilen werden mit
Minuszeichen getrennt.

\textbf{Beachte:} Zur Zeit werden nur Listen richtig erkannt, deren Zeilen
in der Textdatei innerhalb einer Zeile stehen.


\PL*/

parser_table_rep(In, Out) -->
    parser_tablerow(In, Out_1),
    [ sym_single_ul ],
    parser_table_rep(Out_1, Out).

parser_table_rep(In, Out) -->
    parser_tablerow(In, Out).

/*PL

\Predicate parser_tablehdrow/2(+In, -Out).

Regel für die Titelzeile einer Tabelle. Diese besteht aus einer mit
Gleich-Zeichen unterstrichenen Tabellenzeile.

\PL*/

parser_tablehdrow(In, Out) -->
    parser_tablehdrow_rep(tablehdrow, Out_1),
    [ sym_double_ul ],
    {
        parser_append_child(In, Out_1, Out)
    }.

/*PL

\Predicate parser_tablehdrow_rep/2(+In, -Out).

Iteriert über die Elemente einer Tabellen-Titelzeile.

\PL*/

parser_tablehdrow_rep(In, Out) -->
    parser_tablehditem(In, Out_1),
    [ sym_col_separator ],
    parser_tablehdrow_rep(Out_1, Out).

parser_tablehdrow_rep(In, Out) -->
    parser_tablehditem(In, Out_1),
    [ sym_col_separator ],
    parser_tablehditem(Out_1, Out).

/*PL

\Predicate parser_tablerow/2(+In, -Out).

Regel für eine Tabellenzeile.

\PL*/

parser_tablerow(In, Out) -->
    parser_tablerow_rep(tablerow, Out_1),
    {
        parser_append_child(In, Out_1, Out)
    }.

/*PL

\Predicate parser_tablerow_rep/2(+In, -Out).

Iteriert über die Elemente einer Tabellenzeile. Die einzelnen Elemente sind
mit dem Spaltentrenn-Symbol \verb/|/ getrennt.

\PL*/

parser_tablerow_rep(In, Out) -->
    parser_tableitem(In, Out_1),
    [ sym_col_separator ],
    parser_tablerow_rep(Out_1, Out).

parser_tablerow_rep(In, Out) -->
    parser_tableitem(In, Out_1),
    [ sym_col_separator ],
    parser_tableitem(Out_1, Out).

/*PL

\Predicate parser_tablehditem/2(+In, -Out).

Regel für ein Element einer Tabellen-Titelzeile.

\PL*/

parser_tablehditem(In, Out) -->
    parser_tableitem_rep(tablehditem, Out_1),
    {
        parser_append_child(In, Out_1, Out)
    }.

/*PL

\Predicate parser_tableitem/2(+In, -Out).

Regel für ein Element einer Tabellenzeile.

\PL*/

parser_tableitem(In, Out) -->
    parser_tableitem_rep(tableitem, Out_1),
    {
        parser_append_child(In, Out_1, Out)
    }.

/*PL

\Predicate parser_tableitem_rep/2(+In, -Out).

Iteriert über den Text eines Elements einer Tabellenzeile.

\PL*/

parser_tableitem_rep(In, Out) -->
    parser_text(In, Out_1),
    parser_tableitem_rep(Out_1, Out).

parser_tableitem_rep(In, Out) -->
    parser_text(In, Out).

/*PL

\Predicate parser_list/2(+In, -Out).

Regel für eine Liste.

\PL*/

parser_list(In, Out) -->
    parser_list_rep(list, Out_1),
    {
        parser_append_child(In, Out_1, Out)
    }.

/*PL

\Predicate parser_list_rep/2(+In, -Out).

Iteriert über die Child-Elemente (\verb|listitem|) einer Liste.

\PL*/

parser_list_rep(In, Out) -->
    parser_listitem(In, Out_1),
    parser_list_rep(Out_1, Out).

parser_list_rep(In, Out) -->
    parser_listitem(In, Out).

/*PL

\Predicate parser_listitem/2(+In, -Out).

Regel für ein Listenelement. Dieses besteht aus dem Anstrich (-) und dem
nachfolgenden Text.

\PL*/

parser_listitem(In, Out) -->
    [ sym_list_bullet ],
    parser_text(listitem, Out_1),
    {
        parser_append_child(In, Out_1, Out)
    }.

/*PL

\Predicate parser_pre/2(+In, -Out).

Regel für vorformatierten Text. Drei aufeinanderfolgende Anführungszeichen
beginnen oder beenden den Preformat-Modus. Der Text dazwischen bleibt mit
seiner Formatierung, also mit allen Einrückungen erhalten und es findet
keine Interpretation statt, bis der Preformat-Modus wieder beendet wird.

\PL*/

parser_pre(In, Out) -->
    [ sym_pre ],
    parser_cdata(T),
    [ sym_pre ],
    {
        parser_append_child(In, pre(T), Out)
    }.

/*PL

\Predicate parser_text/2(+In, -Out).

Regel für Text.

\PL*/

parser_text(In, Out) -->
    parser_cdata(T),
    {
        parser_append_child(In, text(T), Out)
    }.

/*PL

\Predicate parser_cdata/2(-T).

Regel für aufeinanderfolgende Textsymbole. Die Textsymbole werden zusammengefaßt
und der Text in \verb|T| zurückgegeben. Zeilenende-Zeichen im Text bleiben
erhalten, eventuelle Einrückungen am Zeilenanfang werden überlesen.

\PL*/

parser_cdata(T) -->
    parser_indent_opt,
    [ sym_text(T1) ],
    parser_cdata(T2), !,
    {
        string_concat(T1, T2, T)
    }.

parser_cdata(T) -->
    parser_indent_opt,
    [ sym_text(T) ].

/*PL

\Predicate parser_indent_opt/0().

Regel für optionale Einrückungen.

\PL*/

parser_indent_opt -->
    [ sym_indent ].

parser_indent_opt -->
    [ ].

/*PL

\Predicate parser_email/1(-Email).

Regel für eine Email-Adresse. Diese bestehen aus Benutzernamen, dem @-Symbol,
Server- und Domainnamen. Die Adresse wird in \verb|Email| zurückgeliefert.

\PL*/

parser_email(Email) -->
    parser_username(User), [ '@' ],
    parser_servername(Server), [ '.' ],
    parser_domainname(Domain),
    {
        string_concat(User, '@', E1),
        string_concat(E1, Server, E2),
        string_concat(E2, '.', E3),
        string_concat(E3, Domain, Email)
    }.

/*PL

\Predicate parser_url/1(-Url).

Regel für URLs. Diese bestehen aus der Bezeichnung des Dienstes
(http, ftp oder file), Server- und Verzeichnisnamen. Die URL wird in
\verb|Url| zurückgeliefert.

\PL*/

parser_url(Url) -->
    parser_servicename(Service),
    [ ':' ], [ '/' ], [ '/' ],
    parser_servername(Server),
    ( parser_dirname(Dir) ; true ),
    {
        string_concat(Service, '://', Url_1),
        string_concat(Url_1, Server, Url_2),
        string_concat(Url_2, Dir, Url)
    }.

/*PL

\Predicate parser_servicename/1(-Service).

Regel für einen URL-Dienstnamen. Dieser kann entweder http, ftp oder file sein.
Der Bezeichner wird in \verb|Service| zurückgeliefert.

\PL*/

parser_servicename(Service) -->
    parser_dirname(Service),
    {
        (
            sub_string(Service, 0, _, 0, 'http');
            sub_string(Service, 0, _, 0, 'ftp');
            sub_string(Service, 0, _, 0, 'file')
        )
    }.

/*PL

\Predicate parser_dirname/1(-Dir).

Regel für einen Verzeichnisnamen. Der Name wird in \verb|Dir| zurückgeliefert.

\PL*/

parser_dirname(Dir) -->
    parser_dirname_rep('', Dir).

/*PL

\Predicate parser_dirname_rep/2(+Name_In, -Name_Out).

Iteriert über die einzelnen Zeichen eines Verzeichnisnamens. Der aktuelle
Name wird in \verb|Name_In| übergeben, der neue Name (alter Name + nächstes
Zeichen) wird in \verb|Name_Out| zurückgeliefert.

\PL*/

parser_dirname_rep(Name_In, Name_Out) -->
    [ C ],
    {
        \+char_type(C, space), C \= ',',  C \= ';',
        string_concat(Name_In, C, Name_Out_1)
    },
    parser_dirname_rep(Name_Out_1, Name_Out).

parser_dirname_rep(Name_In, Name_Out) -->
    [ C ],
    {
        \+char_type(C, space), C \= ',',  C \= ';',
        string_concat(Name_In, C, Name_Out)
    }.

/*PL

\Predicate parser_domainname/1(-Domain).

Regel für einen Domainnamen. Der Name wird in \verb|Domain| zurückgeliefert.

\PL*/

parser_domainname(Domain) -->
    parser_servername_rep('', Domain).

/*PL

\Predicate parser_servername/1(-Server).

Regel für einen Servernamen. Der Name wird in \verb|Server| zurückgeliefert.

\PL*/

parser_servername(Server) -->
    parser_server_rep('', Server).

/*PL

\Predicate parser_server_rep/2(+Server_In, -Server_Out).

Iteriert über die Bestandteile eines Servernamens. Die einzelnen Teile werden
mit Punktsymbolen (.) getrennt.

\PL*/

parser_server_rep(Server_In, Server_Out) -->
    parser_servername_rep(Server_In, Server_Out_1),
    [ '.' ],
    {
        string_concat(Server_Out_1, '.', Server_Out_2)
    },
    parser_server_rep(Server_Out_2, Server_Out).

parser_server_rep(Server_In, Server_Out) -->
    parser_servername_rep(Server_In, Server_Out).

/*PL

\Predicate parser_servername_rep/2(+Name_In, -Name_Out).

Iteriert über die einzelnen Zeichen eines Server- oder Domainnamens. Der
aktuelle Name wird in \verb|Name_In| übergeben, der neue Name (alter Name +
nächstes Zeichen) wird in \verb|Name_Out| zurückgeliefert.

\PL*/

parser_servername_rep(Name_In, Name_Out) -->
    [ C ],
    {
        ( char_type(C, alnum) ; C = '_' ; C = '-'),
        string_concat(Name_In, C, Name_Out_1)
    },
    parser_servername_rep(Name_Out_1, Name_Out).

parser_servername_rep(Name_In, Name_Out) -->
    [ C ],
    {
        ( char_type(C, alnum) ; C = '_' ; C = '-'),
        string_concat(Name_In, C, Name_Out)
    }.

/*PL

\Predicate parser_username/1(-User).

Regel für einen Benutzernamen. Der Name wird in \verb|User| zurückgeliefert.

\PL*/

parser_username(User) -->
    parser_username_rep('', User).

/*PL

\Predicate parser_username_rep/2(+Name_In, -Name_Out).

Iteriert über die einzelnen Zeichen eines Benutzernamens. Der aktuelle
Name wird in \verb|Name_In| übergeben, der neue Name (alter Name + nächstes
Zeichen) wird in \verb|Name_Out| zurückgeliefert.

\PL*/

parser_username_rep(Name_In, Name_Out) -->
    [ C ],
    {
        ( char_type(C, alnum) ; C = '.' ; C = '_' ; C = '-'),
        string_concat(Name_In, C, Name_Out_1)
    },
    parser_username_rep(Name_Out_1, Name_Out).

parser_username_rep(Name_In, Name_Out) -->
    [ C ],
    {
        ( char_type(C, alnum) ; C = '.' ; C = '_' ; C = '-'),
        string_concat(Name_In, C, Name_Out)
    }.

/*PL
\EndProlog
*/
