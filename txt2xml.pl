txt2xml(Txt_Filename, Xml_Filename) :-

    ensure_loaded(dl),
    ensure_loaded(string),
    ensure_loaded(scanner),
    ensure_loaded(parser),
    ensure_loaded(genxml),

    write('Scanning text file   '), flush_output,
    scanner(Txt_Filename, Sym_List),
    write('OK'), nl,

    write('Parsing text file    '), flush_output,
    parser(Sym_List, Doc),
    write('OK'), nl,

    write('Writing XML output   '), flush_output,
    open(Xml_Filename, write, S),
    genxml_write_dtd(S),
    genxml_write_doc(S, Doc),
    close(S),
    write('OK'), nl.
