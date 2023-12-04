import "qa"

//
if not globals.hasIndex("ms") then
	import "ms"
	globals.ms = ms
end if
//


_NL = ms._NL


testEmptyStatement = function
	//
	arg = ms._makeParseArg
	//
	
	res = ms.grammar.parse(" ", 0, arg, "Statement")
	qa.assertEqual res.capture isa ms.StmtEmpty, true
	qa.assertEqual ms.str(res.capture),     "[StmtEmpty 1:1 1:1]"
end function


testSimplerStatement = function
	//
	arg = ms._makeParseArg
	//
	
	res = ms.grammar.parse("null", 0, arg, "Statement")
	qa.assertEqual ms.str(res.capture),     "[StmtCall 1:1 1:4]"                + _NL +
	                                        " callable:"                        + _NL +
	                                        "  [LitNull 1:1 1:4]"               + _NL +
	                                        " args.--"
	
	res = ms.grammar.parse("""hi""", 0, arg, "Statement")
	qa.assertEqual ms.str(res.capture),     "[StmtCall 1:1 1:4]"                + _NL +
	                                        " callable:"                        + _NL +
	                                        "  [LitString 1:1 1:4] text = ""hi"""   + _NL +
	                                        " args.--"
	
	res = ms.grammar.parse("foo", 0, arg, "Statement")
	qa.assertEqual ms.str(res.capture),     "[StmtCall 1:1 1:3]"                + _NL +
	                                        " callable:"                        + _NL +
	                                        "  [Identifier 1:1 1:3] name = ""foo""" + _NL +
	                                        " args.--"
	
	res = ms.grammar.parse("X[Y] and [A,B,C]", 0, arg, "Statement")
	qa.assertEqual ms.str(res.capture),     "[StmtCall 1:1 1:16]"                   + _NL +
	                                        " callable:"                            + _NL +
	                                        "  [OpAnd 1:1 1:16]"                    + _NL +
	                                        "   operands.0"                         + _NL +
	                                        "    [OpIndex 1:1 1:4]"                 + _NL +
	                                        "     operands.0"                       + _NL +
	                                        "      [Identifier 1:1 1:1] name = ""X"""   + _NL +
	                                        "     key:"                             + _NL +
	                                        "      [Identifier 1:3 1:3] name = ""Y"""   + _NL +
	                                        "   operands.1"                         + _NL +
	                                        "    [LitList 1:10 1:16]"               + _NL +
	                                        "     elements.0"                       + _NL +
	                                        "      [Identifier 1:11 1:11] name = ""A""" + _NL +
	                                        "     elements.1"                       + _NL +
	                                        "      [Identifier 1:13 1:13] name = ""B""" + _NL +
	                                        "     elements.2"                       + _NL +
	                                        "      [Identifier 1:15 1:15] name = ""C""" + _NL +
	                                        " args.--"
end function


testCallStatement = function
	//
	arg = ms._makeParseArg
	//
	
	res = ms.grammar.parse("X + X ", 0, arg, "Statement")
	qa.assertEqual ms.str(res.capture),     "[StmtCall 1:1 1:5]"                + _NL +
	                                        " callable:"                        + _NL +
	                                        "  [OpAdd 1:1 1:5]"                 + _NL +
	                                        "   operands.0"                     + _NL +
	                                        "    [Identifier 1:1 1:1] name = ""X""" + _NL +
	                                        "   operands.1"                     + _NL +
	                                        "    [Identifier 1:5 1:5] name = ""X""" + _NL +
	                                        " args.--"
	
	res = ms.grammar.parse("X Y ", 0, arg, "Statement")
	qa.assertEqual ms.str(res.capture),     "[StmtCall 1:1 1:3]"                + _NL +
	                                        " callable:"                        + _NL +
	                                        "  [Identifier 1:1 1:1] name = ""X"""   + _NL +
	                                        " args.0"                           + _NL +
	                                        "  [Identifier 1:3 1:3] name = ""Y"""
	
	res = ms.grammar.parse("X Y, Z ", 0, arg, "Statement")
	qa.assertEqual ms.str(res.capture),     "[StmtCall 1:1 1:6]"                + _NL +
	                                        " callable:"                        + _NL +
	                                        "  [Identifier 1:1 1:1] name = ""X"""   + _NL +
	                                        " args.0"                           + _NL +
	                                        "  [Identifier 1:3 1:3] name = ""Y"""   + _NL +
	                                        " args.1"                           + _NL +
	                                        "  [Identifier 1:6 1:6] name = ""Z"""
	
	res = ms.grammar.parse("X Y, " + char(13) + " Z ", 0, arg, "Statement")
	qa.assertEqual ms.str(res.capture),     "[StmtCall 1:1 2:2]"                + _NL +
	                                        " callable:"                        + _NL +
	                                        "  [Identifier 1:1 1:1] name = ""X"""   + _NL +
	                                        " args.0"                           + _NL +
	                                        "  [Identifier 1:3 1:3] name = ""Y"""   + _NL +
	                                        " args.1"                           + _NL +
	                                        "  [Identifier 2:2 2:2] name = ""Z"""
	
	res = ms.grammar.parse("X[Y] ", 0, arg, "Statement")
	qa.assertEqual ms.str(res.capture),     "[StmtCall 1:1 1:4]"                + _NL +
	                                        " callable:"                        + _NL +
	                                        "  [OpIndex 1:1 1:4]"               + _NL +
	                                        "   operands.0"                     + _NL +
	                                        "    [Identifier 1:1 1:1] name = ""X""" + _NL +
	                                        "   key:"                           + _NL +
	                                        "    [Identifier 1:3 1:3] name = ""Y""" + _NL +
	                                        " args.--"
	
	res = ms.grammar.parse("X [Y] ", 0, arg, "Statement")
	qa.assertEqual ms.str(res.capture),     "[StmtCall 1:1 1:5]"                + _NL +
	                                        " callable:"                        + _NL +
	                                        "  [Identifier 1:1 1:1] name = ""X"""   + _NL +
	                                        " args.0"                           + _NL +
	                                        "  [LitList 1:3 1:5]"               + _NL +
	                                        "   elements.0"                     + _NL +
	                                        "    [Identifier 1:4 1:4] name = ""Y"""
	
	res = ms.grammar.parse("X [Y], Z ", 0, arg, "Statement")
	qa.assertEqual ms.str(res.capture),     "[StmtCall 1:1 1:8]"                + _NL +
	                                        " callable:"                        + _NL +
	                                        "  [Identifier 1:1 1:1] name = ""X"""   + _NL +
	                                        " args.0"                           + _NL +
	                                        "  [LitList 1:3 1:5]"               + _NL +
	                                        "   elements.0"                     + _NL +
	                                        "    [Identifier 1:4 1:4] name = ""Y""" + _NL +
	                                        " args.1"                           + _NL +
	                                        "  [Identifier 1:8 1:8] name = ""Z"""
	
	res = ms.grammar.parse("X-Y ", 0, arg, "Statement")
	qa.assertEqual ms.str(res.capture),     "[StmtCall 1:1 1:3]"                + _NL +
	                                        " callable:"                        + _NL +
	                                        "  [OpSubtract 1:1 1:3]"            + _NL +
	                                        "   operands.0"                     + _NL +
	                                        "    [Identifier 1:1 1:1] name = ""X""" + _NL +
	                                        "   operands.1"                     + _NL +
	                                        "    [Identifier 1:3 1:3] name = ""Y""" + _NL +
	                                        " args.--"
	
	res = ms.grammar.parse("X- Y ", 0, arg, "Statement")
	qa.assertEqual ms.str(res.capture),     "[StmtCall 1:1 1:4]"                + _NL +
	                                        " callable:"                        + _NL +
	                                        "  [OpSubtract 1:1 1:4]"            + _NL +
	                                        "   operands.0"                     + _NL +
	                                        "    [Identifier 1:1 1:1] name = ""X""" + _NL +
	                                        "   operands.1"                     + _NL +
	                                        "    [Identifier 1:4 1:4] name = ""Y""" + _NL +
	                                        " args.--"
	
	res = ms.grammar.parse("X - Y ", 0, arg, "Statement")
	qa.assertEqual ms.str(res.capture),     "[StmtCall 1:1 1:5]"                + _NL +
	                                        " callable:"                        + _NL +
	                                        "  [OpSubtract 1:1 1:5]"            + _NL +
	                                        "   operands.0"                     + _NL +
	                                        "    [Identifier 1:1 1:1] name = ""X""" + _NL +
	                                        "   operands.1"                     + _NL +
	                                        "    [Identifier 1:5 1:5] name = ""Y""" + _NL +
	                                        " args.--"
	
	res = ms.grammar.parse("X -Y ", 0, arg, "Statement")
	qa.assertEqual ms.str(res.capture),     "[StmtCall 1:1 1:4]"                + _NL +
	                                        " callable:"                        + _NL +
	                                        "  [Identifier 1:1 1:1] name = ""X"""   + _NL +
	                                        " args.0"                           + _NL +
	                                        "  [OpUMinus 1:3 1:4]"              + _NL +
	                                        "   operands.0"                     + _NL +
	                                        "    [Identifier 1:4 1:4] name = ""Y"""
	
	res = ms.grammar.parse("X -Y + Z ", 0, arg, "Statement")
	qa.assertEqual ms.str(res.capture),     "[StmtCall 1:1 1:8]"                    + _NL +
	                                        " callable:"                            + _NL +
	                                        "  [Identifier 1:1 1:1] name = ""X"""       + _NL +
	                                        " args.0"                               + _NL +
	                                        "  [OpAdd 1:3 1:8]"                     + _NL +
	                                        "   operands.0"                         + _NL +
	                                        "    [OpUMinus 1:3 1:4]"                + _NL +
	                                        "     operands.0"                       + _NL +
	                                        "      [Identifier 1:4 1:4] name = ""Y"""   + _NL +
	                                        "   operands.1"                         + _NL +
	                                        "    [Identifier 1:8 1:8] name = ""Z"""
	
	res = ms.grammar.parse("X (Y) -Z ", 0, arg, "Statement")
	qa.assertEqual ms.str(res.capture),     "[StmtCall 1:1 1:8]"                + _NL +
	                                        " callable:"                        + _NL +
	                                        "  [Identifier 1:1 1:1] name = ""X"""   + _NL +
	                                        " args.0"                           + _NL +
	                                        "  [OpSubtract 1:3 1:8]"            + _NL +
	                                        "   operands.0"                     + _NL +
	                                        "    [Identifier 1:3 1:5] name = ""Y""" + _NL +
	                                        "   operands.1"                     + _NL +
	                                        "    [Identifier 1:8 1:8] name = ""Z"""
	
	res = ms.grammar.parse("X -Y, Z ", 0, arg, "Statement")
	qa.assertEqual ms.str(res.capture),     "[StmtCall 1:1 1:7]"                + _NL +
	                                        " callable:"                        + _NL +
	                                        "  [Identifier 1:1 1:1] name = ""X"""   + _NL +
	                                        " args.0"                           + _NL +
	                                        "  [OpUMinus 1:3 1:4]"              + _NL +
	                                        "   operands.0"                     + _NL +
	                                        "    [Identifier 1:4 1:4] name = ""Y""" + _NL +
	                                        " args.1"                           + _NL +
	                                        "  [Identifier 1:7 1:7] name = ""Z"""
	
	//
	arg = ms._makeParseArg({"multilineContinuations": true})
	//
	
	res = ms.grammar.parse("X Y, " + char(13) + char(13) + " Z ", 0, arg, "Statement")
	qa.assertEqual ms.str(res.capture),     "[StmtCall 1:1 3:2]"                + _NL +
	                                        " callable:"                        + _NL +
	                                        "  [Identifier 1:1 1:1] name = ""X"""   + _NL +
	                                        " args.0"                           + _NL +
	                                        "  [Identifier 1:3 1:3] name = ""Y"""   + _NL +
	                                        " args.1"                           + _NL +
	                                        "  [Identifier 3:2 3:2] name = ""Z"""
end function


testAssignmentStatement = function
	//
	arg = ms._makeParseArg
	//
	
	res = ms.grammar.parse("A = X ", 0, arg, "Statement")
	qa.assertEqual ms.str(res.capture),     "[StmtAssign 1:1 1:5] math = """""          + _NL +
	                                        " left:"                                + _NL +
	                                        "  [Identifier 1:1 1:1] name = ""A"""       + _NL +
	                                        " right:"                               + _NL +
	                                        "  [Identifier 1:5 1:5] name = ""X"""
	
	res = ms.grammar.parse("A.B = X ", 0, arg, "Statement")
	qa.assertEqual ms.str(res.capture),     "[StmtAssign 1:1 1:7] math = """""          + _NL +
	                                        " left:"                                + _NL +
	                                        "  [OpDot 1:1 1:3] name = ""B"""            + _NL +
	                                        "   operands.0"                         + _NL +
	                                        "    [Identifier 1:1 1:1] name = ""A"""     + _NL +
	                                        " right:"                               + _NL +
	                                        "  [Identifier 1:7 1:7] name = ""X"""
	
	res = ms.grammar.parse("A[B] = X ", 0, arg, "Statement")
	qa.assertEqual ms.str(res.capture),     "[StmtAssign 1:1 1:8] math = """""          + _NL +
	                                        " left:"                                + _NL +
	                                        "  [OpIndex 1:1 1:4]"                   + _NL +
	                                        "   operands.0"                         + _NL +
	                                        "    [Identifier 1:1 1:1] name = ""A"""     + _NL +
	                                        "   key:"                               + _NL +
	                                        "    [Identifier 1:3 1:3] name = ""B"""     + _NL +
	                                        " right:"                               + _NL +
	                                        "  [Identifier 1:8 1:8] name = ""X"""
	
	res = ms.grammar.parse("@ A = X ", 0, arg, "Statement")
	qa.assertEqual ms.str(res.capture),     "[StmtAssign 1:1 1:7] math = """""          + _NL +
	                                        " left:"                                + _NL +
	                                        "  [Identifier 1:3 1:3] name = ""A"""     + _NL +
	                                        " right:"                               + _NL +
	                                        "  [Identifier 1:7 1:7] name = ""X"""
	
	res = ms.grammar.parse("(A + B).C = X ", 0, arg, "Statement")
	qa.assertEqual ms.str(res.capture),     "[StmtAssign 1:1 1:13] math = """""         + _NL +
	                                        " left:"                                + _NL +
	                                        "  [OpDot 1:1 1:9] name = ""C"""            + _NL +
	                                        "   operands.0"                         + _NL +
	                                        "    [OpAdd 1:1 1:7]"                   + _NL +
	                                        "     operands.0"                       + _NL +
	                                        "      [Identifier 1:2 1:2] name = ""A"""   + _NL +
	                                        "     operands.1"                       + _NL +
	                                        "      [Identifier 1:6 1:6] name = ""B"""   + _NL +
	                                        " right:"                               + _NL +
	                                        "  [Identifier 1:13 1:13] name = ""X"""
	
	res = ms.grammar.parse("A /= X ", 0, arg, "Statement")
	qa.assertEqual ms.str(res.capture),     "[StmtAssign 1:1 1:6] math = ""/"""         + _NL +
	                                        " left:"                                + _NL +
	                                        "  [Identifier 1:1 1:1] name = ""A"""       + _NL +
	                                        " right:"                               + _NL +
	                                        "  [Identifier 1:6 1:6] name = ""X"""
end function


testIfStatement = function
	//
	arg = ms._makeParseArg
	//
	
	res = ms.grammar.parse("if X then" + char(10) + "end if ", 0, arg, "Statement")
	qa.assertEqual ms.str(res.capture),     "[StmtIf 1:1 2:6]"                      + _NL +
	                                        " conditions.0"                         + _NL +
	                                        "  [Identifier 1:4 1:4] name = ""X"""       + _NL +
	                                        " statements.--.--"                     + _NL +
	                                        " elseStatements.--"
	
	res = ms.grammar.parse("if X then ; end if ", 0, arg, "Statement")
	qa.assertEqual ms.str(res.capture),     "[StmtIf 1:1 1:18]"                     + _NL +
	                                        " conditions.0"                         + _NL +
	                                        "  [Identifier 1:4 1:4] name = ""X"""       + _NL +
	                                        " statements.--.--"                     + _NL +
	                                        " elseStatements.--"
	
	res = ms.grammar.parse("if X then" + char(10) + char(10) + "end if ", 0, arg, "Statement")
	qa.assertEqual ms.str(res.capture),     "[StmtIf 1:1 3:6]"                      + _NL +
	                                        " conditions.0"                         + _NL +
	                                        "  [Identifier 1:4 1:4] name = ""X"""       + _NL +
	                                        " statements.0.0"                       + _NL +
	                                        "  [StmtEmpty 2:1 2:1]"                 + _NL +
	                                        " elseStatements.--"
	
	res = ms.grammar.parse("if X then" + char(10) + "Y ; end if ", 0, arg, "Statement")
	qa.assertEqual ms.str(res.capture),     "[StmtIf 1:1 2:10]"                     + _NL +
	                                        " conditions.0"                         + _NL +
	                                        "  [Identifier 1:4 1:4] name = ""X"""       + _NL +
	                                        " statements.0.0"                       + _NL +
	                                        "  [StmtCall 2:1 2:1]"                  + _NL +
	                                        "   callable:"                          + _NL +
	                                        "    [Identifier 2:1 2:1] name = ""Y"""     + _NL +
	                                        "   args.--"                            + _NL +
	                                        " elseStatements.--"
	
	res = ms.grammar.parse("if X then" + char(10) + "Y ; Z" + char(10) + "end if ", 0, arg, "Statement")
	qa.assertEqual ms.str(res.capture),     "[StmtIf 1:1 3:6]"                      + _NL +
	                                        " conditions.0"                         + _NL +
	                                        "  [Identifier 1:4 1:4] name = ""X"""       + _NL +
	                                        " statements.0.0"                       + _NL +
	                                        "  [StmtCall 2:1 2:1]"                  + _NL +
	                                        "   callable:"                          + _NL +
	                                        "    [Identifier 2:1 2:1] name = ""Y"""     + _NL +
	                                        "   args.--"                            + _NL +
	                                        " statements.0.1"                       + _NL +
	                                        "  [StmtCall 2:5 2:5]"                  + _NL +
	                                        "   callable:"                          + _NL +
	                                        "    [Identifier 2:5 2:5] name = ""Z"""     + _NL +
	                                        "   args.--"                            + _NL +
	                                        " elseStatements.--"
	
	res = ms.grammar.parse( "if A then" + char(10) +
	                        " X"        + char(10) +
	                        " Y"        + char(10) +
	                        "else"      + char(10) +
	                        " Z"        + char(10) +
	                        " W"        + char(10) +
	                        "end if ",
	                        0, arg, "Statement")
	qa.assertEqual ms.str(res.capture),     "[StmtIf 1:1 7:6]"                      + _NL +
	                                        " conditions.0"                         + _NL +
	                                        "  [Identifier 1:4 1:4] name = ""A"""       + _NL +
	                                        " statements.0.0"                       + _NL +
	                                        "  [StmtCall 2:2 2:2]"                  + _NL +
	                                        "   callable:"                          + _NL +
	                                        "    [Identifier 2:2 2:2] name = ""X"""     + _NL +
	                                        "   args.--"                            + _NL +
	                                        " statements.0.1"                       + _NL +
	                                        "  [StmtCall 3:2 3:2]"                  + _NL +
	                                        "   callable:"                          + _NL +
	                                        "    [Identifier 3:2 3:2] name = ""Y"""     + _NL +
	                                        "   args.--"                            + _NL +
	                                        " elseStatements.0"                     + _NL +
	                                        "  [StmtCall 5:2 5:2]"                  + _NL +
	                                        "   callable:"                          + _NL +
	                                        "    [Identifier 5:2 5:2] name = ""Z"""     + _NL +
	                                        "   args.--"                            + _NL +
	                                        " elseStatements.1"                     + _NL +
	                                        "  [StmtCall 6:2 6:2]"                  + _NL +
	                                        "   callable:"                          + _NL +
	                                        "    [Identifier 6:2 6:2] name = ""W"""     + _NL +
	                                        "   args.--"
	
	res = ms.grammar.parse("if A then ; X ; else if B then ; Y ; else if C then ; Z ; end if ", 0, arg, "Statement")
	qa.assertEqual ms.str(res.capture),     "[StmtIf 1:1 1:64]"                     + _NL +
	                                        " conditions.0"                         + _NL +
	                                        "  [Identifier 1:4 1:4] name = ""A"""       + _NL +
	                                        " conditions.1"                         + _NL +
	                                        "  [Identifier 1:25 1:25] name = ""B"""     + _NL +
	                                        " conditions.2"                         + _NL +
	                                        "  [Identifier 1:46 1:46] name = ""C"""     + _NL +
	                                        " statements.0.0"                       + _NL +
	                                        "  [StmtCall 1:13 1:13]"                + _NL +
	                                        "   callable:"                          + _NL +
	                                        "    [Identifier 1:13 1:13] name = ""X"""   + _NL +
	                                        "   args.--"                            + _NL +
	                                        " statements.1.0"                       + _NL +
	                                        "  [StmtCall 1:34 1:34]"                + _NL +
	                                        "   callable:"                          + _NL +
	                                        "    [Identifier 1:34 1:34] name = ""Y"""   + _NL +
	                                        "   args.--"                            + _NL +
	                                        " statements.2.0"                       + _NL +
	                                        "  [StmtCall 1:55 1:55]"                + _NL +
	                                        "   callable:"                          + _NL +
	                                        "    [Identifier 1:55 1:55] name = ""Z"""   + _NL +
	                                        "   args.--"                            + _NL +
	                                        " elseStatements.--"
	
	res = ms.grammar.parse( "if A then ; X "        + char(10) +
	                        "else if B then ; Y "   + char(10) +
	                        "else ; Z "             + char(10) +
	                        "end if ",
	                        0, arg, "Statement")
	qa.assertEqual ms.str(res.capture),     "[StmtIf 1:1 4:6]"                      + _NL +
	                                        " conditions.0"                         + _NL +
	                                        "  [Identifier 1:4 1:4] name = ""A"""       + _NL +
	                                        " conditions.1"                         + _NL +
	                                        "  [Identifier 2:9 2:9] name = ""B"""       + _NL +
	                                        " statements.0.0"                       + _NL +
	                                        "  [StmtCall 1:13 1:13]"                + _NL +
	                                        "   callable:"                          + _NL +
	                                        "    [Identifier 1:13 1:13] name = ""X"""   + _NL +
	                                        "   args.--"                            + _NL +
	                                        " statements.1.0"                       + _NL +
	                                        "  [StmtCall 2:18 2:18]"                + _NL +
	                                        "   callable:"                          + _NL +
	                                        "    [Identifier 2:18 2:18] name = ""Y"""   + _NL +
	                                        "   args.--"                            + _NL +
	                                        " elseStatements.0"                     + _NL +
	                                        "  [StmtCall 3:8 3:8]"                  + _NL +
	                                        "   callable:"                          + _NL +
	                                        "    [Identifier 3:8 3:8] name = ""Z"""     + _NL +
	                                        "   args.--"
	
	res = ms.grammar.parse( "if A then"                 + char(10) +
	                        " if B then ; X ; end if"   + char(10) +
	                        "else"                      + char(10) +
	                        " if C then ; Y ; end if"   + char(10) +
	                        "end if ",
	                        0, arg, "Statement")
	qa.assertEqual ms.str(res.capture),     "[StmtIf 1:1 5:6]"                      + _NL +
	                                        " conditions.0"                         + _NL +
	                                        "  [Identifier 1:4 1:4] name = ""A"""       + _NL +
	                                        " statements.0.0"                       + _NL +
	                                        "  [StmtIf 2:2 2:23]"                   + _NL +
	                                        "   conditions.0"                       + _NL +
	                                        "    [Identifier 2:5 2:5] name = ""B"""     + _NL +
	                                        "   statements.0.0"                     + _NL +
	                                        "    [StmtCall 2:14 2:14]"              + _NL +
	                                        "     callable:"                        + _NL +
	                                        "      [Identifier 2:14 2:14] name = ""X""" + _NL +
	                                        "     args.--"                          + _NL +
	                                        "   elseStatements.--"                  + _NL +
	                                        " elseStatements.0"                     + _NL +
	                                        "  [StmtIf 4:2 4:23]"                   + _NL +
	                                        "   conditions.0"                       + _NL +
	                                        "    [Identifier 4:5 4:5] name = ""C"""     + _NL +
	                                        "   statements.0.0"                     + _NL +
	                                        "    [StmtCall 4:14 4:14]"              + _NL +
	                                        "     callable:"                        + _NL +
	                                        "      [Identifier 4:14 4:14] name = ""Y""" + _NL +
	                                        "     args.--"                          + _NL +
	                                        "   elseStatements.--"
	
	res = ms.grammar.parse("if A then ; X ; end ", 0, arg, "Statement")
	qa.assertEqual res.hasErrorTag("expectedIfAfterEnd"), true
	qa.assertEqual not res.hasErrorType(ms.Continuation), true
	
	res = ms.grammar.parse("if A then ; X ", 0, arg, "Statement")
	qa.assertEqual res.hasErrorTag("expectedEndIf"), true
	qa.assertEqual res.hasErrorType(ms.Continuation), true
	qa.assertEqual res.hasErrorType(ms.ContIf), true
	
	res = ms.grammar.parse("if A ; X ; end if ", 0, arg, "Statement")
	qa.assertEqual res.hasErrorTag("expectedThen"), true
	qa.assertEqual not res.hasErrorType(ms.Continuation), true
	
	res = ms.grammar.parse("if A then ; X ; else if B ; Y ; end if ", 0, arg, "Statement")
	qa.assertEqual res.hasErrorTag("expectedThen"), true
	qa.assertEqual not res.hasErrorType(ms.Continuation), true
	
	res = ms.grammar.parse("if then ; X ; end if ", 0, arg, "Statement")
	qa.assertEqual res.hasErrorTag("expectedCondition"), true
	qa.assertEqual not res.hasErrorType(ms.Continuation), true
	
	res = ms.grammar.parse("if A then ", 0, arg, "Statement")
	qa.assertEqual res.hasErrorType(ms.Continuation), true
	qa.assertEqual res.hasErrorType(ms.ContIf), true
	
	res = ms.grammar.parse("if A then ; ", 0, arg, "Statement")
	qa.assertEqual res.hasErrorType(ms.Continuation), true
	qa.assertEqual res.hasErrorType(ms.ContIf), true
	
	res = ms.grammar.parse("if A then ; X ", 0, arg, "Statement")
	qa.assertEqual res.hasErrorType(ms.Continuation), true
	qa.assertEqual res.hasErrorType(ms.ContIf), true
	
	res = ms.grammar.parse("if A then ; X ; else if B then ", 0, arg, "Statement")
	qa.assertEqual res.hasErrorType(ms.Continuation), true
	qa.assertEqual res.hasErrorType(ms.ContIf), true
	
	res = ms.grammar.parse("if A then ; X ; else if B then ; ", 0, arg, "Statement")
	qa.assertEqual res.hasErrorType(ms.Continuation), true
	qa.assertEqual res.hasErrorType(ms.ContIf), true
	
	res = ms.grammar.parse("if A then ; X ; else if B then ; Y ", 0, arg, "Statement")
	qa.assertEqual res.hasErrorType(ms.Continuation), true
	qa.assertEqual res.hasErrorType(ms.ContIf), true
	
	res = ms.grammar.parse("if A then ; X ; else ", 0, arg, "Statement")
	qa.assertEqual res.hasErrorType(ms.Continuation), true
	qa.assertEqual res.hasErrorType(ms.ContIf), true
	
	res = ms.grammar.parse("if A then ; X ; else ; ", 0, arg, "Statement")
	qa.assertEqual res.hasErrorType(ms.Continuation), true
	qa.assertEqual res.hasErrorType(ms.ContIf), true
	
	res = ms.grammar.parse("if A then ; X ; else ; Y ", 0, arg, "Statement")
	qa.assertEqual res.hasErrorType(ms.Continuation), true
	qa.assertEqual res.hasErrorType(ms.ContIf), true
	
	res = ms.grammar.parse("if A then end if ", 0, arg, "Statement")
	qa.assertEqual res.hasErrorTag("expectedStatementSeparator"), true
	
	res = ms.grammar.parse("if A then else ; end if ", 0, arg, "Statement")
	qa.assertEqual res.hasErrorTag("expectedStatementSeparator"), true
	
	res = ms.grammar.parse("if A then ; else end if ", 0, arg, "Statement")
	qa.assertEqual res.hasErrorTag("expectedStatementSeparator"), true
	
	res = ms.grammar.parse("if A then if B then ; end if ", 0, arg, "Statement")
	qa.assertEqual res.hasErrorTag("expectedStatementSeparator"), true
	
	res = ms.grammar.parse("if A then ; else if B then ; Y ; else ; Z ; end if ", 0, arg, "Statement")
	qa.assertEqual ms.str(res.capture),     "[StmtIf 1:1 1:50]"                     + _NL +
	                                        " conditions.0"                         + _NL +
	                                        "  [Identifier 1:4 1:4] name = ""A"""       + _NL +
	                                        " conditions.1"                         + _NL +
	                                        "  [Identifier 1:21 1:21] name = ""B"""     + _NL +
	                                        " statements.0.--"                      + _NL +
	                                        " statements.1.0"                       + _NL +
	                                        "  [StmtCall 1:30 1:30]"                + _NL +
	                                        "   callable:"                          + _NL +
	                                        "    [Identifier 1:30 1:30] name = ""Y"""   + _NL +
	                                        "   args.--"                            + _NL +
	                                        " elseStatements.0"                     + _NL +
	                                        "  [StmtCall 1:41 1:41]"                + _NL +
	                                        "   callable:"                          + _NL +
	                                        "    [Identifier 1:41 1:41] name = ""Z"""   + _NL +
	                                        "   args.--"
	
	res = ms.grammar.parse("if A then ; X ; else if B then ; else ; Z ; end if ", 0, arg, "Statement")
	qa.assertEqual ms.str(res.capture),     "[StmtIf 1:1 1:50]"                     + _NL +
	                                        " conditions.0"                         + _NL +
	                                        "  [Identifier 1:4 1:4] name = ""A"""       + _NL +
	                                        " conditions.1"                         + _NL +
	                                        "  [Identifier 1:25 1:25] name = ""B"""     + _NL +
	                                        " statements.0.0"                       + _NL +
	                                        "  [StmtCall 1:13 1:13]"                + _NL +
	                                        "   callable:"                          + _NL +
	                                        "    [Identifier 1:13 1:13] name = ""X"""   + _NL +
	                                        "   args.--"                            + _NL +
	                                        " elseStatements.0"                     + _NL +
	                                        "  [StmtCall 1:41 1:41]"                + _NL +
	                                        "   callable:"                          + _NL +
	                                        "    [Identifier 1:41 1:41] name = ""Z"""   + _NL +
	                                        "   args.--"
	
	res = ms.grammar.parse("if A then ; X ; else if B then ; Y ; else ; end if ", 0, arg, "Statement")
	qa.assertEqual ms.str(res.capture),     "[StmtIf 1:1 1:50]"                     + _NL +
	                                        " conditions.0"                         + _NL +
	                                        "  [Identifier 1:4 1:4] name = ""A"""       + _NL +
	                                        " conditions.1"                         + _NL +
	                                        "  [Identifier 1:25 1:25] name = ""B"""     + _NL +
	                                        " statements.0.0"                       + _NL +
	                                        "  [StmtCall 1:13 1:13]"                + _NL +
	                                        "   callable:"                          + _NL +
	                                        "    [Identifier 1:13 1:13] name = ""X"""   + _NL +
	                                        "   args.--"                            + _NL +
	                                        " statements.1.0"                       + _NL +
	                                        "  [StmtCall 1:34 1:34]"                + _NL +
	                                        "   callable:"                          + _NL +
	                                        "    [Identifier 1:34 1:34] name = ""Y"""   + _NL +
	                                        "   args.--"                            + _NL +
	                                        " elseStatements.--"
end function


testShortIfStatement = function
	//
	arg = ms._makeParseArg
	//
	
	res = ms.grammar.parse("if A then X ", 0, arg, "Statement")
	qa.assertEqual ms.str(res.capture),     "[StmtIf 1:1 1:11]"                     + _NL +
	                                        " conditions.0"                         + _NL +
	                                        "  [Identifier 1:4 1:4] name = ""A"""       + _NL +
	                                        " statements.0.0"                       + _NL +
	                                        "  [StmtCall 1:11 1:11]"                + _NL +
	                                        "   callable:"                          + _NL +
	                                        "    [Identifier 1:11 1:11] name = ""X"""   + _NL +
	                                        "   args.--"                            + _NL +
	                                        " elseStatements.--"
	
	res = ms.grammar.parse("if A then X ; Y ", 0, arg, "Statement")
	qa.assertEqual ms.str(res.capture),     "[StmtIf 1:1 1:11]"                     + _NL +
	                                        " conditions.0"                         + _NL +
	                                        "  [Identifier 1:4 1:4] name = ""A"""       + _NL +
	                                        " statements.0.0"                       + _NL +
	                                        "  [StmtCall 1:11 1:11]"                + _NL +
	                                        "   callable:"                          + _NL +
	                                        "    [Identifier 1:11 1:11] name = ""X"""   + _NL +
	                                        "   args.--"                            + _NL +
	                                        " elseStatements.--"
	
	res = ms.grammar.parse("if A then X else Y ", 0, arg, "Statement")
	qa.assertEqual ms.str(res.capture),     "[StmtIf 1:1 1:18]"                     + _NL +
	                                        " conditions.0"                         + _NL +
	                                        "  [Identifier 1:4 1:4] name = ""A"""       + _NL +
	                                        " statements.0.0"                       + _NL +
	                                        "  [StmtCall 1:11 1:11]"                + _NL +
	                                        "   callable:"                          + _NL +
	                                        "    [Identifier 1:11 1:11] name = ""X"""   + _NL +
	                                        "   args.--"                            + _NL +
	                                        " elseStatements.0"                     + _NL +
	                                        "  [StmtCall 1:18 1:18]"                + _NL +
	                                        "   callable:"                          + _NL +
	                                        "    [Identifier 1:18 1:18] name = ""Y"""   + _NL +
	                                        "   args.--"
end function


testWhileStatement = function
	//
	arg = ms._makeParseArg
	//
	
	res = ms.grammar.parse( "while A" + char(13) +
	                        "end while ",
	                        0, arg, "Statement")
	qa.assertEqual ms.str(res.capture),     "[StmtWhile 1:1 2:9]"                   + _NL +
	                                        " condition:"                           + _NL +
	                                        "  [Identifier 1:7 1:7] name = ""A"""       + _NL +
	                                        " statements.--"
	
	res = ms.grammar.parse( "while A ; end while ", 0, arg, "Statement")
	qa.assertEqual ms.str(res.capture),     "[StmtWhile 1:1 1:19]"                  + _NL +
	                                        " condition:"                           + _NL +
	                                        "  [Identifier 1:7 1:7] name = ""A"""       + _NL +
	                                        " statements.--"
	
	res = ms.grammar.parse( "while A"       + char(13) +
	                        " X"            + char(13) +
	                        "end while ",
	                        0, arg, "Statement")
	qa.assertEqual ms.str(res.capture),     "[StmtWhile 1:1 3:9]"                   + _NL +
	                                        " condition:"                           + _NL +
	                                        "  [Identifier 1:7 1:7] name = ""A"""       + _NL +
	                                        " statements.0"                         + _NL +
	                                        "  [StmtCall 2:2 2:2]"                  + _NL +
	                                        "   callable:"                          + _NL +
	                                        "    [Identifier 2:2 2:2] name = ""X"""     + _NL +
	                                        "   args.--"
	
	res = ms.grammar.parse( "while A ; X ; Y ; end while ", 0, arg, "Statement")
	qa.assertEqual ms.str(res.capture),     "[StmtWhile 1:1 1:27]"                  + _NL +
	                                        " condition:"                           + _NL +
	                                        "  [Identifier 1:7 1:7] name = ""A"""       + _NL +
	                                        " statements.0"                         + _NL +
	                                        "  [StmtCall 1:11 1:11]"                + _NL +
	                                        "   callable:"                          + _NL +
	                                        "    [Identifier 1:11 1:11] name = ""X"""   + _NL +
	                                        "   args.--"                            + _NL +
	                                        " statements.1"                         + _NL +
	                                        "  [StmtCall 1:15 1:15]"                + _NL +
	                                        "   callable:"                          + _NL +
	                                        "    [Identifier 1:15 1:15] name = ""Y"""   + _NL +
	                                        "   args.--"
	
	res = ms.grammar.parse( "while ", 0, arg, "Statement")
	qa.assertEqual res.hasErrorTag("expectedCondition"), true
	qa.assertEqual not res.hasErrorType(ms.Continuation), true
	
	res = ms.grammar.parse( "while A ", 0, arg, "Statement")
	qa.assertEqual res.hasErrorType(ms.Continuation), true
	qa.assertEqual res.hasErrorType(ms.ContWhile), true
	
	res = ms.grammar.parse( "while A ; ", 0, arg, "Statement")
	qa.assertEqual res.hasErrorTag("expectedEndWhile"), true
	qa.assertEqual res.hasErrorType(ms.Continuation), true
	qa.assertEqual res.hasErrorType(ms.ContWhile), true
	
	res = ms.grammar.parse( "while A ; X ", 0, arg, "Statement")
	qa.assertEqual res.hasErrorTag("expectedEndWhile"), true
	qa.assertEqual res.hasErrorType(ms.Continuation), true
	qa.assertEqual res.hasErrorType(ms.ContWhile), true
	
	res = ms.grammar.parse( "while A ; X ; ", 0, arg, "Statement")
	qa.assertEqual res.hasErrorTag("expectedEndWhile"), true
	qa.assertEqual res.hasErrorType(ms.Continuation), true
	qa.assertEqual res.hasErrorType(ms.ContWhile), true
	
	res = ms.grammar.parse( "while A ; X ; end ", 0, arg, "Statement")
	qa.assertEqual res.hasErrorTag("expectedWhileAfterEnd"), true
	qa.assertEqual not res.hasErrorType(ms.Continuation), true
	
	res = ms.grammar.parse( "while A X ; end while", 0, arg, "Statement")
	qa.assertEqual res.hasErrorTag("expectedStatementSeparator"), true
	qa.assertEqual not res.hasErrorType(ms.Continuation), true
	
	res = ms.grammar.parse( "while A ; X end while", 0, arg, "Statement")
	qa.assertEqual res.hasErrorTag("expectedStatementSeparator"), true
	qa.assertEqual not res.hasErrorType(ms.Continuation), true
	
	res = ms.grammar.parse( "while A end while", 0, arg, "Statement")
	qa.assertEqual res.hasErrorTag("expectedStatementSeparator"), true
	qa.assertEqual not res.hasErrorType(ms.Continuation), true
end function


testForStatement = function
	//
	arg = ms._makeParseArg
	//
	
	res = ms.grammar.parse( "for A in B" + char(10) +
	                        "end for ",
	                        0, arg, "Statement")
	qa.assertEqual ms.str(res.capture),     "[StmtFor 1:1 2:7] var = ""A"""             + _NL +
	                                        " expression:"                          + _NL +
	                                        "  [Identifier 1:10 1:10] name = ""B"""     + _NL +
	                                        " statements.--"
	
	res = ms.grammar.parse("for A in B ; end for ", 0, arg, "Statement")
	qa.assertEqual ms.str(res.capture),     "[StmtFor 1:1 1:20] var = ""A"""            + _NL +
	                                        " expression:"                          + _NL +
	                                        "  [Identifier 1:10 1:10] name = ""B"""     + _NL +
	                                        " statements.--"
	
	res = ms.grammar.parse( "for A in B"    + char(10) +
	                        " X"            + char(10) +
	                        "end for ",
	                        0, arg, "Statement")
	qa.assertEqual ms.str(res.capture),     "[StmtFor 1:1 3:7] var = ""A"""             + _NL +
	                                        " expression:"                          + _NL +
	                                        "  [Identifier 1:10 1:10] name = ""B"""     + _NL +
	                                        " statements.0"                         + _NL +
	                                        "  [StmtCall 2:2 2:2]"                  + _NL +
	                                        "   callable:"                          + _NL +
	                                        "    [Identifier 2:2 2:2] name = ""X"""     + _NL +
	                                        "   args.--"
	
	res = ms.grammar.parse("for A in B ; X ; Y ; end for ", 0, arg, "Statement")
	qa.assertEqual ms.str(res.capture),     "[StmtFor 1:1 1:28] var = ""A"""            + _NL +
	                                        " expression:"                          + _NL +
	                                        "  [Identifier 1:10 1:10] name = ""B"""     + _NL +
	                                        " statements.0"                         + _NL +
	                                        "  [StmtCall 1:14 1:14]"                + _NL +
	                                        "   callable:"                          + _NL +
	                                        "    [Identifier 1:14 1:14] name = ""X"""   + _NL +
	                                        "   args.--"                            + _NL +
	                                        " statements.1"                         + _NL +
	                                        "  [StmtCall 1:18 1:18]"                + _NL +
	                                        "   callable:"                          + _NL +
	                                        "    [Identifier 1:18 1:18] name = ""Y"""   + _NL +
	                                        "   args.--"
	
	res = ms.grammar.parse("for ", 0, arg, "Statement")
	qa.assertEqual res.hasErrorTag("expectedForVariable"), true
	qa.assertEqual not res.hasErrorType(ms.Continuation), true
	
	res = ms.grammar.parse("for A ", 0, arg, "Statement")
	qa.assertEqual res.hasErrorTag("expectedIn"), true
	qa.assertEqual not res.hasErrorType(ms.Continuation), true
	
	res = ms.grammar.parse("for A in ", 0, arg, "Statement")
	qa.assertEqual res.hasErrorTag("expectedForExpression"), true
	qa.assertEqual not res.hasErrorType(ms.Continuation), true
	
	res = ms.grammar.parse("for A in B ", 0, arg, "Statement")
	qa.assertEqual res.hasErrorType(ms.Continuation), true
	qa.assertEqual res.hasErrorType(ms.ContFor), true
	
	res = ms.grammar.parse("for A in B ; ", 0, arg, "Statement")
	qa.assertEqual res.hasErrorTag("expectedEndFor"), true
	qa.assertEqual res.hasErrorType(ms.Continuation), true
	qa.assertEqual res.hasErrorType(ms.ContFor), true
	
	res = ms.grammar.parse("for A in B ; X ", 0, arg, "Statement")
	qa.assertEqual res.hasErrorTag("expectedEndFor"), true
	qa.assertEqual res.hasErrorType(ms.Continuation), true
	qa.assertEqual res.hasErrorType(ms.ContFor), true
	
	res = ms.grammar.parse("for A in B ; X ; ", 0, arg, "Statement")
	qa.assertEqual res.hasErrorTag("expectedEndFor"), true
	qa.assertEqual res.hasErrorType(ms.Continuation), true
	qa.assertEqual res.hasErrorType(ms.ContFor), true
	
	res = ms.grammar.parse("for A in B ; X ; end ", 0, arg, "Statement")
	qa.assertEqual res.hasErrorTag("expectedForAfterEnd"), true
	qa.assertEqual not res.hasErrorType(ms.Continuation), true
	
	res = ms.grammar.parse("for A in B end for ", 0, arg, "Statement")
	qa.assertEqual res.hasErrorTag("expectedStatementSeparator"), true
	qa.assertEqual not res.hasErrorType(ms.Continuation), true
	
	res = ms.grammar.parse("for A in B X ; end for ", 0, arg, "Statement")
	qa.assertEqual res.hasErrorTag("expectedStatementSeparator"), true
	qa.assertEqual not res.hasErrorType(ms.Continuation), true
	
	res = ms.grammar.parse("for A in B ; X end for ", 0, arg, "Statement")
	qa.assertEqual res.hasErrorTag("expectedStatementSeparator"), true
	qa.assertEqual not res.hasErrorType(ms.Continuation), true
end function


testReturnStatement = function
	//
	arg = ms._makeParseArg
	//
	
	res = ms.grammar.parse("return ", 0, arg, "Statement")
	qa.assertEqual ms.str(res.capture),     "[StmtReturn 1:1 1:6]"              + _NL +
	                                        " expression:"
	
	res = ms.grammar.parse("return X ", 0, arg, "Statement")
	qa.assertEqual ms.str(res.capture),     "[StmtReturn 1:1 1:8]"              + _NL +
	                                        " expression:"                      + _NL +
	                                        "  [Identifier 1:8 1:8] name = ""X"""
end function


testBreakStatement = function
	//
	arg = ms._makeParseArg
	//
	
	res = ms.grammar.parse("break ", 0, arg, "Statement")
	qa.assertEqual res.hasErrorTag("breakOutsideLoop"), true
	
	res = ms.grammar.parse("if X then ; break ; end if ", 0, arg, "Statement")
	qa.assertEqual res.hasErrorTag("breakOutsideLoop"), true
	
	res = ms.grammar.parse("while A ; break ; end while ", 0, arg, "Statement")
	qa.assertEqual ms.str(res.capture),     "[StmtWhile 1:1 1:27]"              + _NL +
	                                        " condition:"                       + _NL +
	                                        "  [Identifier 1:7 1:7] name = ""A"""   + _NL +
	                                        " statements.0"                     + _NL +
	                                        "  [StmtBreak 1:11 1:15]"
	
	res = ms.grammar.parse("for A in B ; if X then ; break ; end if ; end for ", 0, arg, "Statement")
	qa.assertEqual ms.str(res.capture),     "[StmtFor 1:1 1:49] var = ""A"""            + _NL +
	                                        " expression:"                          + _NL +
	                                        "  [Identifier 1:10 1:10] name = ""B"""     + _NL +
	                                        " statements.0"                         + _NL +
	                                        "  [StmtIf 1:14 1:39]"                  + _NL +
	                                        "   conditions.0"                       + _NL +
	                                        "    [Identifier 1:17 1:17] name = ""X"""   + _NL +
	                                        "   statements.0.0"                     + _NL +
	                                        "    [StmtBreak 1:26 1:30]"             + _NL +
	                                        "   elseStatements.--"
end function


testContinueStatement = function
	//
	arg = ms._makeParseArg
	//
	
	res = ms.grammar.parse("continue ", 0, arg, "Statement")
	qa.assertEqual res.hasErrorTag("continueOutsideLoop"), true
	
	res = ms.grammar.parse("if X then ; continue ; end if ", 0, arg, "Statement")
	qa.assertEqual res.hasErrorTag("continueOutsideLoop"), true
	
	res = ms.grammar.parse("while A ; continue ; end while ", 0, arg, "Statement")
	qa.assertEqual ms.str(res.capture),     "[StmtWhile 1:1 1:30]"              + _NL +
	                                        " condition:"                       + _NL +
	                                        "  [Identifier 1:7 1:7] name = ""A"""   + _NL +
	                                        " statements.0"                     + _NL +
	                                        "  [StmtContinue 1:11 1:18]"
	
	res = ms.grammar.parse("for A in B ; if X then ; continue ; end if ; end for ", 0, arg, "Statement")
	qa.assertEqual ms.str(res.capture),     "[StmtFor 1:1 1:52] var = ""A"""            + _NL +
	                                        " expression:"                          + _NL +
	                                        "  [Identifier 1:10 1:10] name = ""B"""     + _NL +
	                                        " statements.0"                         + _NL +
	                                        "  [StmtIf 1:14 1:42]"                  + _NL +
	                                        "   conditions.0"                       + _NL +
	                                        "    [Identifier 1:17 1:17] name = ""X"""   + _NL +
	                                        "   statements.0.0"                     + _NL +
	                                        "    [StmtContinue 1:26 1:33]"          + _NL +
	                                        "   elseStatements.--"
end function


testAssignFunctionStatement = function
	//
	arg = ms._makeParseArg
	//
	
	res = ms.grammar.parse("F = function ; end function ", 0, arg, "Statement")
	qa.assertEqual ms.str(res.capture),     "[StmtAssign 1:1 1:27] math = """""         + _NL +
	                                        " left:"                                + _NL +
	                                        "  [Identifier 1:1 1:1] name = ""F"""       + _NL +
	                                        " right:"                               + _NL +
	                                        "  [LitFunction 1:5 1:27]"              + _NL +
	                                        "   args.--"                            + _NL +
	                                        "   defaults.--"                        + _NL +
	                                        "   statements.--"
	
	res = ms.grammar.parse( "F = function()" + char(13) +
	                        "end function ",
	                        0, arg, "Statement")
	qa.assertEqual ms.str(res.capture),     "[StmtAssign 1:1 2:12] math = """""         + _NL +
	                                        " left:"                                + _NL +
	                                        "  [Identifier 1:1 1:1] name = ""F"""       + _NL +
	                                        " right:"                               + _NL +
	                                        "  [LitFunction 1:5 2:12]"              + _NL +
	                                        "   args.--"                            + _NL +
	                                        "   defaults.--"                        + _NL +
	                                        "   statements.--"
	
	res = ms.grammar.parse( "F = function(P)" + char(13) +
	                        " X" + char(13) +
	                        "end function ",
	                        0, arg, "Statement")
	qa.assertEqual ms.str(res.capture),     "[StmtAssign 1:1 3:12] math = """""         + _NL +
	                                        " left:"                                + _NL +
	                                        "  [Identifier 1:1 1:1] name = ""F"""       + _NL +
	                                        " right:"                               + _NL +
	                                        "  [LitFunction 1:5 3:12]"              + _NL +
	                                        "   args.0"                             + _NL +
	                                        "    ""P"""                                 + _NL +
	                                        "   defaults.0"                         + _NL +
	                                        "    null"                              + _NL +
	                                        "   statements.0"                       + _NL +
	                                        "    [StmtCall 2:2 2:2]"                + _NL +
	                                        "     callable:"                        + _NL +
	                                        "      [Identifier 2:2 2:2] name = ""X"""   + _NL +
	                                        "     args.--"
	
	res = ms.grammar.parse( "F = function(P, Q=42)" + char(13) +
	                        " X" + char(13) +
	                        " Y" + char(13) +
	                        "end function ",
	                        0, arg, "Statement")
	qa.assertEqual ms.str(res.capture),     "[StmtAssign 1:1 4:12] math = """""         + _NL +
	                                        " left:"                                + _NL +
	                                        "  [Identifier 1:1 1:1] name = ""F"""       + _NL +
	                                        " right:"                               + _NL +
	                                        "  [LitFunction 1:5 4:12]"              + _NL +
	                                        "   args.0"                             + _NL +
	                                        "    ""P"""                                 + _NL +
	                                        "   args.1"                             + _NL +
	                                        "    ""Q"""                                 + _NL +
	                                        "   defaults.0"                         + _NL +
	                                        "    null"                              + _NL +
	                                        "   defaults.1"                         + _NL +
	                                        "    [LitNumeral 1:19 1:20] int = ""42"", fract = null, eSign = null, exp = null, val = 42" + _NL +
	                                        "   statements.0"                       + _NL +
	                                        "    [StmtCall 2:2 2:2]"                + _NL +
	                                        "     callable:"                        + _NL +
	                                        "      [Identifier 2:2 2:2] name = ""X"""   + _NL +
	                                        "     args.--"                          + _NL +
	                                        "   statements.1"                       + _NL +
	                                        "    [StmtCall 3:2 3:2]"                + _NL +
	                                        "     callable:"                        + _NL +
	                                        "      [Identifier 3:2 3:2] name = ""Y"""   + _NL +
	                                        "     args.--"
	
	res = ms.grammar.parse("F = function ", 0, arg, "Statement")
	qa.assertEqual res.hasErrorType(ms.Continuation), true
	qa.assertEqual res.hasErrorType(ms.ContFunction), true
	
	res = ms.grammar.parse("F = function() ", 0, arg, "Statement")
	qa.assertEqual res.hasErrorType(ms.Continuation), true
	qa.assertEqual res.hasErrorType(ms.ContFunction), true
	
	res = ms.grammar.parse("F = function ; ", 0, arg, "Statement")
	qa.assertEqual res.hasErrorType(ms.Continuation), true
	qa.assertEqual res.hasErrorType(ms.ContFunction), true
	
	res = ms.grammar.parse("F = function() ; ", 0, arg, "Statement")
	qa.assertEqual res.hasErrorType(ms.Continuation), true
	qa.assertEqual res.hasErrorType(ms.ContFunction), true
	
	res = ms.grammar.parse("F = function() ; X ", 0, arg, "Statement")
	qa.assertEqual res.hasErrorType(ms.Continuation), true
	qa.assertEqual res.hasErrorType(ms.ContFunction), true
	
	res = ms.grammar.parse("F = function() ; X ; ", 0, arg, "Statement")
	qa.assertEqual res.hasErrorType(ms.Continuation), true
	qa.assertEqual res.hasErrorType(ms.ContFunction), true
	
	res = ms.grammar.parse("F = function() ; X ; end ", 0, arg, "Statement")
	qa.assertEqual res.hasErrorTag("expectedFunctionAfterEnd"), true
	qa.assertEqual not res.hasErrorType(ms.Continuation), true
	
	res = ms.grammar.parse("F = function end function ", 0, arg, "Statement")
	qa.assertEqual res.hasErrorTag("expectedStatementSeparator"), true
	qa.assertEqual not res.hasErrorType(ms.Continuation), true
	
	res = ms.grammar.parse("F = function() end function ", 0, arg, "Statement")
	qa.assertEqual res.hasErrorTag("expectedStatementSeparator"), true
	qa.assertEqual not res.hasErrorType(ms.Continuation), true
	
	res = ms.grammar.parse("F = function X ; end function ", 0, arg, "Statement")
	qa.assertEqual res.hasErrorTag("expectedStatementSeparator"), true
	qa.assertEqual not res.hasErrorType(ms.Continuation), true
	
	res = ms.grammar.parse("F = function() X ; end function ", 0, arg, "Statement")
	qa.assertEqual res.hasErrorTag("expectedStatementSeparator"), true
	qa.assertEqual not res.hasErrorType(ms.Continuation), true
	
	res = ms.grammar.parse("F = function ; X end function ", 0, arg, "Statement")
	qa.assertEqual res.hasErrorTag("expectedStatementSeparator"), true
	qa.assertEqual not res.hasErrorType(ms.Continuation), true
end function


testReturnFunctionStatement = function
	//
	arg = ms._makeParseArg
	//
	
	res = ms.grammar.parse("return function ; end function ", 0, arg, "Statement")
	qa.assertEqual ms.str(res.capture),     "[StmtReturn 1:1 1:30]"                 + _NL +
	                                        " expression:"                          + _NL +
	                                        "  [LitFunction 1:8 1:30]"              + _NL +
	                                        "   args.--"                            + _NL +
	                                        "   defaults.--"                        + _NL +
	                                        "   statements.--"
	
	res = ms.grammar.parse( "return function" + char(13) + char(10) +
	                        "end function ",
	                        0, arg, "Statement")
	qa.assertEqual ms.str(res.capture),     "[StmtReturn 1:1 2:12]"                 + _NL +
	                                        " expression:"                          + _NL +
	                                        "  [LitFunction 1:8 2:12]"              + _NL +
	                                        "   args.--"                            + _NL +
	                                        "   defaults.--"                        + _NL +
	                                        "   statements.--"
end function


testCallFunctionStatement = function
	//
	arg = ms._makeParseArg
	//
	
	res = ms.grammar.parse("A function ; end function ", 0, arg, "Statement")
	qa.assertEqual ms.str(res.capture),     "[StmtCall 1:1 1:25]"                   + _NL +
	                                        " callable:"                            + _NL +
	                                        "  [Identifier 1:1 1:1] name = ""A"""       + _NL +
	                                        " args.0"                               + _NL +
	                                        "  [LitFunction 1:3 1:25]"              + _NL +
	                                        "   args.--"                            + _NL +
	                                        "   defaults.--"                        + _NL +
	                                        "   statements.--"
	
	res = ms.grammar.parse( "A B, function(P)" + char(13) +
	                        "end function ",
	                        0, arg, "Statement")
	qa.assertEqual ms.str(res.capture),     "[StmtCall 1:1 2:12]"                   + _NL +
	                                        " callable:"                            + _NL +
	                                        "  [Identifier 1:1 1:1] name = ""A"""       + _NL +
	                                        " args.0"                               + _NL +
	                                        "  [Identifier 1:3 1:3] name = ""B"""       + _NL +
	                                        " args.1"                               + _NL +
	                                        "  [LitFunction 1:6 2:12]"              + _NL +
	                                        "   args.0"                             + _NL +
	                                        "    ""P"""                                 + _NL +
	                                        "   defaults.0"                         + _NL +
	                                        "    null"                              + _NL +
	                                        "   statements.--"
end function


testBreakAndContinueInFunctionInLoop = function
	//
	arg = ms._makeParseArg
	//
	
	res = ms.grammar.parse( "while A"           + char(13) +
	                        " F = function"     + char(13) +
	                        "  break"           + char(13) +
	                        " end function"     + char(13) +
	                        "end while ",
	                        0, arg, "Statement")
	qa.assertEqual res.hasErrorTag("breakOutsideLoop"), true
	
	res = ms.grammar.parse( "for A in B"        + char(13) +
	                        " F = function()"   + char(13) +
	                        "  continue"        + char(13) +
	                        " end function"     + char(13) +
	                        "end while ",
	                        0, arg, "Statement")
	qa.assertEqual res.hasErrorTag("continueOutsideLoop"), true
end function

