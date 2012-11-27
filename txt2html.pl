txt2html(Txt_Filename, Html_Filename) :-

    ensure_loaded(dl),
    ensure_loaded(string),
    ensure_loaded(scanner),
    ensure_loaded(parser),
    ensure_loaded(genhtml),

    write('Scanning text file   '), flush_output,
    scanner(Txt_Filename, Sym_List),
    write('OK'), nl,

    write('Parsing text file    '), flush_output,
    parser(Sym_List, Doc),
    write('OK'), nl,

    write('Writing HTML output  '), flush_output,
    open(Html_Filename, write, S),
    genhtml_write_header(S),
    genhtml_write_doc(S, Doc),
    close(S),
    write('OK'), nl.
