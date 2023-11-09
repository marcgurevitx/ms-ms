import "qa"

//
if not globals.hasIndex("ms") then
	import "ms"
	globals.ms = ms
end if
//


_NL = ms._NL


testLitNull = function
	res = ms.grammar.parse("", 0, null, "LitNull")
	qa.assertEqual res.match, null
	
	res = ms.grammar.parse(" ", 0, null, "LitNull")
	qa.assertEqual res.match, null
	
	res = ms.grammar.parse("null ", 0, null, "LitNull")
	qa.assertEqual ms.str(res.capture), "[LitNull 1:1 1:4]"
	
	res = ms.grammar.parse("nullX", 0, null, "LitNull")
	qa.assertEqual res.match, null
end function


testLitTrue = function
	res = ms.grammar.parse("", 0, null, "LitTrue")
	qa.assertEqual res.match, null
	
	res = ms.grammar.parse(" ", 0, null, "LitTrue")
	qa.assertEqual res.match, null
	
	res = ms.grammar.parse("true ", 0, null, "LitTrue")
	qa.assertEqual ms.str(res.capture), "[LitTrue 1:1 1:4]"
	
	res = ms.grammar.parse("trueX", 0, null, "LitTrue")
	qa.assertEqual res.match, null
end function


testLitFalse = function
	res = ms.grammar.parse("", 0, null, "LitFalse")
	qa.assertEqual res.match, null
	
	res = ms.grammar.parse(" ", 0, null, "LitFalse")
	qa.assertEqual res.match, null
	
	res = ms.grammar.parse("false ", 0, null, "LitFalse")
	qa.assertEqual ms.str(res.capture), "[LitFalse 1:1 1:5]"
	
	res = ms.grammar.parse("falseX", 0, null, "LitFalse")
	qa.assertEqual res.match, null
end function


testLitNumeral = function
	res = ms.grammar.parse("", 0, null, "LitNumeral")
	qa.assertEqual res.match, null
	
	res = ms.grammar.parse(" ", 0, null, "LitNumeral")
	qa.assertEqual res.match, null
	
	res = ms.grammar.parse("1 ", 0, null, "LitNumeral")
	qa.assertEqual ms.str(res.capture), "[LitNumeral 1:1 1:1] int = 1, fract = , eSign = , exp = , val = 1"
	
	res = ms.grammar.parse("1. ", 0, null, "LitNumeral")
	qa.assertEqual ms.str(res.capture), "[LitNumeral 1:1 1:2] int = 1, fract = , eSign = , exp = , val = 1"
	
	res = ms.grammar.parse("1.23 ", 0, null, "LitNumeral")
	qa.assertEqual ms.str(res.capture), "[LitNumeral 1:1 1:4] int = 1, fract = 23, eSign = , exp = , val = 1.23"
	
	res = ms.grammar.parse("1.23e4 ", 0, null, "LitNumeral")
	qa.assertEqual ms.str(res.capture), "[LitNumeral 1:1 1:6] int = 1, fract = 23, eSign = , exp = 4, val = 12300"
	
	res = ms.grammar.parse("1.23e+4 ", 0, null, "LitNumeral")
	qa.assertEqual ms.str(res.capture), "[LitNumeral 1:1 1:7] int = 1, fract = 23, eSign = +, exp = 4, val = 12300"
	
	res = ms.grammar.parse("1.23e-4 ", 0, null, "LitNumeral")
	qa.assertEqual ms.str(res.capture), "[LitNumeral 1:1 1:7] int = 1, fract = 23, eSign = -, exp = 4, val = 0.000123"
	
	res = ms.grammar.parse(".23e-4 ", 0, null, "LitNumeral")
	qa.assertEqual ms.str(res.capture), "[LitNumeral 1:1 1:6] int = , fract = 23, eSign = -, exp = 4, val = 0.000023"
	
	res = ms.grammar.parse("1e ", 0, null, "LitNumeral")
	qa.assertEqual ms.str(res.capture), "[LitNumeral 1:1 1:1] int = 1, fract = , eSign = , exp = , val = 1"
	qa.assertEqual res.hasErrorTag("expectedNumeralExponent"), true
	
	res = ms.grammar.parse("1e+ ", 0, null, "LitNumeral")
	qa.assertEqual ms.str(res.capture), "[LitNumeral 1:1 1:1] int = 1, fract = , eSign = , exp = , val = 1"
	qa.assertEqual res.hasErrorTag("expectedNumeralExponent"), true
end function


testLitString = function
	res = ms.grammar.parse("", 0, null, "LitString")
	qa.assertEqual res.match, null
	
	res = ms.grammar.parse(" ", 0, null, "LitString")
	qa.assertEqual res.match, null
	
	res = ms.grammar.parse(""""" ", 0, null, "LitString")
	qa.assertEqual ms.str(res.capture), "[LitString 1:1 1:2] text = "
	
	res = ms.grammar.parse("""foo"" ", 0, null, "LitString")
	qa.assertEqual ms.str(res.capture), "[LitString 1:1 1:5] text = foo"
	
	//
	arg = {}
	arg.features = {}
	arg.features.multilineStrings = false
	//
	
	res = ms.grammar.parse("""", 0, arg, "LitString")
	qa.assertEqual res.match, null
	qa.assertEqual res.hasErrorTag("expectedStringClose"), true
	qa.assertEqual not res.hasErrorType(ms.Continuation), true
	
	res = ms.grammar.parse("""foo", 0, arg, "LitString")
	qa.assertEqual res.match, null
	qa.assertEqual res.hasErrorTag("expectedStringClose"), true
	qa.assertEqual not res.hasErrorType(ms.Continuation), true
	
	//
	arg = {}
	arg.features = {}
	arg.features.multilineStrings = true
	//
	
	res = ms.grammar.parse("""", 0, arg, "LitString")
	qa.assertEqual res.match, null
	qa.assertEqual res.hasErrorType(ms.Continuation), true
	qa.assertEqual res.hasErrorType(ms.ContString), true
	
	res = ms.grammar.parse("""foo", 0, arg, "LitString")
	qa.assertEqual res.match, null
	qa.assertEqual res.hasErrorType(ms.Continuation), true
	qa.assertEqual res.hasErrorType(ms.ContString), true
end function


testIdentifier = function
	res = ms.grammar.parse("", 0, null, "Identifier")
	qa.assertEqual res.match, null
	
	res = ms.grammar.parse(" ", 0, null, "Identifier")
	qa.assertEqual res.match, null
	
	res = ms.grammar.parse("foo ", 0, null, "Identifier")
	qa.assertEqual ms.str(res.capture), "[Identifier 1:1 1:3] name = foo"
end function


testLitList = function
	res = ms.grammar.parse("", 0, null, "LitList")
	qa.assertEqual res.match, null
	
	res = ms.grammar.parse(" ", 0, null, "LitList")
	qa.assertEqual res.match, null
	
	res = ms.grammar.parse("[] ", 0, null, "LitList")
	qa.assertEqual ms.str(res.capture),     "[LitList 1:1 1:2]" + _NL +
	                                        " elements.--"
	
	res = ms.grammar.parse("[ ] ", 0, null, "LitList")
	qa.assertEqual ms.str(res.capture),     "[LitList 1:1 1:3]" + _NL +
	                                        " elements.--"
	
	res = ms.grammar.parse("[ " + char(13) + " ] ", 0, null, "LitList")
	qa.assertEqual ms.str(res.capture),     "[LitList 1:1 2:2]" + _NL +
	                                        " elements.--"
	
	res = ms.grammar.parse("[X] ", 0, null, "LitList")
	qa.assertEqual ms.str(res.capture),     "[LitList 1:1 1:3]"                 + _NL +
	                                        " elements.0"                       + _NL +
	                                        "  [Identifier 1:2 1:2] name = X"
	
	res = ms.grammar.parse("[X , Y] ", 0, null, "LitList")
	qa.assertEqual ms.str(res.capture),     "[LitList 1:1 1:7]"                 + _NL +
	                                        " elements.0"                       + _NL +
	                                        "  [Identifier 1:2 1:2] name = X"   + _NL +
	                                        " elements.1"                       + _NL +
	                                        "  [Identifier 1:6 1:6] name = Y"
	
	res = ms.grammar.parse("[X , Y , ] ", 0, null, "LitList")
	qa.assertEqual ms.str(res.capture),     "[LitList 1:1 1:10]"                + _NL +
	                                        " elements.0"                       + _NL +
	                                        "  [Identifier 1:2 1:2] name = X"   + _NL +
	                                        " elements.1"                       + _NL +
	                                        "  [Identifier 1:6 1:6] name = Y"
	
	res = ms.grammar.parse("[X," + char(13) + "Y] ", 0, null, "LitList")
	qa.assertEqual ms.str(res.capture),     "[LitList 1:1 2:2]"                 + _NL +
	                                        " elements.0"                       + _NL +
	                                        "  [Identifier 1:2 1:2] name = X"   + _NL +
	                                        " elements.1"                       + _NL +
	                                        "  [Identifier 2:1 2:1] name = Y"
	
	res = ms.grammar.parse("[ ", 0, null, "LitList")
	qa.assertEqual res.match, null
	qa.assertEqual res.hasErrorType(ms.Continuation), true
	qa.assertEqual res.hasErrorType(ms.ContLine), true
	
	res = ms.grammar.parse("[X ", 0, null, "LitList")
	qa.assertEqual res.match, null
	qa.assertEqual res.hasErrorTag("expectedClosingBracket"), true
	qa.assertEqual not res.hasErrorType(ms.Continuation), true
	
	res = ms.grammar.parse("[X, ", 0, null, "LitList")
	qa.assertEqual res.match, null
	qa.assertEqual res.hasErrorType(ms.Continuation), true
	qa.assertEqual res.hasErrorType(ms.ContLine), true
	
	res = ms.grammar.parse("[X, , ", 0, null, "LitList")
	qa.assertEqual res.match, null
	qa.assertEqual res.hasErrorTag("expectedClosingBracket"), true
	qa.assertEqual not res.hasErrorType(ms.Continuation), true
	
	//
	arg = {}
	arg.features = {}
	arg.features.multilineContinuations = false
	//
	
	res = ms.grammar.parse("[X," + char(13) + char(13) + "Y] ", 0, arg, "LitList")
	qa.assertEqual res.match, null
	qa.assertEqual res.hasErrorTag("expectedClosingBracket"), true
	qa.assertEqual not res.hasErrorType(ms.Continuation), true
	
	res = ms.grammar.parse("[X," + char(13) + char(13), 0, arg, "LitList")
	qa.assertEqual res.match, null
	qa.assertEqual res.hasErrorTag("expectedClosingBracket"), true
	qa.assertEqual not res.hasErrorType(ms.Continuation), true
	
	//
	arg = {}
	arg.features = {}
	arg.features.multilineContinuations = true
	//
	
	res = ms.grammar.parse("[X," + char(13) + char(13) + "Y] ", 0, arg, "LitList")
	qa.assertEqual ms.str(res.capture),     "[LitList 1:1 3:2]"                 + _NL +
	                                        " elements.0"                       + _NL +
	                                        "  [Identifier 1:2 1:2] name = X"   + _NL +
	                                        " elements.1"                       + _NL +
	                                        "  [Identifier 3:1 3:1] name = Y"
	
	res = ms.grammar.parse("[X," + char(13) + char(13), 0, arg, "LitList")
	qa.assertEqual res.match, null
	qa.assertEqual res.hasErrorType(ms.Continuation), true
	qa.assertEqual res.hasErrorType(ms.ContLine), true
end function


testLitMap = function
	res = ms.grammar.parse("", 0, null, "LitMap")
	qa.assertEqual res.match, null
	
	res = ms.grammar.parse(" ", 0, null, "LitMap")
	qa.assertEqual res.match, null
	
	res = ms.grammar.parse("{} ", 0, null, "LitMap")
	qa.assertEqual ms.str(res.capture),     "[LitMap 1:1 1:2]"                  + _NL +
	                                        " keys.--"                          + _NL +
	                                        " values.--"
	
	res = ms.grammar.parse("{ } ", 0, null, "LitMap")
	qa.assertEqual ms.str(res.capture),     "[LitMap 1:1 1:3]"                  + _NL +
	                                        " keys.--"                          + _NL +
	                                        " values.--"
	
	res = ms.grammar.parse("{ " + char(10) + " } ", 0, null, "LitMap")
	qa.assertEqual ms.str(res.capture),     "[LitMap 1:1 2:2]"                  + _NL +
	                                        " keys.--"                          + _NL +
	                                        " values.--"
	
	res = ms.grammar.parse("{X: Y} ", 0, null, "LitMap")
	qa.assertEqual ms.str(res.capture),     "[LitMap 1:1 1:6]"                  + _NL +
	                                        " keys.0"                           + _NL +
	                                        "  [Identifier 1:2 1:2] name = X"   + _NL +
	                                        " values.0"                         + _NL +
	                                        "  [Identifier 1:5 1:5] name = Y"
	
	res = ms.grammar.parse("{X : Y , Z : W} ", 0, null, "LitMap")
	qa.assertEqual ms.str(res.capture),     "[LitMap 1:1 1:15]"                 + _NL +
	                                        " keys.0"                           + _NL +
	                                        "  [Identifier 1:2 1:2] name = X"   + _NL +
	                                        " keys.1"                           + _NL +
	                                        "  [Identifier 1:10 1:10] name = Z" + _NL +
	                                        " values.0"                         + _NL +
	                                        "  [Identifier 1:6 1:6] name = Y"   + _NL +
	                                        " values.1"                         + _NL +
	                                        "  [Identifier 1:14 1:14] name = W"
	
	res = ms.grammar.parse("{X : Y , Z : W , } ", 0, null, "LitMap")
	qa.assertEqual ms.str(res.capture),     "[LitMap 1:1 1:18]"                 + _NL +
	                                        " keys.0"                           + _NL +
	                                        "  [Identifier 1:2 1:2] name = X"   + _NL +
	                                        " keys.1"                           + _NL +
	                                        "  [Identifier 1:10 1:10] name = Z" + _NL +
	                                        " values.0"                         + _NL +
	                                        "  [Identifier 1:6 1:6] name = Y"   + _NL +
	                                        " values.1"                         + _NL +
	                                        "  [Identifier 1:14 1:14] name = W"
	
	res = ms.grammar.parse("{X: " + char(10) + " Y, " + char(10) + " Z : W} ", 0, null, "LitMap")
	qa.assertEqual ms.str(res.capture),     "[LitMap 1:1 3:7]"                  + _NL +
	                                        " keys.0"                           + _NL +
	                                        "  [Identifier 1:2 1:2] name = X"   + _NL +
	                                        " keys.1"                           + _NL +
	                                        "  [Identifier 3:2 3:2] name = Z"   + _NL +
	                                        " values.0"                         + _NL +
	                                        "  [Identifier 2:2 2:2] name = Y"   + _NL +
	                                        " values.1"                         + _NL +
	                                        "  [Identifier 3:6 3:6] name = W"
	
	res = ms.grammar.parse("{ ", 0, null, "LitMap")
	qa.assertEqual res.match, null
	qa.assertEqual res.hasErrorType(ms.Continuation), true
	qa.assertEqual res.hasErrorType(ms.ContLine), true
	
	res = ms.grammar.parse("{ X ", 0, null, "LitMap")
	qa.assertEqual res.match, null
	qa.assertEqual res.hasErrorTag("expectedClosingBrace"), true
	qa.assertEqual not res.hasErrorType(ms.Continuation), true
	
	res = ms.grammar.parse("{ X : ", 0, null, "LitMap")
	qa.assertEqual res.match, null
	qa.assertEqual res.hasErrorType(ms.Continuation), true
	qa.assertEqual res.hasErrorType(ms.ContLine), true
	
	res = ms.grammar.parse("{ X : Y ", 0, null, "LitMap")
	qa.assertEqual res.match, null
	qa.assertEqual res.hasErrorTag("expectedClosingBrace"), true
	qa.assertEqual not res.hasErrorType(ms.Continuation), true
	
	res = ms.grammar.parse("{ X : Y , ", 0, null, "LitMap")
	qa.assertEqual res.match, null
	qa.assertEqual res.hasErrorType(ms.Continuation), true
	qa.assertEqual res.hasErrorType(ms.ContLine), true
	
	res = ms.grammar.parse("{ X : Y ,, ", 0, null, "LitMap")
	qa.assertEqual res.match, null
	qa.assertEqual res.hasErrorTag("expectedClosingBrace"), true
	qa.assertEqual not res.hasErrorType(ms.Continuation), true
	
	//
	arg = {}
	arg.features = {}
	arg.features.multilineContinuations = false
	//
	
	res = ms.grammar.parse("{X: " + char(10) + char(10) + " Y} ", 0, arg, "LitMap")
	qa.assertEqual res.match, null
	qa.assertEqual res.hasErrorTag("expectedValue"), true
	qa.assertEqual not res.hasErrorType(ms.Continuation), true
	
	res = ms.grammar.parse("{X: " + char(10) + char(10), 0, arg, "LitMap")
	qa.assertEqual res.match, null
	qa.assertEqual res.hasErrorTag("expectedValue"), true
	qa.assertEqual not res.hasErrorType(ms.Continuation), true
	
	//
	arg = {}
	arg.features = {}
	arg.features.multilineContinuations = true
	//
	
	res = ms.grammar.parse("{X: " + char(10) + char(10) + " Y} ", 0, arg, "LitMap")
	qa.assertEqual ms.str(res.capture),     "[LitMap 1:1 3:3]"                  + _NL +
	                                        " keys.0"                           + _NL +
	                                        "  [Identifier 1:2 1:2] name = X"   + _NL +
	                                        " values.0"                         + _NL +
	                                        "  [Identifier 3:2 3:2] name = Y"
	
	res = ms.grammar.parse("{X: " + char(10) + char(10), 0, arg, "LitMap")
	qa.assertEqual res.match, null
	qa.assertEqual res.hasErrorType(ms.Continuation), true
	qa.assertEqual res.hasErrorType(ms.ContLine), true
end function

