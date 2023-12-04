import "qa"

//
if not globals.hasIndex("ms") then
	import "ms"
	globals.ms = ms
end if
//


_NL = ms._NL


testParseFile = function
	res = ms.parseFile("tests/files/pf001.txt")
	qa.assertEqual ms.str(res.program),     "[Program 1:1 1:20]"                            + _NL +
	                                        " file:"                                        + _NL +
	                                        "  ""tests/files/pf001.txt"""                       + _NL +
	                                        " shebang:"                                     + _NL +
	                                        " statements.0"                                 + _NL +
	                                        "  [StmtCall 1:1 1:20]"                         + _NL +
	                                        "   callable:"                                  + _NL +
	                                        "    [Identifier 1:1 1:5] name = ""print"""         + _NL +
	                                        "   args.0"                                     + _NL +
	                                        "    [LitString 1:7 1:20] text = ""hello world!"""
	qa.assertEqual res.errors, []
	qa.assertEqual res.comments, {}
	qa.assertEqual res._result.length, 20
end function


testParseFileBad = function
	res = ms.parseFile("tests/files/pf002.txt")
	qa.assertEqual res.program, null
	qa.assertEqual res.errors.len > 0, true
	qa.assertEqual res.comments, {}
	qa.assertEqual res._result.length, null
end function


testParseFileEmpty = function
	res = ms.parseFile("tests/files/pf003.txt")
	qa.assertEqual ms.str(res.program),     "[Program 1:0 1:0]"                             + _NL +
	                                        " file:"                                        + _NL +
	                                        "  ""tests/files/pf003.txt"""                       + _NL +
	                                        " shebang:"                                     + _NL +
	                                        " statements.0"                                 + _NL +
	                                        "  [StmtEmpty 1:0 1:0]"
	qa.assertEqual res.errors, []
	qa.assertEqual res.comments, {}
	qa.assertEqual res._result.length, 0
end function


testParseFileShebang = function
	res = ms.parseFile("tests/files/pf004.txt")
	qa.assertEqual ms.str(res.program),     "[Program 1:1 2:20]"                            + _NL +
	                                        " file:"                                        + _NL +
	                                        "  ""tests/files/pf004.txt"""                       + _NL +
	                                        " shebang:"                                     + _NL +
	                                        "  "" /foo/bar baz"""                               + _NL +
	                                        " statements.0"                                 + _NL +
	                                        "  [StmtCall 2:1 2:20]"                         + _NL +
	                                        "   callable:"                                  + _NL +
	                                        "    [Identifier 2:1 2:5] name = ""print"""         + _NL +
	                                        "   args.0"                                     + _NL +
	                                        "    [LitString 2:7 2:20] text = ""hello world!"""
	qa.assertEqual res.errors, []
	qa.assertEqual res.comments, {}
	qa.assertEqual res._result.length, 36
end function


testParseFileMultilineStrings = function
	res = ms.parseFile("tests/files/pf005.txt")
	qa.assertEqual ms.str(res.program),     "[Program 1:1 2:6]"                             + _NL +
	                                        " file:"                                        + _NL +
	                                        "  ""tests/files/pf005.txt"""                       + _NL +
	                                        " shebang:"                                     + _NL +
	                                        " statements.0"                                 + _NL +
	                                        "  [StmtAssign 1:1 2:6] math = """""                + _NL +
	                                        "   left:"                                      + _NL +
	                                        "    [Identifier 1:1 1:1] name = ""x"""             + _NL +
	                                        "   right:"                                     + _NL +
	                                        "    [LitString 1:5 2:6] text = ""hello←world"""
end function


testParseFileMultilineContinuations = function
	res = ms.parseFile("tests/files/pf006.txt")
	qa.assertEqual ms.str(res.program),     "[Program 1:1 7:3]"                             + _NL +
	                                        " file:"                                        + _NL +
	                                        "  ""tests/files/pf006.txt"""                       + _NL +
	                                        " shebang:"                                     + _NL +
	                                        " statements.0"                                 + _NL +
	                                        "  [StmtAssign 1:1 7:3] math = """""                + _NL +
	                                        "   left:"                                      + _NL +
	                                        "    [Identifier 1:1 1:1] name = ""x"""             + _NL +
	                                        "   right:"                                     + _NL +
	                                        "    [LitMap 1:5 7:3]"                          + _NL +
	                                        "     keys.0"                                   + _NL +
	                                        "      [LitNumeral 1:6 1:7] int = ""13"", fract = null, eSign = null, exp = null, val = 13" + _NL +
	                                        "     values.0"                                                                             + _NL +
	                                        "      [LitNumeral 7:1 7:2] int = ""14"", fract = null, eSign = null, exp = null, val = 14"
end function


testParseFileContext = function
	res = ms.parseFile("tests/files/pf006.txt", {"features": {"multilineContinuations": false}})
	qa.assertEqual res.program, null
	qa.assertEqual res.errors.len > 0, true
	qa.assertEqual res.comments, {}
	qa.assertEqual res._result.length, null
end function


testParseFileContext = function
	res = ms.parseFile("tests/files/pf007.txt")
	qa.assertEqual res.program.programName == "tests/files/pf007.txt", true
	qa.assertEqual res.program.statements[0].programName == "tests/files/pf007.txt", true
	qa.assertEqual res.program.statements[0].callable.programName == "tests/files/pf007.txt", true
	qa.assertEqual res.program.statements[0].callable.operands[0].programName == "tests/files/pf007.txt", true
	qa.assertEqual res.program.statements[0].callable.operands[1].programName == "tests/files/pf007.txt", true
	
	res = ms.parseFile("tests/files/pf007.txt", {"params": {"programName": "foo"}})
	qa.assertEqual res.program.programName == "foo", true
	qa.assertEqual res.program.statements[0].programName == "foo", true
	qa.assertEqual res.program.statements[0].callable.programName == "foo", true
	qa.assertEqual res.program.statements[0].callable.operands[0].programName == "foo", true
	qa.assertEqual res.program.statements[0].callable.operands[1].programName == "foo", true
end function
