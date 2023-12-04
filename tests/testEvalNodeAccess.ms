import "qa"

//
if not globals.hasIndex("ms") then
	import "ms"
	globals.ms = ms
end if
//


_NL = ms._NL


testEvalNodeIndex = function
	op = ms.parse("{""foo"": 42}[""foo""]").program.statements[0].callable
	qa.assertEqual op isa ms.OpIndex, true
	res = ms.eval(op)
	qa.assertEqual res, 42
	
	op = ms.parse("""foo""[1]").program.statements[0].callable
	qa.assertEqual op isa ms.OpIndex, true
	res = ms.eval(op)
	qa.assertEqual res, "o"
	
	op = ms.parse("[1, 2, 3][1]").program.statements[0].callable
	qa.assertEqual op isa ms.OpIndex, true
	res = ms.eval(op)
	qa.assertEqual res, 2
	
	//
	i = 0
	f = function ; outer.i += 1 ; return i ; end function
	ns = {}
	ns.locals = {}
	ns.locals.f = @f
	ctx = ms.Context.assimilateMap({"namespaces": ns})
	//
	
	op = ms.parse("{@f: @f}[@f]").program.statements[0].callable
	qa.assertEqual op isa ms.OpIndex, true
	res = ms.eval(op, ctx)
	qa.assertEqual @res == @f, true
	qa.assertEqual i, 0
end function


testEvalNodeSlice = function
	op = ms.parse("""hello""[1:-1]").program.statements[0].callable
	qa.assertEqual op isa ms.OpSlice, true
	res = ms.eval(op)
	qa.assertEqual res, "ell"
	
	op = ms.parse("""hello""[1:]").program.statements[0].callable
	qa.assertEqual op isa ms.OpSlice, true
	res = ms.eval(op)
	qa.assertEqual res, "ello"
	
	op = ms.parse("""hello""[:-1]").program.statements[0].callable
	qa.assertEqual op isa ms.OpSlice, true
	res = ms.eval(op)
	qa.assertEqual res, "hell"
	
	op = ms.parse("""hello""[:]").program.statements[0].callable
	qa.assertEqual op isa ms.OpSlice, true
	res = ms.eval(op)
	qa.assertEqual res, "hello"
	
	op = ms.parse("""hello""[-4:4]").program.statements[0].callable
	qa.assertEqual op isa ms.OpSlice, true
	res = ms.eval(op)
	qa.assertEqual res, "ell"
	
	op = ms.parse("[1, 2, 3, 4, 5][1:-1]").program.statements[0].callable
	qa.assertEqual op isa ms.OpSlice, true
	res = ms.eval(op)
	qa.assertEqual res, [2, 3, 4]
	
	op = ms.parse("[1, 2, 3, 4, 5][1:]").program.statements[0].callable
	qa.assertEqual op isa ms.OpSlice, true
	res = ms.eval(op)
	qa.assertEqual res, [2, 3, 4, 5]
	
	op = ms.parse("[1, 2, 3, 4, 5][:-1]").program.statements[0].callable
	qa.assertEqual op isa ms.OpSlice, true
	res = ms.eval(op)
	qa.assertEqual res, [1, 2, 3, 4]
	
	op = ms.parse("[1, 2, 3, 4, 5][:]").program.statements[0].callable
	qa.assertEqual op isa ms.OpSlice, true
	res = ms.eval(op)
	qa.assertEqual res, [1, 2, 3, 4, 5]
	
	op = ms.parse("[1, 2, 3, 4, 5][-4:4]").program.statements[0].callable
	qa.assertEqual op isa ms.OpSlice, true
	res = ms.eval(op)
	qa.assertEqual res, [2, 3, 4]
end function


testEvalNodeDot = function
	op = ms.parse("{""foo"": 42}.foo").program.statements[0].callable
	qa.assertEqual op isa ms.OpDot, true
	res = ms.eval(op)
	qa.assertEqual res, 42
	
	//
	params = {}
	params.catchErrors = ms.KeyNotFoundError
	ctx = ms.Context.assimilateMap({"params": params})
	//
	op = ms.parse("{}.foo").program.statements[0].callable
	qa.assertEqual op isa ms.OpDot, true
	res = ms.eval(op, ctx)
	qa.assertEqual res, null
	qa.assertEqual ctx.out.type, "error"
	qa.assertEqual ctx.out.error isa ms.KeyNotFoundError, true
	qa.assertEqual ctx.out.error.index, "foo"
	
	//
	i = 0
	f = function ; outer.i += 1 ; return i ; end function
	ns = {}
	ns.locals = {}
	ns.locals.f = @f
	ctx = ms.Context.assimilateMap({"namespaces": ns})
	//
	op = ms.parse("{""foo"": @f}.foo").program.statements[0].callable
	qa.assertEqual op isa ms.OpDot, true
	res = ms.eval(op, ctx)
	qa.assertEqual @res == 1, true
	qa.assertEqual i, 1
	
	//
	i = 0
	f = function ; outer.i += 1 ; return i ; end function
	ns = {}
	ns.locals = {}
	ns.locals.f = @f
	ctx = ms.Context.assimilateMap({"namespaces": ns})
	//
	op = ms.parse("@{""foo"": @f}.foo").program.statements[0].callable
	qa.assertEqual op isa ms.OpAddress, true
	res = ms.eval(op, ctx)
	qa.assertEqual @res == @f, true
	qa.assertEqual i, 0
	
	//
	f = function ; return self.bar ; end function
	ns = {}
	ns.locals = {}
	ns.locals.f = @f
	ctx = ms.Context.assimilateMap({"namespaces": ns})
	//
	op = ms.parse("{""foo"": @f, ""bar"": 42}.foo").program.statements[0].callable
	qa.assertEqual op isa ms.OpDot, true
	res = ms.eval(op, ctx)
	qa.assertEqual res, 42
end function


testEvalNodeCall = function
	//
	f = function(x=0, y=0) ; return x + y ; end function
	ns = {}
	ns.locals = {}
	ns.locals.f = @f
	ctx = ms.Context.assimilateMap({"namespaces": ns})
	//
	
	op = ms.parse("f()").program.statements[0].callable
	qa.assertEqual op isa ms.OpCall, true
	res = ms.eval(op, ctx)
	qa.assertEqual res, 0
	
	op = ms.parse("f(42)").program.statements[0].callable
	qa.assertEqual op isa ms.OpCall, true
	res = ms.eval(op, ctx)
	qa.assertEqual res, 42
	
	op = ms.parse("f(42, 43)").program.statements[0].callable
	qa.assertEqual op isa ms.OpCall, true
	res = ms.eval(op, ctx)
	qa.assertEqual res, 85
	
	op = ms.parse("{""foo"": @f}.foo()").program.statements[0].callable
	qa.assertEqual op isa ms.OpCall, true
	res = ms.eval(op, ctx)
	qa.assertEqual res, 0
	
	op = ms.parse("{""foo"": @f}.foo(42)").program.statements[0].callable
	qa.assertEqual op isa ms.OpCall, true
	res = ms.eval(op, ctx)
	qa.assertEqual res, 42
	
	op = ms.parse("{""foo"": @f}.foo(42, 43)").program.statements[0].callable
	qa.assertEqual op isa ms.OpCall, true
	res = ms.eval(op, ctx)
	qa.assertEqual res, 85
	
	//
	f = function(x=0) ; return self.bar + x ; end function
	ns = {}
	ns.locals = {}
	ns.locals.f = @f
	ctx = ms.Context.assimilateMap({"namespaces": ns})
	//
	
	op = ms.parse("{""foo"": @f, ""bar"": 42}.foo()").program.statements[0].callable
	qa.assertEqual op isa ms.OpCall, true
	res = ms.eval(op, ctx)
	qa.assertEqual res, 42
	
	op = ms.parse("{""foo"": @f, ""bar"": 42}.foo(43)").program.statements[0].callable
	qa.assertEqual op isa ms.OpCall, true
	res = ms.eval(op, ctx)
	qa.assertEqual res, 85
	
	//
	f = function(self, x=0) ; return self.bar + x ; end function
	ns = {}
	ns.locals = {}
	ns.locals.f = @f
	ctx = ms.Context.assimilateMap({"namespaces": ns})
	//
	
	op = ms.parse("{""foo"": @f, ""bar"": 42}.foo()").program.statements[0].callable
	qa.assertEqual op isa ms.OpCall, true
	res = ms.eval(op, ctx)
	qa.assertEqual res, 42
	
	op = ms.parse("{""foo"": @f, ""bar"": 42}.foo(43)").program.statements[0].callable
	qa.assertEqual op isa ms.OpCall, true
	res = ms.eval(op, ctx)
	qa.assertEqual res, 85
end function
