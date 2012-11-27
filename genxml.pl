/*

\Predicate genxml_write_dtd/1(+S).

Schreibt unsere Document Type Definition (DTD) in den Stream \verb|S|.

\PL*/

genxml_write_dtd(S) :-
    write(S, '<?xml version="1.0"?>'), nl(S),
    write(S, '<!DOCTYPE doc ['), nl(S),
    write(S, '<!ELEMENT doc (title|sec|subsec|subsubsec|para|pre|'),
    write(S, 'table|list|enum|image)*>'), nl(S),
    write(S, '<!ELEMENT sec (heading, (subsec|subsubsec|para|pre|'),
    write(S, 'table|list|enum|image)*)>'), nl(S),
    write(S, '<!ELEMENT subsec (heading, (subsubsec|para|pre|table|'),
    write(S, 'list|enum|image)*)>'), nl(S),
    write(S, '<!ELEMENT subsubsec (heading, (para|pre|table|list|'),
    write(S, 'enum|image)*)>'), nl(S),
    write(S, '<!ELEMENT para (text|url|email)*>'), nl(S),
    write(S, '<!ELEMENT title (#PCDATA)>'), nl(S),
    write(S, '<!ELEMENT heading (#PCDATA)>'), nl(S),
    write(S, '<!ELEMENT text (#PCDATA)>'), nl(S),
    write(S, '<!ELEMENT pre (#PCDATA)>'), nl(S),
    write(S, '<!ELEMENT url (#PCDATA)>'), nl(S),
    write(S, '<!ELEMENT email (#PCDATA)>'), nl(S),
    write(S, '<!ELEMENT table (tablehdrow?, tablerow+)>'), nl(S),
    write(S, '<!ELEMENT tablerow (tableitem, tableitem+)>'), nl(S),
    write(S, '<!ELEMENT tablehdrow (tablehditem, tablehditem+)>'), nl(S),
    write(S, '<!ELEMENT tableitem (text|url|email)*>'), nl(S),
    write(S, '<!ELEMENT tablehditem (text|url|email)*>'), nl(S),
    write(S, '<!ELEMENT list (listitem)+>'), nl(S),
    write(S, '<!ELEMENT listitem (text|url|email)*>'), nl(S),
    write(S, '<!ELEMENT enum (enumitem)+>'), nl(S),
    write(S, '<!ELEMENT enumitem (text|url|email)*>'), nl(S),
    write(S, '<!ELEMENT image (filename)>'), nl(S),
    write(S, '<!ELEMENT filename (#PCDATA)>'), nl(S),
    write(S, ']>'), nl(S).

/*PL

\Predicate genxml_replace_xml_chars/2(+Text_In, -Text_Out).

Ersetzt die in \verb|Text_In| auftretenden für XML reservierten Zeichen
durch die vordefinierten Entity-Referenzen und gibt das Ergebnis in
\verb|Text_Out| zurück.

\PL*/

genxml_replace_xml_chars(Text_In, Text_Out) :-
    string_replace_all(Text_In, '&',  '&amp;',  Text_1),
    string_replace_all(Text_1,  '<',  '&lt;',   Text_2),
    string_replace_all(Text_2,  '>',  '&gt;',   Text_3),
    string_replace_all(Text_3,  '\'', '&apos;', Text_4),
    string_replace_all(Text_4,  '"',  '&quot;', Text_Out).

/*PL

\Predicate genxml_write_element/3(+S, +Element, +Child_List).

Schreibt das Dokumentenelement \verb|Element| in den Stream \verb|S|. Dieses
Prädikat schreibt rekursiv alle Child-Elemente von \verb|Element|, welche in
\verb|Child_List| übergeben werden müssen.

\PL*/

genxml_write_element(S, filename, [Text]) :-
    write(S, '<filename>'),
    genxml_replace_xml_chars(Text, XML_Text),
    write(S, XML_Text),
    write(S, '</filename>'), nl(S).

genxml_write_element(S, email, [Text]) :-
    write(S, '<email>'),
    genxml_replace_xml_chars(Text, XML_Text),
    write(S, XML_Text),
    write(S, '</email>'), nl(S).

genxml_write_element(S, url, [Text]) :-
    write(S, '<url>'),
    genxml_replace_xml_chars(Text, XML_Text),
    write(S, XML_Text),
    write(S, '</url>'), nl(S).

genxml_write_element(S, pre, [Text]) :-
    write(S, '<pre>'),
    genxml_replace_xml_chars(Text, XML_Text),
    write(S, XML_Text),
    write(S, '</pre>'), nl(S).

genxml_write_element(S, text, [Text]) :-
    write(S, '<text>'),
    genxml_replace_xml_chars(Text, XML_Text),
    write(S, XML_Text),
    write(S, '</text>'), nl(S).

genxml_write_element(S, heading, [Text]) :-
    write(S, '<heading>'),
    genxml_replace_xml_chars(Text, XML_Text),
    write(S, XML_Text),
    write(S, '</heading>'), nl(S).

genxml_write_element(S, title, [Text]) :-
    write(S, '<title>'),
    genxml_replace_xml_chars(Text, XML_Text),
    write(S, XML_Text),
    write(S, '</title>'), nl(S).

genxml_write_element(S, image, Child_List) :-
    write(S, '<image>'), nl(S),
    checklist(genxml_write_child_element(S), Child_List),
    write(S, '</image>'), nl(S).

genxml_write_element(S, enumitem, Child_List) :-
    write(S, '<enumitem>'), nl(S),
    checklist(genxml_write_child_element(S), Child_List),
    write(S, '</enumitem>'), nl(S).

genxml_write_element(S, enum, Child_List) :-
    write(S, '<enum>'), nl(S),
    checklist(genxml_write_child_element(S), Child_List),
    write(S, '</enum>'), nl(S).

genxml_write_element(S, listitem, Child_List) :-
    write(S, '<listitem>'), nl(S),
    checklist(genxml_write_child_element(S), Child_List),
    write(S, '</listitem>'), nl(S).

genxml_write_element(S, list, Child_List) :-
    write(S, '<list>'), nl(S),
    checklist(genxml_write_child_element(S), Child_List),
    write(S, '</list>'), nl(S).

genxml_write_element(S, tableitem, Child_List) :-
    write(S, '<tableitem>'), nl(S),
    checklist(genxml_write_child_element(S), Child_List),
    write(S, '</tableitem>'), nl(S).

genxml_write_element(S, tablehditem, Child_List) :-
    write(S, '<tablehditem>'), nl(S),
    checklist(genxml_write_child_element(S), Child_List),
    write(S, '</tablehditem>'), nl(S).

genxml_write_element(S, tablehdrow, Child_List) :-
    write(S, '<tablehdrow>'), nl(S),
    checklist(genxml_write_child_element(S), Child_List),
    write(S, '</tablehdrow>'), nl(S).

genxml_write_element(S, tablerow, Child_List) :-
    write(S, '<tablerow>'), nl(S),
    checklist(genxml_write_child_element(S), Child_List),
    write(S, '</tablerow>'), nl(S).

genxml_write_element(S, table, Child_List) :-
    write(S, '<table>'), nl(S),
    checklist(genxml_write_child_element(S), Child_List),
    write(S, '</table>'), nl(S).

genxml_write_element(S, para, Child_List) :-
    write(S, '<para>'), nl(S),
    checklist(genxml_write_child_element(S), Child_List),
    write(S, '</para>'), nl(S).

genxml_write_element(S, subsubsec, Child_List) :-
    write(S, '<subsubsec>'), nl(S),
    checklist(genxml_write_child_element(S), Child_List),
    write(S, '</subsubsec>'), nl(S).

genxml_write_element(S, subsec, Child_List) :-
    write(S, '<subsec>'), nl(S),
    checklist(genxml_write_child_element(S), Child_List),
    write(S, '</subsec>'), nl(S).

genxml_write_element(S, sec, Child_List) :-
    write(S, '<sec>'), nl(S),
    checklist(genxml_write_child_element(S), Child_List),
    write(S, '</sec>'), nl(S).

genxml_write_element(S, doc, Child_List) :-
    write(S, '<doc>'), nl(S),
    checklist(genxml_write_child_element(S), Child_List),
    write(S, '</doc>'), nl(S).

/*PL

\Predicate genxml_write_child_element/2(+S, +Child).

Schreibt das Child-Element \verb|Child| in den Stream \verb|S|.

\PL*/

genxml_write_child_element(S, Child) :-
    Child =.. [Element|Params],
    genxml_write_element(S, Element, Params).

/*PL

\Predicate genxml_write_doc/2(+S, +Doc).

Schreibt das Dokument \verb|Doc| in den Stream \verb|S|.

\PL*/

genxml_write_doc(S, Doc) :-
    Doc =.. [Element|Params],
    genxml_write_element(S, Element, Params).

/*PL
\EndProlog
*/