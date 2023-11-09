import "qa"

//
if not globals.hasIndex("ms") then
	import "ms"
	globals.ms = ms
end if
//


_NL = ms._NL


testGrammarComment = function
	arg = {}
	arg.comments = {}
	res = ms.grammar.parse("", 0, arg, "Comment")
	qa.assertEqual res.match, null
	qa.assertEqual arg.comments, {}
	
	arg = {}
	arg.comments = {}
	res = ms.grammar.parse("/ foo bar", 0, arg, "Comment")
	qa.assertEqual res.match, null
	qa.assertEqual arg.comments, {}
	
	arg = {}
	arg.comments = {}
	res = ms.grammar.parse("// foo bar", 0, arg, "Comment")
	qa.assertEqual res.match.fragment, "// foo bar"
	qa.assertEqual arg.comments[1], " foo bar"
	
	arg = {}
	arg.comments = {}
	res = ms.grammar.parse("  // foo bar", 2, arg, "Comment")
	qa.assertEqual res.match.fragment, "// foo bar"
	qa.assertEqual arg.comments.indexes, [1]
	qa.assertEqual arg.comments[1], " foo bar"
	
	arg = {}
	arg.comments = {}
	res = ms.grammar.parse("// foo bar" + char(13) + "baz", 0, arg, "Comment")
	qa.assertEqual res.match.fragment, "// foo bar"
	qa.assertEqual arg.comments.indexes, [1]
	qa.assertEqual arg.comments[1], " foo bar"
	
	arg = {}
	arg.comments = {}
	res = ms.grammar.parse(char(10) + char(10) + "// foo bar" + char(13) + "baz", 2, arg, "Comment")
	qa.assertEqual res.match.fragment, "// foo bar"
	qa.assertEqual arg.comments.indexes, [3]
	qa.assertEqual arg.comments[3], " foo bar"
end function


testGrammarKeyword = function
	res = ms.grammar.parse("", 0, null, "Keyword")
	qa.assertEqual res.match, null
	
	res = ms.grammar.parse("and", 0, null, "Keyword")
	qa.assertEqual res.match.fragment, "and"
	res = ms.grammar.parse("and ", 0, null, "Keyword")
	qa.assertEqual res.match.fragment, "and"
	res = ms.grammar.parse("andX ", 0, null, "Keyword")
	qa.assertEqual res.match, null
	
	res = ms.grammar.parse("break", 0, null, "Keyword")
	qa.assertEqual res.match.fragment, "break"
	res = ms.grammar.parse("break ", 0, null, "Keyword")
	qa.assertEqual res.match.fragment, "break"
	res = ms.grammar.parse("breakX ", 0, null, "Keyword")
	qa.assertEqual res.match, null
	
	res = ms.grammar.parse("continue", 0, null, "Keyword")
	qa.assertEqual res.match.fragment, "continue"
	res = ms.grammar.parse("continue ", 0, null, "Keyword")
	qa.assertEqual res.match.fragment, "continue"
	res = ms.grammar.parse("continueX ", 0, null, "Keyword")
	qa.assertEqual res.match, null
	
	res = ms.grammar.parse("else", 0, null, "Keyword")
	qa.assertEqual res.match.fragment, "else"
	res = ms.grammar.parse("else ", 0, null, "Keyword")
	qa.assertEqual res.match.fragment, "else"
	res = ms.grammar.parse("elseX ", 0, null, "Keyword")
	qa.assertEqual res.match, null
	
	res = ms.grammar.parse("end", 0, null, "Keyword")
	qa.assertEqual res.match.fragment, "end"
	res = ms.grammar.parse("end ", 0, null, "Keyword")
	qa.assertEqual res.match.fragment, "end"
	res = ms.grammar.parse("endX ", 0, null, "Keyword")
	qa.assertEqual res.match, null
	
	res = ms.grammar.parse("false", 0, null, "Keyword")
	qa.assertEqual res.match.fragment, "false"
	res = ms.grammar.parse("false ", 0, null, "Keyword")
	qa.assertEqual res.match.fragment, "false"
	res = ms.grammar.parse("falseX ", 0, null, "Keyword")
	qa.assertEqual res.match, null
	
	res = ms.grammar.parse("for", 0, null, "Keyword")
	qa.assertEqual res.match.fragment, "for"
	res = ms.grammar.parse("for ", 0, null, "Keyword")
	qa.assertEqual res.match.fragment, "for"
	res = ms.grammar.parse("forX ", 0, null, "Keyword")
	qa.assertEqual res.match, null
	
	res = ms.grammar.parse("function", 0, null, "Keyword")
	qa.assertEqual res.match.fragment, "function"
	res = ms.grammar.parse("function ", 0, null, "Keyword")
	qa.assertEqual res.match.fragment, "function"
	res = ms.grammar.parse("functionX ", 0, null, "Keyword")
	qa.assertEqual res.match, null
	
	res = ms.grammar.parse("if", 0, null, "Keyword")
	qa.assertEqual res.match.fragment, "if"
	res = ms.grammar.parse("if ", 0, null, "Keyword")
	qa.assertEqual res.match.fragment, "if"
	res = ms.grammar.parse("ifX ", 0, null, "Keyword")
	qa.assertEqual res.match, null
	
	res = ms.grammar.parse("in", 0, null, "Keyword")
	qa.assertEqual res.match.fragment, "in"
	res = ms.grammar.parse("in ", 0, null, "Keyword")
	qa.assertEqual res.match.fragment, "in"
	res = ms.grammar.parse("inX ", 0, null, "Keyword")
	qa.assertEqual res.match, null
	
	res = ms.grammar.parse("isa", 0, null, "Keyword")
	qa.assertEqual res.match.fragment, "isa"
	res = ms.grammar.parse("isa ", 0, null, "Keyword")
	qa.assertEqual res.match.fragment, "isa"
	res = ms.grammar.parse("isaX ", 0, null, "Keyword")
	qa.assertEqual res.match, null
	
	res = ms.grammar.parse("new", 0, null, "Keyword")
	qa.assertEqual res.match.fragment, "new"
	res = ms.grammar.parse("new ", 0, null, "Keyword")
	qa.assertEqual res.match.fragment, "new"
	res = ms.grammar.parse("newX ", 0, null, "Keyword")
	qa.assertEqual res.match, null
	
	res = ms.grammar.parse("not", 0, null, "Keyword")
	qa.assertEqual res.match.fragment, "not"
	res = ms.grammar.parse("not ", 0, null, "Keyword")
	qa.assertEqual res.match.fragment, "not"
	res = ms.grammar.parse("notX ", 0, null, "Keyword")
	qa.assertEqual res.match, null
	
	res = ms.grammar.parse("null", 0, null, "Keyword")
	qa.assertEqual res.match.fragment, "null"
	res = ms.grammar.parse("null ", 0, null, "Keyword")
	qa.assertEqual res.match.fragment, "null"
	res = ms.grammar.parse("nullX ", 0, null, "Keyword")
	qa.assertEqual res.match, null
	
	res = ms.grammar.parse("or", 0, null, "Keyword")
	qa.assertEqual res.match.fragment, "or"
	res = ms.grammar.parse("or ", 0, null, "Keyword")
	qa.assertEqual res.match.fragment, "or"
	res = ms.grammar.parse("orX ", 0, null, "Keyword")
	qa.assertEqual res.match, null
	
	res = ms.grammar.parse("return", 0, null, "Keyword")
	qa.assertEqual res.match.fragment, "return"
	res = ms.grammar.parse("return ", 0, null, "Keyword")
	qa.assertEqual res.match.fragment, "return"
	res = ms.grammar.parse("returnX ", 0, null, "Keyword")
	qa.assertEqual res.match, null
	
	res = ms.grammar.parse("then", 0, null, "Keyword")
	qa.assertEqual res.match.fragment, "then"
	res = ms.grammar.parse("then ", 0, null, "Keyword")
	qa.assertEqual res.match.fragment, "then"
	res = ms.grammar.parse("thenX ", 0, null, "Keyword")
	qa.assertEqual res.match, null
	
	res = ms.grammar.parse("true", 0, null, "Keyword")
	qa.assertEqual res.match.fragment, "true"
	res = ms.grammar.parse("true ", 0, null, "Keyword")
	qa.assertEqual res.match.fragment, "true"
	res = ms.grammar.parse("trueX ", 0, null, "Keyword")
	qa.assertEqual res.match, null
	
	res = ms.grammar.parse("while", 0, null, "Keyword")
	qa.assertEqual res.match.fragment, "while"
	res = ms.grammar.parse("while ", 0, null, "Keyword")
	qa.assertEqual res.match.fragment, "while"
	res = ms.grammar.parse("whileX ", 0, null, "Keyword")
	qa.assertEqual res.match, null
end function

