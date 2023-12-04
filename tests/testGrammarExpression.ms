import "qa"

//
if not globals.hasIndex("ms") then
	import "ms"
	globals.ms = ms
end if
//


_NL = ms._NL


testExpSimple = function
	//
	arg = ms._makeParseArg
	//
	
	res = ms.grammar.parse("", 0, arg, "Expression")
	qa.assertEqual res.match, null
	
	res = ms.grammar.parse(" ", 0, arg, "Expression")
	qa.assertEqual res.match, null
	
	res = ms.grammar.parse("null ", 0, arg, "Expression")
	qa.assertEqual ms.str(res.capture), "[LitNull 1:1 1:4]"
	
	res = ms.grammar.parse("true ", 0, arg, "Expression")
	qa.assertEqual ms.str(res.capture), "[LitTrue 1:1 1:4]"
	
	res = ms.grammar.parse("false ", 0, arg, "Expression")
	qa.assertEqual ms.str(res.capture), "[LitFalse 1:1 1:5]"
	
	res = ms.grammar.parse("foo ", 0, arg, "Expression")
	qa.assertEqual ms.str(res.capture), "[Identifier 1:1 1:3] name = ""foo"""
	
	res = ms.grammar.parse("3.14 ", 0, arg, "Expression")
	qa.assertEqual ms.str(res.capture), "[LitNumeral 1:1 1:4] int = ""3"", fract = ""14"", eSign = null, exp = null, val = 3.14"
	
	res = ms.grammar.parse("""hi"" ", 0, arg, "Expression")
	qa.assertEqual ms.str(res.capture), "[LitString 1:1 1:4] text = ""hi"""
end function


testExpParens = function
	//
	arg = ms._makeParseArg
	//
	
	res = ms.grammar.parse("(null) ", 0, arg, "Expression")
	qa.assertEqual ms.str(res.capture), "[LitNull 1:1 1:6]"
	
	res = ms.grammar.parse("(  42  ) ", 0, arg, "Expression")
	qa.assertEqual ms.str(res.capture), "[LitNumeral 1:1 1:8] int = ""42"", fract = null, eSign = null, exp = null, val = 42"
	
	res = ms.grammar.parse("( " + char(13) + " foo  ) ", 0, arg, "Expression")
	qa.assertEqual ms.str(res.capture), "[Identifier 1:1 2:7] name = ""foo"""
	
	res = ms.grammar.parse("( ", 0, arg, "Expression")
	qa.assertEqual res.match, null
	qa.assertEqual res.hasErrorType(ms.Continuation), true
	qa.assertEqual res.hasErrorType(ms.ContLine), true
	
	res = ms.grammar.parse("( " + char(13), 0, arg, "Expression")
	qa.assertEqual res.match, null
	qa.assertEqual res.hasErrorType(ms.Continuation), true
	qa.assertEqual res.hasErrorType(ms.ContLine), true
	
	//
	arg = ms._makeParseArg({"multilineContinuations": false})
	//
	
	res = ms.grammar.parse("( " + char(13) + char(13) + " foo  ) ", 0, arg, "Expression")
	qa.assertEqual res.match, null
	qa.assertEqual res.hasErrorTag("expectedExpression"), true
	qa.assertEqual not res.hasErrorType(ms.Continuation), true
	
	res = ms.grammar.parse("( " + char(13) + char(13), 0, arg, "Expression")
	qa.assertEqual res.match, null
	qa.assertEqual res.hasErrorTag("expectedExpression"), true
	qa.assertEqual not res.hasErrorType(ms.Continuation), true
	
	//
	arg = ms._makeParseArg({"multilineContinuations": true})
	//
	
	res = ms.grammar.parse("( " + char(13) + char(13) + " foo  ) ", 0, arg, "Expression")
	qa.assertEqual ms.str(res.capture), "[Identifier 1:1 3:7] name = ""foo"""
	
	res = ms.grammar.parse("( " + char(13) + char(13), 0, arg, "Expression")
	qa.assertEqual res.match, null
	qa.assertEqual res.hasErrorType(ms.Continuation), true
	qa.assertEqual res.hasErrorType(ms.ContLine), true
end function


testExpOr = function
	//
	arg = ms._makeParseArg
	//
	
	res = ms.grammar.parse("null or true ", 0, arg, "Expression")
	qa.assertEqual ms.str(res.capture),     "[OpOr 1:1 1:12]"       + _NL +
	                                        " operands.0"           + _NL +
	                                        "  [LitNull 1:1 1:4]"   + _NL +
	                                        " operands.1"           + _NL +
	                                        "  [LitTrue 1:9 1:12]"
	
	res = ms.grammar.parse("false or " + char(10) + " 42 ", 0, arg, "Expression")
	qa.assertEqual ms.str(res.capture),     "[OpOr 1:1 2:3]"        + _NL +
	                                        " operands.0"           + _NL +
	                                        "  [LitFalse 1:1 1:5]"  + _NL +
	                                        " operands.1"           + _NL +
	                                        "  [LitNumeral 2:2 2:3] int = ""42"", fract = null, eSign = null, exp = null, val = 42"
	
	res = ms.grammar.parse("(X or ", 0, arg, "Expression")
	qa.assertEqual res.match, null
	qa.assertEqual res.hasErrorType(ms.Continuation), true
	qa.assertEqual res.hasErrorType(ms.ContLine), true
	
	res = ms.grammar.parse("X or Y or Z ", 0, arg, "Expression")
	qa.assertEqual ms.str(res.capture),     "[OpOr 1:1 1:11]"                       + _NL +
	                                        " operands.0"                           + _NL +
	                                        "  [OpOr 1:1 1:6]"                      + _NL +
	                                        "   operands.0"                         + _NL +
	                                        "    [Identifier 1:1 1:1] name = ""X"""     + _NL +
	                                        "   operands.1"                         + _NL +
	                                        "    [Identifier 1:6 1:6] name = ""Y"""     + _NL +
	                                        " operands.1"                           + _NL +
	                                        "  [Identifier 1:11 1:11] name = ""Z"""
	
	res = ms.grammar.parse("X or (Y or Z) ", 0, arg, "Expression")
	qa.assertEqual ms.str(res.capture),     "[OpOr 1:1 1:13]"                       + _NL +
	                                        " operands.0"                           + _NL +
	                                        "  [Identifier 1:1 1:1] name = ""X"""       + _NL +
	                                        " operands.1"                           + _NL +
	                                        "  [OpOr 1:6 1:13]"                     + _NL +
	                                        "   operands.0"                         + _NL +
	                                        "    [Identifier 1:7 1:7] name = ""Y"""     + _NL +
	                                        "   operands.1"                         + _NL +
	                                        "    [Identifier 1:12 1:12] name = ""Z"""
	
	//
	arg = ms._makeParseArg({"multilineContinuations": false})
	//
	
	res = ms.grammar.parse("(X or " + char(10) + char(10) + " Y ) ", 0, arg, "Expression")
	qa.assertEqual res.match, null
	qa.assertEqual res.hasErrorTag("expectedOperand"), true
	qa.assertEqual not res.hasErrorType(ms.Continuation), true
	
	res = ms.grammar.parse("(X or " + char(10) + char(10), 0, arg, "Expression")
	qa.assertEqual res.match, null
	qa.assertEqual res.hasErrorTag("expectedOperand"), true
	qa.assertEqual not res.hasErrorType(ms.Continuation), true
	
	//
	arg = ms._makeParseArg({"multilineContinuations": true})
	//
	
	res = ms.grammar.parse("(X or " + char(10) + char(10) + " Y ) ", 0, arg, "Expression")
	qa.assertEqual ms.str(res.capture),     "[OpOr 1:1 3:4]"                    + _NL +
	                                        " operands.0"                       + _NL +
	                                        "  [Identifier 1:2 1:2] name = ""X"""   + _NL +
	                                        " operands.1"                       + _NL +
	                                        "  [Identifier 3:2 3:2] name = ""Y"""
	
	res = ms.grammar.parse("(X or " + char(10) + char(10), 0, arg, "Expression")
	qa.assertEqual res.match, null
	qa.assertEqual res.hasErrorType(ms.Continuation), true
	qa.assertEqual res.hasErrorType(ms.ContLine), true
end function


testExpAnd = function
	//
	arg = ms._makeParseArg
	//
	
	res = ms.grammar.parse("X and Y ", 0, arg, "Expression")
	qa.assertEqual ms.str(res.capture),     "[OpAnd 1:1 1:7]"                   + _NL +
	                                        " operands.0"                       + _NL +
	                                        "  [Identifier 1:1 1:1] name = ""X"""   + _NL +
	                                        " operands.1"                       + _NL +
	                                        "  [Identifier 1:7 1:7] name = ""Y"""
end function


testExpNot = function
	//
	arg = ms._makeParseArg
	//
	
	res = ms.grammar.parse("not X ", 0, arg, "Expression")
	qa.assertEqual ms.str(res.capture),     "[OpNot 1:1 1:5]"                   + _NL +
	                                        " operands.0"                       + _NL +
	                                        "  [Identifier 1:5 1:5] name = ""X"""
end function


testExpIsa = function
	//
	arg = ms._makeParseArg
	//
	
	res = ms.grammar.parse("X isa Y ", 0, arg, "Expression")
	qa.assertEqual ms.str(res.capture),     "[OpIsa 1:1 1:7]"                   + _NL +
	                                        " operands.0"                       + _NL +
	                                        "  [Identifier 1:1 1:1] name = ""X"""   + _NL +
	                                        " operands.1"                       + _NL +
	                                        "  [Identifier 1:7 1:7] name = ""Y"""
end function


testExpCompare = function
	//
	arg = ms._makeParseArg
	//
	
	res = ms.grammar.parse("X < Y ", 0, arg, "Expression")
	qa.assertEqual ms.str(res.capture),     "[OpCompare 1:1 1:5]"               + _NL +
	                                        " operands.0"                       + _NL +
	                                        "  [Identifier 1:1 1:1] name = ""X"""   + _NL +
	                                        " operands.1"                       + _NL +
	                                        "  [Identifier 1:5 1:5] name = ""Y"""   + _NL +
	                                        " operators.0"                      + _NL +
	                                        "  ""<"""
	
	res = ms.grammar.parse("X == Y >= Z ", 0, arg, "Expression")
	qa.assertEqual ms.str(res.capture),     "[OpCompare 1:1 1:11]"              + _NL +
	                                        " operands.0"                       + _NL +
	                                        "  [Identifier 1:1 1:1] name = ""X"""   + _NL +
	                                        " operands.1"                       + _NL +
	                                        "  [Identifier 1:6 1:6] name = ""Y"""   + _NL +
	                                        " operands.2"                       + _NL +
	                                        "  [Identifier 1:11 1:11] name = ""Z""" + _NL +
	                                        " operators.0"                      + _NL +
	                                        "  ""=="""                              + _NL +
	                                        " operators.1"                      + _NL +
	                                        "  "">="""
end function


testExpAddSub = function
	//
	arg = ms._makeParseArg
	//
	
	res = ms.grammar.parse("X + Y ", 0, arg, "Expression")
	qa.assertEqual ms.str(res.capture),     "[OpAdd 1:1 1:5]"                   + _NL +
	                                        " operands.0"                       + _NL +
	                                        "  [Identifier 1:1 1:1] name = ""X"""   + _NL +
	                                        " operands.1"                       + _NL +
	                                        "  [Identifier 1:5 1:5] name = ""Y"""
	
	res = ms.grammar.parse("X - Y ", 0, arg, "Expression")
	qa.assertEqual ms.str(res.capture),     "[OpSubtract 1:1 1:5]"              + _NL +
	                                        " operands.0"                       + _NL +
	                                        "  [Identifier 1:1 1:1] name = ""X"""   + _NL +
	                                        " operands.1"                       + _NL +
	                                        "  [Identifier 1:5 1:5] name = ""Y"""
end function


testExpMulDivMod = function
	//
	arg = ms._makeParseArg
	//
	
	res = ms.grammar.parse("X * Y ", 0, arg, "Expression")
	qa.assertEqual ms.str(res.capture),     "[OpMultiply 1:1 1:5]"              + _NL +
	                                        " operands.0"                       + _NL +
	                                        "  [Identifier 1:1 1:1] name = ""X"""   + _NL +
	                                        " operands.1"                       + _NL +
	                                        "  [Identifier 1:5 1:5] name = ""Y"""
	
	res = ms.grammar.parse("X / Y ", 0, arg, "Expression")
	qa.assertEqual ms.str(res.capture),     "[OpDivide 1:1 1:5]"                + _NL +
	                                        " operands.0"                       + _NL +
	                                        "  [Identifier 1:1 1:1] name = ""X"""   + _NL +
	                                        " operands.1"                       + _NL +
	                                        "  [Identifier 1:5 1:5] name = ""Y"""
	
	res = ms.grammar.parse("X % Y ", 0, arg, "Expression")
	qa.assertEqual ms.str(res.capture),     "[OpModulo 1:1 1:5]"                + _NL +
	                                        " operands.0"                       + _NL +
	                                        "  [Identifier 1:1 1:1] name = ""X"""   + _NL +
	                                        " operands.1"                       + _NL +
	                                        "  [Identifier 1:5 1:5] name = ""Y"""
	
end function


testExpUMinus = function
	//
	arg = ms._makeParseArg
	//
	
	res = ms.grammar.parse("- X ", 0, arg, "Expression")
	qa.assertEqual ms.str(res.capture),     "[OpUMinus 1:1 1:3]"                + _NL +
	                                        " operands.0"                       + _NL +
	                                        "  [Identifier 1:3 1:3] name = ""X"""
end function


testExpNew = function
	//
	arg = ms._makeParseArg
	//
	
	res = ms.grammar.parse("new X ", 0, arg, "Expression")
	qa.assertEqual ms.str(res.capture),     "[OpNew 1:1 1:5]"                   + _NL +
	                                        " operands.0"                       + _NL +
	                                        "  [Identifier 1:5 1:5] name = ""X"""
end function


testExpAddress = function
	//
	arg = ms._makeParseArg
	//
	
	res = ms.grammar.parse("@ X ", 0, arg, "Expression")
	qa.assertEqual ms.str(res.capture),     "[OpAddress 1:1 1:3]"               + _NL +
	                                        " operands.0"                       + _NL +
	                                        "  [Identifier 1:3 1:3] name = ""X"""
end function


testExpPower = function
	//
	arg = ms._makeParseArg
	//
	
	res = ms.grammar.parse("X ^ Y ", 0, arg, "Expression")
	qa.assertEqual ms.str(res.capture),     "[OpPower 1:1 1:5]"                 + _NL +
	                                        " operands.0"                       + _NL +
	                                        "  [Identifier 1:1 1:1] name = ""X"""   + _NL +
	                                        " operands.1"                       + _NL +
	                                        "  [Identifier 1:5 1:5] name = ""Y"""
end function


testExpAccess = function
	//
	arg = ms._makeParseArg
	//
	
	res = ms.grammar.parse("X[ Y ] ", 0, arg, "Expression")
	qa.assertEqual ms.str(res.capture),     "[OpIndex 1:1 1:6]"                 + _NL +
	                                        " operands.0"                       + _NL +
	                                        "  [Identifier 1:1 1:1] name = ""X"""   + _NL +
	                                        " key:"                             + _NL +
	                                        "  [Identifier 1:4 1:4] name = ""Y"""
	
	res = ms.grammar.parse("X[ Y : Z ] ", 0, arg, "Expression")
	qa.assertEqual ms.str(res.capture),     "[OpSlice 1:1 1:10]"                + _NL +
	                                        " operands.0"                       + _NL +
	                                        "  [Identifier 1:1 1:1] name = ""X"""   + _NL +
	                                        " from:"                            + _NL +
	                                        "  [Identifier 1:4 1:4] name = ""Y"""   + _NL +
	                                        " to:"                              + _NL +
	                                        "  [Identifier 1:8 1:8] name = ""Z"""
	
	res = ms.grammar.parse("X[ : Z ] ", 0, arg, "Expression")
	qa.assertEqual ms.str(res.capture),     "[OpSlice 1:1 1:8]"                 + _NL +
	                                        " operands.0"                       + _NL +
	                                        "  [Identifier 1:1 1:1] name = ""X"""   + _NL +
	                                        " from:"                            + _NL +
	                                        " to:"                              + _NL +
	                                        "  [Identifier 1:6 1:6] name = ""Z"""
	
	res = ms.grammar.parse("X[ Y : ] ", 0, arg, "Expression")
	qa.assertEqual ms.str(res.capture),     "[OpSlice 1:1 1:8]"                 + _NL +
	                                        " operands.0"                       + _NL +
	                                        "  [Identifier 1:1 1:1] name = ""X"""   + _NL +
	                                        " from:"                            + _NL +
	                                        "  [Identifier 1:4 1:4] name = ""Y"""   + _NL +
	                                        " to:"
	
	res = ms.grammar.parse("X[ : ] ", 0, arg, "Expression")
	qa.assertEqual ms.str(res.capture),     "[OpSlice 1:1 1:6]"                 + _NL +
	                                        " operands.0"                       + _NL +
	                                        "  [Identifier 1:1 1:1] name = ""X"""   + _NL +
	                                        " from:"                            + _NL +
	                                        " to:"
	
	res = ms.grammar.parse("X . Y ", 0, arg, "Expression")
	qa.assertEqual ms.str(res.capture),     "[OpDot 1:1 1:5] name = ""Y"""          + _NL +
	                                        " operands.0"                       + _NL +
	                                        "  [Identifier 1:1 1:1] name = ""X"""
	
	res = ms.grammar.parse("X () ", 0, arg, "Expression")
	qa.assertEqual ms.str(res.capture),     "[OpCall 1:1 1:4]"                  + _NL +
	                                        " operands.0"                       + _NL +
	                                        "  [Identifier 1:1 1:1] name = ""X"""   + _NL +
	                                        " args.--"
	
	res = ms.grammar.parse("X ( Y ) ", 0, arg, "Expression")
	qa.assertEqual ms.str(res.capture),     "[OpCall 1:1 1:7]"                  + _NL +
	                                        " operands.0"                       + _NL +
	                                        "  [Identifier 1:1 1:1] name = ""X"""   + _NL +
	                                        " args.0"                           + _NL +
	                                        "  [Identifier 1:5 1:5] name = ""Y"""
	
	res = ms.grammar.parse("X ( Y , Z ) ", 0, arg, "Expression")
	qa.assertEqual ms.str(res.capture),     "[OpCall 1:1 1:11]"                 + _NL +
	                                        " operands.0"                       + _NL +
	                                        "  [Identifier 1:1 1:1] name = ""X"""   + _NL +
	                                        " args.0"                           + _NL +
	                                        "  [Identifier 1:5 1:5] name = ""Y"""   + _NL +
	                                        " args.1"                           + _NL +
	                                        "  [Identifier 1:9 1:9] name = ""Z"""
end function

