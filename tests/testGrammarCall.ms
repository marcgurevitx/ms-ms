import "qa"

//
if not globals.hasIndex("ms") then
	import "ms"
	globals.ms = ms
end if
//


_NL = ms._NL


testCallWithParens = function
	res = ms.grammar.parse("A B (C, D) ", 0, ms._makeParseArg)
	qa.assertEqual ms.str(res.capture),     "[Program 1:1 1:10]"                    + _NL +
	                                        " file:"                                + _NL +
	                                        " shebang:"                             + _NL +
	                                        " statements.0"                         + _NL +
	                                        "  [StmtCall 1:1 1:10]"                 + _NL +
	                                        "   callable:"                          + _NL +
	                                        "    [Identifier 1:1 1:1] name = ""A"""     + _NL +
	                                        "   args.0"                             + _NL +
	                                        "    [OpCall 1:3 1:10]"                 + _NL +
	                                        "     operands.0"                       + _NL +
	                                        "      [Identifier 1:3 1:3] name = ""B"""   + _NL +
	                                        "     args.0"                           + _NL +
	                                        "      [Identifier 1:6 1:6] name = ""C"""   + _NL +
	                                        "     args.1"                           + _NL +
	                                        "      [Identifier 1:9 1:9] name = ""D"""
	
	res = ms.grammar.parse("A (B, C) ", 0, ms._makeParseArg)
	qa.assertEqual res.capture, null
	qa.assertEqual res.errors.len > 0, true
	
	res = ms.grammar.parse("A (B) * C ", 0, ms._makeParseArg)
	qa.assertEqual ms.str(res.capture),     "[Program 1:1 1:9]"                     + _NL +
	                                        " file:"                                + _NL +
	                                        " shebang:"                             + _NL +
	                                        " statements.0"                         + _NL +
	                                        "  [StmtCall 1:1 1:9]"                  + _NL +
	                                        "   callable:"                          + _NL +
	                                        "    [Identifier 1:1 1:1] name = ""A"""     + _NL +
	                                        "   args.0"                             + _NL +
	                                        "    [OpMultiply 1:3 1:9]"              + _NL +
	                                        "     operands.0"                       + _NL +
	                                        "      [Identifier 1:3 1:5] name = ""B"""   + _NL +
	                                        "     operands.1"                       + _NL +
	                                        "      [Identifier 1:9 1:9] name = ""C"""
	
	res = ms.grammar.parse("A(B) * C ", 0, ms._makeParseArg)
	qa.assertEqual ms.str(res.capture),     "[Program 1:1 1:8]"                     + _NL +
	                                        " file:"                                + _NL +
	                                        " shebang:"                             + _NL +
	                                        " statements.0"                         + _NL +
	                                        "  [StmtCall 1:1 1:8]"                  + _NL +
	                                        "   callable:"                          + _NL +
	                                        "    [OpMultiply 1:1 1:8]"              + _NL +
	                                        "     operands.0"                       + _NL +
	                                        "      [OpCall 1:1 1:4]"                + _NL +
	                                        "       operands.0"                     + _NL +
	                                        "        [Identifier 1:1 1:1] name = ""A""" + _NL +
	                                        "       args.0"                         + _NL +
	                                        "        [Identifier 1:3 1:3] name = ""B""" + _NL +
	                                        "     operands.1"                       + _NL +
	                                        "      [Identifier 1:8 1:8] name = ""C"""   + _NL +
	                                        "   args.--"
end function
