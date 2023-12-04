import "qa"

//
if not globals.hasIndex("ms") then
	import "ms"
	globals.ms = ms
end if
//


_NL = ms._NL


testEvalNodeOr = function
	op = ms.parse("0 or 0").program.statements[0].callable
	qa.assertEqual op isa ms.OpOr, true
	res = ms.eval(op)
	qa.assertEqual res, 0
	
	op = ms.parse("0 or 1").program.statements[0].callable
	qa.assertEqual op isa ms.OpOr, true
	res = ms.eval(op)
	qa.assertEqual res, 1
	
	op = ms.parse("1 or 0").program.statements[0].callable
	qa.assertEqual op isa ms.OpOr, true
	res = ms.eval(op)
	qa.assertEqual res, 1
	
	op = ms.parse("1 or 1").program.statements[0].callable
	qa.assertEqual op isa ms.OpOr, true
	res = ms.eval(op)
	qa.assertEqual res, 1
	
	op = ms.parse("0.5 or 0.2").program.statements[0].callable
	qa.assertEqual op isa ms.OpOr, true
	res = ms.eval(op)
	qa.assertEqual res, 0.6
	
	op = ms.parse("0 or """"").program.statements[0].callable
	qa.assertEqual op isa ms.OpOr, true
	res = ms.eval(op)
	qa.assertEqual res, 0
	
	op = ms.parse("0 or ""foo""").program.statements[0].callable
	qa.assertEqual op isa ms.OpOr, true
	res = ms.eval(op)
	qa.assertEqual res, 1
	
	op = ms.parse(""""" or 1").program.statements[0].callable
	qa.assertEqual op isa ms.OpOr, true
	res = ms.eval(op)
	qa.assertEqual res, 1
	
	op = ms.parse("""foo"" or 0").program.statements[0].callable
	qa.assertEqual op isa ms.OpOr, true
	res = ms.eval(op)
	qa.assertEqual res, 1
	
	op = ms.parse("(function()) or 0 ; end function").program.statements[0].callable
	qa.assertEqual op isa ms.OpOr, true
	res = ms.eval(op)
	qa.assertEqual res, 1
	
	op = ms.parse("0 or (function()) ; end function").program.statements[0].callable
	qa.assertEqual op isa ms.OpOr, true
	res = ms.eval(op)
	qa.assertEqual res, 1
end function


testEvalNodeAnd = function
	op = ms.parse("0 and 0").program.statements[0].callable
	qa.assertEqual op isa ms.OpAnd, true
	res = ms.eval(op)
	qa.assertEqual res, 0
	
	op = ms.parse("0 and 1").program.statements[0].callable
	qa.assertEqual op isa ms.OpAnd, true
	res = ms.eval(op)
	qa.assertEqual res, 0
	
	op = ms.parse("1 and 0").program.statements[0].callable
	qa.assertEqual op isa ms.OpAnd, true
	res = ms.eval(op)
	qa.assertEqual res, 0
	
	op = ms.parse("1 and 1").program.statements[0].callable
	qa.assertEqual op isa ms.OpAnd, true
	res = ms.eval(op)
	qa.assertEqual res, 1
	
	op = ms.parse("0.5 and 0.2").program.statements[0].callable
	qa.assertEqual op isa ms.OpAnd, true
	res = ms.eval(op)
	qa.assertEqual res, 0.1
	
	op = ms.parse("1 and """"").program.statements[0].callable
	qa.assertEqual op isa ms.OpAnd, true
	res = ms.eval(op)
	qa.assertEqual res, 0
	
	op = ms.parse("1 and ""foo""").program.statements[0].callable
	qa.assertEqual op isa ms.OpAnd, true
	res = ms.eval(op)
	qa.assertEqual res, 1
	
	op = ms.parse(""""" and 1").program.statements[0].callable
	qa.assertEqual op isa ms.OpAnd, true
	res = ms.eval(op)
	qa.assertEqual res, 0
	
	op = ms.parse("""foo"" and 1").program.statements[0].callable
	qa.assertEqual op isa ms.OpAnd, true
	res = ms.eval(op)
	qa.assertEqual res, 1
	
	op = ms.parse("(function()) and 1 ; end function").program.statements[0].callable
	qa.assertEqual op isa ms.OpAnd, true
	res = ms.eval(op)
	qa.assertEqual res, 1
	
	op = ms.parse("1 and (function()) ; end function").program.statements[0].callable
	qa.assertEqual op isa ms.OpAnd, true
	res = ms.eval(op)
	qa.assertEqual res, 1
end function


testEvalNodeNot = function
	op = ms.parse("not 0").program.statements[0].callable
	qa.assertEqual op isa ms.OpNot, true
	res = ms.eval(op)
	qa.assertEqual res, 1
	
	op = ms.parse("not 1").program.statements[0].callable
	qa.assertEqual op isa ms.OpNot, true
	res = ms.eval(op)
	qa.assertEqual res, 0
	
	op = ms.parse("not 0.7").program.statements[0].callable
	qa.assertEqual op isa ms.OpNot, true
	res = ms.eval(op)
	qa.assertEqual res, 1 - 0.7
	
	op = ms.parse("not 42").program.statements[0].callable
	qa.assertEqual op isa ms.OpNot, true
	res = ms.eval(op)
	qa.assertEqual res, 0
	
	op = ms.parse("not """"").program.statements[0].callable
	qa.assertEqual op isa ms.OpNot, true
	res = ms.eval(op)
	qa.assertEqual res, 1
	
	op = ms.parse("not ""foo""").program.statements[0].callable
	qa.assertEqual op isa ms.OpNot, true
	res = ms.eval(op)
	qa.assertEqual res, 0
	
	op = ms.parse("not function() ; end function").program.statements[0].callable
	qa.assertEqual op isa ms.OpNot, true
	res = ms.eval(op)
	qa.assertEqual res, 0
end function


testEvalNodeIsa = function
	//
	ns = {}
	ns.intrinsics = {}
	ns.intrinsics.number = number
	ns.intrinsics.string = string
	ns.intrinsics.list = list
	ns.intrinsics.map = map
	ns.intrinsics.funcRef = funcRef
	ns.locals = {}
	ns.locals.M = {}
	ns.locals.N = {}
	ns.locals.m = new ns.locals.M
	ns.locals.f = @print
	ctx = ms.Context.assimilateMap({"namespaces": ns})
	//
	
	op = ms.parse("42 isa number").program.statements[0].callable
	qa.assertEqual op isa ms.OpIsa, true
	res = ms.eval(op, ctx)
	qa.assertEqual res, 1
	
	for prog in ["42 isa string", "42 isa list", "42 isa map", "42 isa funcRef", "42 isa {}", "42 isa M", "42 isa N"]
		op = ms.parse(prog).program.statements[0].callable
		qa.assertEqual op isa ms.OpIsa, true
		res = ms.eval(op, ctx)
		qa.assertEqual res, 0
	end for
	
	op = ms.parse("0 isa number").program.statements[0].callable
	qa.assertEqual op isa ms.OpIsa, true
	res = ms.eval(op, ctx)
	qa.assertEqual res, 1
	
	for prog in ["0 isa string", "0 isa list", "0 isa map", "0 isa funcRef", "0 isa {}", "0 isa M", "0 isa N"]
		op = ms.parse(prog).program.statements[0].callable
		qa.assertEqual op isa ms.OpIsa, true
		res = ms.eval(op, ctx)
		qa.assertEqual res, 0
	end for
	
	op = ms.parse(""""" isa string").program.statements[0].callable
	qa.assertEqual op isa ms.OpIsa, true
	res = ms.eval(op, ctx)
	qa.assertEqual res, 1
	
	for prog in [""""" isa number", """"" isa list", """"" isa map", """"" isa funcRef", """"" isa {}", """"" isa M", """"" isa N"]
		op = ms.parse(prog).program.statements[0].callable
		qa.assertEqual op isa ms.OpIsa, true
		res = ms.eval(op, ctx)
		qa.assertEqual res, 0
	end for
	
	op = ms.parse("""foo"" isa string").program.statements[0].callable
	qa.assertEqual op isa ms.OpIsa, true
	res = ms.eval(op, ctx)
	qa.assertEqual res, 1
	
	for prog in ["""foo"" isa number", """foo"" isa list", """foo"" isa map", """foo"" isa funcRef", """foo"" isa {}", """foo"" isa M", """foo"" isa N"]
		op = ms.parse(prog).program.statements[0].callable
		qa.assertEqual op isa ms.OpIsa, true
		res = ms.eval(op, ctx)
		qa.assertEqual res, 0
	end for
	
	op = ms.parse("[] isa list").program.statements[0].callable
	qa.assertEqual op isa ms.OpIsa, true
	res = ms.eval(op, ctx)
	qa.assertEqual res, 1
	
	for prog in ["[] isa number", "[] isa string", "[] isa map", "[] isa funcRef", "[] isa {}", "[] isa M", "[] isa N"]
		op = ms.parse(prog).program.statements[0].callable
		qa.assertEqual op isa ms.OpIsa, true
		res = ms.eval(op, ctx)
		qa.assertEqual res, 0
	end for
	
	op = ms.parse("[1, 2, 3] isa list").program.statements[0].callable
	qa.assertEqual op isa ms.OpIsa, true
	res = ms.eval(op, ctx)
	qa.assertEqual res, 1
	
	for prog in ["[1, 2, 3] isa number", "[1, 2, 3] isa string", "[1, 2, 3] isa map", "[1, 2, 3] isa funcRef", "[1, 2, 3] isa {}", "[1, 2, 3] isa M", "[1, 2, 3] isa N"]
		op = ms.parse(prog).program.statements[0].callable
		qa.assertEqual op isa ms.OpIsa, true
		res = ms.eval(op, ctx)
		qa.assertEqual res, 0
	end for
	
	op = ms.parse("{} isa map").program.statements[0].callable
	qa.assertEqual op isa ms.OpIsa, true
	res = ms.eval(op, ctx)
	qa.assertEqual res, 1
	
	for prog in ["{} isa number", "{} isa string", "{} isa list", "{} isa funcRef", "{} isa {}", "{} isa M", "{} isa N"]
		op = ms.parse(prog).program.statements[0].callable
		qa.assertEqual op isa ms.OpIsa, true
		res = ms.eval(op, ctx)
		qa.assertEqual res, 0
	end for
	
	op = ms.parse("{""foo"": 42} isa map").program.statements[0].callable
	qa.assertEqual op isa ms.OpIsa, true
	res = ms.eval(op, ctx)
	qa.assertEqual res, 1
	
	for prog in ["{""foo"": 42} isa number", "{""foo"": 42} isa string", "{""foo"": 42} isa list", "{""foo"": 42} isa funcRef", "{""foo"": 42} isa {}", "{""foo"": 42} isa M", "{""foo"": 42} isa N"]
		op = ms.parse(prog).program.statements[0].callable
		qa.assertEqual op isa ms.OpIsa, true
		res = ms.eval(op, ctx)
		qa.assertEqual res, 0
	end for
	
	op = ms.parse("map isa map").program.statements[0].callable
	qa.assertEqual op isa ms.OpIsa, true
	res = ms.eval(op, ctx)
	qa.assertEqual res, 1
	
	op = ms.parse("list isa map").program.statements[0].callable
	qa.assertEqual op isa ms.OpIsa, true
	res = ms.eval(op, ctx)
	qa.assertEqual res, 1
	
	op = ms.parse("number isa map").program.statements[0].callable
	qa.assertEqual op isa ms.OpIsa, true
	res = ms.eval(op, ctx)
	qa.assertEqual res, 1
	
	op = ms.parse("string isa map").program.statements[0].callable
	qa.assertEqual op isa ms.OpIsa, true
	res = ms.eval(op, ctx)
	qa.assertEqual res, 1
	
	op = ms.parse("funcRef isa map").program.statements[0].callable
	qa.assertEqual op isa ms.OpIsa, true
	res = ms.eval(op, ctx)
	qa.assertEqual res, 1
	
	op = ms.parse("M isa map").program.statements[0].callable
	qa.assertEqual op isa ms.OpIsa, true
	res = ms.eval(op, ctx)
	qa.assertEqual res, 1
	
	op = ms.parse("N isa map").program.statements[0].callable
	qa.assertEqual op isa ms.OpIsa, true
	res = ms.eval(op, ctx)
	qa.assertEqual res, 1
	
	op = ms.parse("m isa map").program.statements[0].callable
	qa.assertEqual op isa ms.OpIsa, true
	res = ms.eval(op, ctx)
	qa.assertEqual res, 1
	
	op = ms.parse("m isa M").program.statements[0].callable
	qa.assertEqual op isa ms.OpIsa, true
	res = ms.eval(op, ctx)
	qa.assertEqual res, 1
	
	op = ms.parse("m isa N").program.statements[0].callable
	qa.assertEqual op isa ms.OpIsa, true
	res = ms.eval(op, ctx)
	qa.assertEqual res, 0
	
	op = ms.parse("m isa m").program.statements[0].callable
	qa.assertEqual op isa ms.OpIsa, true
	res = ms.eval(op, ctx)
	qa.assertEqual res, 0
	
	op = ms.parse("(42 isa number) isa number").program.statements[0].callable
	qa.assertEqual op isa ms.OpIsa, true
	res = ms.eval(op, ctx)
	qa.assertEqual res, 1
end function


testEvalNodeCompare = function
	m = {
		"42 == 42": true,
		"42 != 42": false,
		"42 < 42": false,
		"42 > 42": false,
		"42 <= 42": true,
		"42 >= 42": true,
		"42 == 43": false,
		"42 != 43": true,
		"42 < 43": true,
		"42 > 43": false,
		"42 <= 43": true,
		"42 >= 43": false,
		"""a"" == ""a""": true,
		"""a"" != ""a""": false,
		"""a"" == ""b""": false,
		"""a"" != ""b""": true,
		"10 < 15 < 20": true,
		"10 < 5 < 20": false,
		"10 < 25 < 20": false,
		"10 < 10 < 20": false,
		"10 <= 10 < 20": true,
		"10 < 20 < 20": false,
		"10 < 20 <= 20": true,
	}
	for kv in m
		op = ms.parse(kv.key).program.statements[0].callable
		qa.assertEqual op isa ms.OpCompare, true
		res = ms.eval(op)
		qa.assertEqual res, kv.value
	end for
end function


testEvalNodeAdd = function
	op = ms.parse("2 + 3").program.statements[0].callable
	qa.assertEqual op isa ms.OpAdd, true
	res = ms.eval(op)
	qa.assertEqual res, 5
	
	op = ms.parse("""foo"" + ""bar""").program.statements[0].callable
	qa.assertEqual op isa ms.OpAdd, true
	res = ms.eval(op)
	qa.assertEqual res, "foobar"
	
	op = ms.parse("""foo"" + 42").program.statements[0].callable
	qa.assertEqual op isa ms.OpAdd, true
	res = ms.eval(op)
	qa.assertEqual res, "foo42"
	
	op = ms.parse("42 + ""foo""").program.statements[0].callable
	qa.assertEqual op isa ms.OpAdd, true
	res = ms.eval(op)
	qa.assertEqual res, "42foo"
	
	op = ms.parse("[1, 2] + [3, 4]").program.statements[0].callable
	qa.assertEqual op isa ms.OpAdd, true
	res = ms.eval(op)
	qa.assertEqual res, [1, 2, 3, 4]
	
	op = ms.parse("{""a"": 13, ""b"": 14} + {""b"": 15}").program.statements[0].callable
	qa.assertEqual op isa ms.OpAdd, true
	res = ms.eval(op)
	qa.assertEqual res, {"a": 13, "b": 15}
end function


testEvalNodeSubtract = function
	op = ms.parse("2 - 3").program.statements[0].callable
	qa.assertEqual op isa ms.OpSubtract, true
	res = ms.eval(op)
	qa.assertEqual res, -1
	
	op = ms.parse("""foo"" - ""oo""").program.statements[0].callable
	qa.assertEqual op isa ms.OpSubtract, true
	res = ms.eval(op)
	qa.assertEqual res, "f"
	
	op = ms.parse("""foo"" - ""xx""").program.statements[0].callable
	qa.assertEqual op isa ms.OpSubtract, true
	res = ms.eval(op)
	qa.assertEqual res, "foo"
end function


testEvalNodeMultiply = function
	op = ms.parse("2 * 3").program.statements[0].callable
	qa.assertEqual op isa ms.OpMultiply, true
	res = ms.eval(op)
	qa.assertEqual res, 6
	
	op = ms.parse("""foo"" * 3").program.statements[0].callable
	qa.assertEqual op isa ms.OpMultiply, true
	res = ms.eval(op)
	qa.assertEqual res, "foofoofoo"
	
	op = ms.parse("""foo"" * 0.5").program.statements[0].callable
	qa.assertEqual op isa ms.OpMultiply, true
	res = ms.eval(op)
	qa.assertEqual res, "f"
	
	op = ms.parse("[42] * 3").program.statements[0].callable
	qa.assertEqual op isa ms.OpMultiply, true
	res = ms.eval(op)
	qa.assertEqual res, [42, 42, 42]
	
	op = ms.parse("[1, 2, 3] * 0.5").program.statements[0].callable
	qa.assertEqual op isa ms.OpMultiply, true
	res = ms.eval(op)
	qa.assertEqual res, [1]
end function


testEvalNodeDivide = function
	op = ms.parse("1.5 / 3").program.statements[0].callable
	qa.assertEqual op isa ms.OpDivide, true
	res = ms.eval(op)
	qa.assertEqual res, .5
	
	op = ms.parse("""foo"" / 3").program.statements[0].callable
	qa.assertEqual op isa ms.OpDivide, true
	res = ms.eval(op)
	qa.assertEqual res, "f"
	
	op = ms.parse("""foo"" / 0.5").program.statements[0].callable
	qa.assertEqual op isa ms.OpDivide, true
	res = ms.eval(op)
	qa.assertEqual res, "foofoo"
	
	op = ms.parse("[1, 2, 3] / 3").program.statements[0].callable
	qa.assertEqual op isa ms.OpDivide, true
	res = ms.eval(op)
	qa.assertEqual res, [1]
	
	op = ms.parse("[1, 2, 3] / 0.5").program.statements[0].callable
	qa.assertEqual op isa ms.OpDivide, true
	res = ms.eval(op)
	qa.assertEqual res, [1, 2, 3, 1, 2, 3]
end function


testEvalNodeModulo = function
	op = ms.parse("2 % 3").program.statements[0].callable
	qa.assertEqual op isa ms.OpModulo, true
	res = ms.eval(op)
	qa.assertEqual res, 2
end function


testEvalNodeUMinus = function
	op = ms.parse("- 3").program.statements[0].callable
	qa.assertEqual op isa ms.OpUMinus, true
	res = ms.eval(op)
	qa.assertEqual res, -3
end function


testEvalNodeNew = function
	//
	ns = {}
	ns.locals = {}
	ns.locals.M = {}
	ctx = ms.Context.assimilateMap({"namespaces": ns})
	//
	
	op = ms.parse("new M").program.statements[0].callable
	qa.assertEqual op isa ms.OpNew, true
	res = ms.eval(op, ctx)
	qa.assertEqual res isa ns.locals.M, true
end function


testEvalNodeAddress = function
	//
	i = 0
	f = function ; outer.i += 1 ; return i ; end function
	ns = {}
	ns.locals = {}
	ns.locals.f = @f
	ctx = ms.Context.assimilateMap({"namespaces": ns})
	//
	
	op = ms.parse("@f == @f").program.statements[0].callable
	qa.assertEqual op isa ms.OpCompare, true
	res = ms.eval(op, ctx)
	qa.assertEqual res, 1
	qa.assertEqual i, 0
end function


testEvalNodePower = function
	op = ms.parse("2 ^ 3").program.statements[0].callable
	qa.assertEqual op isa ms.OpPower, true
	res = ms.eval(op)
	qa.assertEqual res, 8
end function
