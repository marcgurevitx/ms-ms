import "qa"

//
if not globals.hasIndex("ms") then
	import "ms"
	globals.ms = ms
end if
//


_NL = ms._NL


testEvalFileBasic = function
	s = null
	
	ns = {}
	ns.locals = {}
	ns.locals.print = function(x) ; outer.s = x ; end function
	ctx = {"namespaces": ns}
	
	res = ms.evalFile("tests/files/pf001.txt", ctx)
	
	qa.assertEqual refEquals(res, ns.locals), true
	qa.assertEqual s, "hello world!"
end function


testEvalFileParseError = function
	params = {}
	params.catchErrors = ms.ParseError
	ctx = {"params": params}
	
	res = ms.evalFile("tests/files/pf002.txt", ctx)
	
	qa.assertEqual res, null
	qa.assertEqual ctx.out.type, "error"
	qa.assertEqual ctx.out.error isa ms.ParseError, true
end function


testEvalFileParseEmpty = function
	res = ms.evalFile("tests/files/pf003.txt")
	qa.assertEqual res, {}
end function


testEvalFileParseMLStrings = function
	res = ms.evalFile("tests/files/pf005.txt")
	qa.assertEqual res.x.startsWith("hello"), true
	qa.assertEqual res.x.endsWith("world"), true
end function


testEvalFileParseMLContinuations = function
	res = ms.evalFile("tests/files/pf006.txt")
	qa.assertEqual res.x[13], 14
end function


testEvalFileParseIdentifierError = function
	params = {}
	params.catchErrors = ms.UnknownIdentifierError
	ctx = {"params": params}
	
	res = ms.evalFile("tests/files/pf007.txt", ctx)
	
	qa.assertEqual res, null
	qa.assertEqual ctx.out.type, "error"
	qa.assertEqual ctx.out.error isa ms.UnknownIdentifierError, true
	qa.assertEqual ctx.out.error.name, "A"
end function


testEvalFileParseSum = function
	ns = {}
	ns.locals = {}
	ns.locals.A = 42
	ns.locals.B = 43
	ctx = {"namespaces": ns}
	
	res = ms.evalFile("tests/files/pf007.txt", ctx)
	
	qa.assertEqual res, {"A": 42, "B": 43}
	qa.assertEqual ctx.out.type, "result"
end function


testEvalFileParseCustomReturn = function
	ctx = {}
	
	res = ms.evalFile("tests/files/pf008.txt", ctx)
	
	qa.assertEqual res, {"foo": 42}
	qa.assertEqual ctx.out.type, "return"
end function
