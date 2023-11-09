import "qa"

//
if not globals.hasIndex("ms") then
	import "ms"
	globals.ms = ms
end if
//


_NL = ms._NL


testParseSimple = function
	res = ms.parse("print ""hello world!""")
	qa.assertEqual ms.str(res.program),     "[Program 1:1 1:20]"                            + _NL +
	                                        " file:"                                        + _NL +
	                                        " shebang:"                                     + _NL +
	                                        " statements.0"                                 + _NL +
	                                        "  [StmtCall 1:1 1:20]"                         + _NL +
	                                        "   callable:"                                  + _NL +
	                                        "    [Identifier 1:1 1:5] name = print"         + _NL +
	                                        "   args.0"                                     + _NL +
	                                        "    [LitString 1:7 1:20] text = hello world!"
	qa.assertEqual res.errors, []
	qa.assertEqual res.comments, {}
	qa.assertEqual res.needMoreInput, false
	qa.assertEqual res._result.length, 20
end function


testParseContinuation = function
	res = ms.parse("print ""hello world!"", ")
	qa.assertEqual res.program, null
	qa.assertEqual res._result.hasErrorType(ms.Continuation), true
	qa.assertEqual res._result.hasErrorType(ms.ContLine), true
	qa.assertEqual res.comments, {}
	qa.assertEqual res.needMoreInput, true
	qa.assertEqual res._result.length, null
	
	res = ms.parse("if true then")
	qa.assertEqual res.program, null
	qa.assertEqual res._result.hasErrorType(ms.Continuation), true
	qa.assertEqual res._result.hasErrorType(ms.ContIf), true
	qa.assertEqual res.comments, {}
	qa.assertEqual res.needMoreInput, true
	qa.assertEqual res._result.length, null
	
	res = ms.parse("f = function; print")
	qa.assertEqual res.program, null
	qa.assertEqual res._result.hasErrorType(ms.Continuation), true
	qa.assertEqual res._result.hasErrorType(ms.ContFunction), true
	qa.assertEqual res.comments, {}
	qa.assertEqual res.needMoreInput, true
	qa.assertEqual res._result.length, null
end function


testParseSyntaxErrors = function
	res = ms.parse("if while print")
	qa.assertEqual res.program, null
	qa.assertEqual res.errors.len > 0, true
	qa.assertEqual not res._result.hasErrorType(ms.Continuation), true
	qa.assertEqual res.comments, {}
	qa.assertEqual res.needMoreInput, false
	qa.assertEqual res._result.length, null
end function


testParseComments = function
	res = ms.parse( "// Hello world program.  (This line is a comment.)"    + char(13) + char(10) +
	                "print ""Hello world!""  // Greet the user."            + char(13) + char(10) +
	                "// End of program (this line is also a comment).")
	qa.assertEqual res.program isa ms.Program, true
	qa.assertEqual res.errors, []
	qa.assertEqual res.comments.len, 3
	qa.assertEqual res.comments[1], " Hello world program.  (This line is a comment.)"
	qa.assertEqual res.comments[2], " Greet the user."
	qa.assertEqual res.comments[3], " End of program (this line is also a comment)."
	qa.assertEqual res.needMoreInput, false
	qa.assertEqual res._result.length != null, true
end function


testParseFeatures = function
	ctx = {}
	ctx.features = {"beheadedFunctions": false}
	res = ms.parse("(function()) ; end function", ctx)
	qa.assertEqual res.program, null
	qa.assertEqual res.errors.len > 0, true
	qa.assertEqual res.comments, {}
	qa.assertEqual res.needMoreInput, false
	qa.assertEqual res._result.length, null
	
	ctx = {}
	ctx.features = {"beheadedFunctions": true}
	res = ms.parse("(function()) ; end function", ctx)
	qa.assertEqual ms.str(res.program),     "[Program 1:1 1:27]" + _NL +
	                                        " file:" + _NL +
	                                        " shebang:" + _NL +
	                                        " statements.0" + _NL +
	                                        "  [StmtCall 1:1 1:12]" + _NL +
	                                        "   callable:" + _NL +
	                                        "    [LitFunction 1:1 1:27]" + _NL +
	                                        "     args.--" + _NL +
	                                        "     defaults.--" + _NL +
	                                        "     statements.--" + _NL +
	                                        "   args.--"
	//qa.assertEqual res.errors, []
	qa.assertEqual res.comments, {}
	qa.assertEqual res.needMoreInput, false
	qa.assertEqual res._result.length, 27
end function


testParseEmpty = function
	res = ms.parse("")
	qa.assertEqual ms.str(res.program),     "[Program 1:0 1:0]"                             + _NL +
	                                        " file:"                                        + _NL +
	                                        " shebang:"                                     + _NL +
	                                        " statements.0"                                 + _NL +
	                                        "  [StmtEmpty 1:0 1:0]"
	qa.assertEqual res.errors, []
	qa.assertEqual res.comments, {}
	qa.assertEqual res.needMoreInput, false
	qa.assertEqual res._result.length, 0
end function

