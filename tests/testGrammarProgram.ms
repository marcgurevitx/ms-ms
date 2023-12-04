import "qa"

//
if not globals.hasIndex("ms") then
	import "ms"
	globals.ms = ms
end if
//


_NL = ms._NL


testParseProgram = function
	//
	arg = ms._makeParseArg
	//
	
	res = ms.grammar.parse("", 0, arg)
	qa.assertEqual ms.str(res.capture),     "[Program 1:0 1:0]"                     + _NL +
	                                        " file:"                                + _NL +
	                                        " shebang:"                             + _NL +
	                                        " statements.0"                         + _NL +
	                                        "  [StmtEmpty 1:0 1:0]"
	
	res = ms.grammar.parse(" ", 0, arg)
	qa.assertEqual ms.str(res.capture),     "[Program 1:1 1:1]"                     + _NL +
	                                        " file:"                                + _NL +
	                                        " shebang:"                             + _NL +
	                                        " statements.0"                         + _NL +
	                                        "  [StmtEmpty 1:1 1:1]"
	
	res = ms.grammar.parse("X ", 0, arg)
	qa.assertEqual ms.str(res.capture),     "[Program 1:1 1:1]"                     + _NL +
	                                        " file:"                                + _NL +
	                                        " shebang:"                             + _NL +
	                                        " statements.0"                         + _NL +
	                                        "  [StmtCall 1:1 1:1]"                  + _NL +
	                                        "   callable:"                          + _NL +
	                                        "    [Identifier 1:1 1:1] name = ""X"""     + _NL +
	                                        "   args.--"
	
	res = ms.grammar.parse("X ; Y ", 0, arg)
	qa.assertEqual ms.str(res.capture),     "[Program 1:1 1:5]"                     + _NL +
	                                        " file:"                                + _NL +
	                                        " shebang:"                             + _NL +
	                                        " statements.0"                         + _NL +
	                                        "  [StmtCall 1:1 1:1]"                  + _NL +
	                                        "   callable:"                          + _NL +
	                                        "    [Identifier 1:1 1:1] name = ""X"""     + _NL +
	                                        "   args.--"                            + _NL +
	                                        " statements.1"                         + _NL +
	                                        "  [StmtCall 1:5 1:5]"                  + _NL +
	                                        "   callable:"                          + _NL +
	                                        "    [Identifier 1:5 1:5] name = ""Y"""     + _NL +
	                                        "   args.--"
	
	res = ms.grammar.parse( "   //hello" + char(10) +
	                        " X//hi" + char(10) +
	                        "" + char(10) +
	                        "     Y " + char(10) +
	                        "//bye",
	                        0, arg)
	qa.assertEqual ms.str(res.capture),     "[Program 1:1 5:5]"                     + _NL +
	                                        " file:"                                + _NL +
	                                        " shebang:"                             + _NL +
	                                        " statements.0"                         + _NL +
	                                        "  [StmtEmpty 1:4 1:4]"                 + _NL +
	                                        " statements.1"                         + _NL +
	                                        "  [StmtCall 2:2 2:2]"                  + _NL +
	                                        "   callable:"                          + _NL +
	                                        "    [Identifier 2:2 2:2] name = ""X"""     + _NL +
	                                        "   args.--"                            + _NL +
	                                        " statements.2"                         + _NL +
	                                        "  [StmtEmpty 3:1 3:1]"                 + _NL +
	                                        " statements.3"                         + _NL +
	                                        "  [StmtCall 4:6 4:6]"                  + _NL +
	                                        "   callable:"                          + _NL +
	                                        "    [Identifier 4:6 4:6] name = ""Y"""     + _NL +
	                                        "   args.--"                            + _NL +
	                                        " statements.4"                         + _NL +
	                                        "  [StmtEmpty 5:1 5:1]"
	
	res = ms.grammar.parse("$", 0, arg)
	qa.assertEqual res.hasErrorTag("couldNotParseEverything"), true
end function


testParseShebang = function
	//
	arg = ms._makeParseArg
	//
	
	res = ms.grammar.parse("#! /foo/bar" + char(13) + "X", 0, arg)
	qa.assertEqual res.hasErrorTag("couldNotParseEverything"), true
	
	//
	arg = ms._makeParseArg({"parseShebang": true})
	//
	
	res = ms.grammar.parse("#! /foo/bar baz" + char(13) + "X", 0, arg)
	qa.assertEqual ms.str(res.capture),     "[Program 1:1 2:1]"                     + _NL +
	                                        " file:"                                + _NL +
	                                        " shebang:"                             + _NL +
	                                        "  "" /foo/bar baz"""                       + _NL +
	                                        " statements.0"                         + _NL +
	                                        "  [StmtCall 2:1 2:1]"                  + _NL +
	                                        "   callable:"                          + _NL +
	                                        "    [Identifier 2:1 2:1] name = ""X"""     + _NL +
	                                        "   args.--"
end function

