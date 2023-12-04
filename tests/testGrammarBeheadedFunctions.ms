import "qa"

//
if not globals.hasIndex("ms") then
	import "ms"
	globals.ms = ms
end if
//


_NL = ms._NL


testBeheadedFunctions = function
	//
	arg = ms._makeParseArg
	arg.features.beheadedFunctions = false
	//
	
	res = ms.grammar.parse( "A"                 + char(10) +
	                        "B = [function()]"  + char(10) +
	                        " C"                + char(10) +
	                        "end function"      + char(10) +
	                        "D",
	                        0, arg)
	qa.assertEqual res.hasErrorTag("couldNotParseEverything"), true
	
	//
	arg = ms._makeParseArg
	arg.features.beheadedFunctions = true
	//
	
	res = ms.grammar.parse( "A"                 + char(10) +
	                        "B = [function()]"  + char(10) +
	                        " C"                + char(10) +
	                        "end function"      + char(10) +
	                        "D",
	                        0, arg)
	qa.assertEqual ms.str(res.capture),     "[Program 1:1 5:1]"                         + _NL +
	                                        " file:"                                    + _NL +
	                                        " shebang:"                                 + _NL +
	                                        " statements.0"                             + _NL +
	                                        "  [StmtCall 1:1 1:1]"                      + _NL +
	                                        "   callable:"                              + _NL +
	                                        "    [Identifier 1:1 1:1] name = ""A"""         + _NL +
	                                        "   args.--"                                + _NL +
	                                        " statements.1"                             + _NL +
	                                        "  [StmtAssign 2:1 2:16] math = """""           + _NL +
	                                        "   left:"                                  + _NL +
	                                        "    [Identifier 2:1 2:1] name = ""B"""         + _NL +
	                                        "   right:"                                 + _NL +
	                                        "    [LitList 2:5 2:16]"                    + _NL +
	                                        "     elements.0"                           + _NL +
	                                        "      [LitFunction 2:6 4:12]"              + _NL +
	                                        "       args.--"                            + _NL +
	                                        "       defaults.--"                        + _NL +
	                                        "       statements.0"                       + _NL +
	                                        "        [StmtCall 3:2 3:2]"                + _NL +
	                                        "         callable:"                        + _NL +
	                                        "          [Identifier 3:2 3:2] name = ""C"""   + _NL +
	                                        "         args.--"                          + _NL +
	                                        " statements.2"                             + _NL +
	                                        "  [StmtCall 5:1 5:1]"                      + _NL +
	                                        "   callable:"                              + _NL +
	                                        "    [Identifier 5:1 5:1] name = ""D"""         + _NL +
	                                        "   args.--"
	
	//
	arg = ms._makeParseArg
	arg.features.beheadedFunctions = true
	//
	
	res = ms.grammar.parse( "A"                     + char(10) +
	                        "B = [function(C)]"     + char(10) +
	                        " D"                    + char(10) +
	                        " E function(F, G), H"  + char(10) +
	                        "  I"                   + char(10) +
	                        " end function"         + char(10) +
	                        " J"                    + char(10) +
	                        "end function"          + char(10) +
	                        "K",
	                        0, arg)
	qa.assertEqual ms.str(res.capture),     "[Program 1:1 9:1]"                             + _NL +
	                                        " file:"                                        + _NL +
	                                        " shebang:"                                     + _NL +
	                                        " statements.0"                                 + _NL +
	                                        "  [StmtCall 1:1 1:1]"                          + _NL +
	                                        "   callable:"                                  + _NL +
	                                        "    [Identifier 1:1 1:1] name = ""A"""             + _NL +
	                                        "   args.--"                                    + _NL +
	                                        " statements.1"                                 + _NL +
	                                        "  [StmtAssign 2:1 2:17] math = """""               + _NL +
	                                        "   left:"                                      + _NL +
	                                        "    [Identifier 2:1 2:1] name = ""B"""             + _NL +
	                                        "   right:"                                     + _NL +
	                                        "    [LitList 2:5 2:17]"                        + _NL +
	                                        "     elements.0"                               + _NL +
	                                        "      [LitFunction 2:6 8:12]"                  + _NL +
	                                        "       args.0"                                 + _NL +
	                                        "        ""C"""                                     + _NL +
	                                        "       defaults.0"                             + _NL +
	                                        "        null"                                  + _NL +
	                                        "       statements.0"                           + _NL +
	                                        "        [StmtCall 3:2 3:2]"                    + _NL +
	                                        "         callable:"                            + _NL +
	                                        "          [Identifier 3:2 3:2] name = ""D"""       + _NL +
	                                        "         args.--"                              + _NL +
	                                        "       statements.1"                           + _NL +
	                                        "        [StmtCall 4:2 4:20]"                   + _NL +
	                                        "         callable:"                            + _NL +
	                                        "          [Identifier 4:2 4:2] name = ""E"""       + _NL +
	                                        "         args.0"                               + _NL +
	                                        "          [LitFunction 4:4 6:13]"              + _NL +
	                                        "           args.0"                             + _NL +
	                                        "            ""F"""                                 + _NL +
	                                        "           args.1"                             + _NL +
	                                        "            ""G"""                                 + _NL +
	                                        "           defaults.0"                         + _NL +
	                                        "            null"                              + _NL +
	                                        "           defaults.1"                         + _NL +
	                                        "            null"                              + _NL +
	                                        "           statements.0"                       + _NL +
	                                        "            [StmtCall 5:3 5:3]"                + _NL +
	                                        "             callable:"                        + _NL +
	                                        "              [Identifier 5:3 5:3] name = ""I"""   + _NL +
	                                        "             args.--"                          + _NL +
	                                        "         args.1"                               + _NL +
	                                        "          [Identifier 4:20 4:20] name = ""H"""     + _NL +
	                                        "       statements.2"                           + _NL +
	                                        "        [StmtCall 7:2 7:2]"                    + _NL +
	                                        "         callable:"                            + _NL +
	                                        "          [Identifier 7:2 7:2] name = ""J"""       + _NL +
	                                        "         args.--"                              + _NL +
	                                        " statements.2"                                 + _NL +
	                                        "  [StmtCall 9:1 9:1]"                          + _NL +
	                                        "   callable:"                                  + _NL +
	                                        "    [Identifier 9:1 9:1] name = ""K"""             + _NL +
	                                        "   args.--"
	
	//
	arg = ms._makeParseArg
	arg.features.beheadedFunctions = true
	//
	
	res = ms.grammar.parse( "X function(), function()", 0, arg)
	qa.assertEqual res.hasErrorTag("cannotStartTwoFunctions"), true
end function

