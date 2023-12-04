import "qa"

//
if not globals.hasIndex("ms") then
	import "ms"
	globals.ms = ms
end if
//


_NL = ms._NL


testEvalNodeNull = function
	lit = ms.parse("null").program.statements[0].callable
	qa.assertEqual lit isa ms.LitNull, true
	
	res = ms.eval(lit)
	qa.assertEqual res, null
	
	res = ms.eval(lit, {"params": {"valueOnNone": "none"}})
	qa.assertEqual res, null
end function


testEvalNodeTrue = function
	lit = ms.parse("true").program.statements[0].callable
	qa.assertEqual lit isa ms.LitTrue, true
	res = ms.eval(lit)
	qa.assertEqual res, true
end function


testEvalNodeFalse = function
	lit = ms.parse("false").program.statements[0].callable
	qa.assertEqual lit isa ms.LitFalse, true
	res = ms.eval(lit)
	qa.assertEqual res, false
end function


testEvalNodeNumeral = function
	lit = ms.parse("1.23e+4").program.statements[0].callable
	qa.assertEqual lit isa ms.LitNumeral, true
	res = ms.eval(lit)
	qa.assertEqual res, 12300
end function


testEvalNodeString = function
	lit = ms.parse("""foo""").program.statements[0].callable
	qa.assertEqual lit isa ms.LitString, true
	res = ms.eval(lit)
	qa.assertEqual res, "foo"
end function


testEvalNodeList = function
	lit = ms.parse("[]").program.statements[0].callable
	qa.assertEqual lit isa ms.LitList, true
	res = ms.eval(lit)
	qa.assertEqual res, []
	
	lit = ms.parse("[42]").program.statements[0].callable
	qa.assertEqual lit isa ms.LitList, true
	res = ms.eval(lit)
	qa.assertEqual res, [42]
	
	lit = ms.parse("[true, null, ""foo"", [5, 6 + 7, 8]]").program.statements[0].callable
	qa.assertEqual lit isa ms.LitList, true
	res = ms.eval(lit)
	qa.assertEqual res, [true, null, "foo", [5, 13, 8]]
	
	//
	i = 0
	f = function ; outer.i += 1 ; return i ; end function
	ns = {}
	ns.locals = {}
	ns.locals.f = @f
	ctx = ms.Context.assimilateMap({"namespaces": ns})
	//
	
	lit = ms.parse("[@f]").program.statements[0].callable
	qa.assertEqual lit isa ms.LitList, true
	res = ms.eval(lit, ctx)
	qa.assertEqual res, [@f]
	qa.assertEqual i, 0
end function


testEvalNodeMap = function
	lit = ms.parse("{}").program.statements[0].callable
	qa.assertEqual lit isa ms.LitMap, true
	res = ms.eval(lit)
	qa.assertEqual res, {}
	
	lit = ms.parse("{""foo"": 42}").program.statements[0].callable
	qa.assertEqual lit isa ms.LitMap, true
	res = ms.eval(lit)
	qa.assertEqual res, {"foo": 42}
	
	lit = ms.parse("{true: false, ""foo"": 42, ""bar"": {43: 44}}").program.statements[0].callable
	qa.assertEqual lit isa ms.LitMap, true
	res = ms.eval(lit)
	qa.assertEqual res.len, 3
	qa.assertEqual res[true], false
	qa.assertEqual res.foo, 42
	qa.assertEqual res.bar, {43: 44}
	
	lit = ms.parse("{""foo"": 42, ""foo"": 43}").program.statements[0].callable
	qa.assertEqual lit isa ms.LitMap, true
	res = ms.eval(lit)
	qa.assertEqual res, {"foo": 43}
	
	//
	i = 0
	f = function ; outer.i += 1 ; return i ; end function
	ns = {}
	ns.locals = {}
	ns.locals.f = @f
	ctx = ms.Context.assimilateMap({"namespaces": ns})
	//
	
	lit = ms.parse("{@f:@f}").program.statements[0].callable
	qa.assertEqual lit isa ms.LitMap, true
	res = ms.eval(lit, ctx)
	qa.assertEqual res, {@f:@f}
	qa.assertEqual i, 0
end function
