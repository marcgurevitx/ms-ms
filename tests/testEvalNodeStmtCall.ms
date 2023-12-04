import "qa"

//
if not globals.hasIndex("ms") then
	import "ms"
	globals.ms = ms
end if
//


_NL = ms._NL


testStmtCall = function
	//
	ns = {}
	ns.locals = {}
	ns.locals.f = function ; return 42 ; end function
	ctx = ms.Context.assimilateMap({"namespaces": ns})
	//
	st = ms.parse("f").program.statements[0]
	qa.assertEqual st isa ms.StmtCall, true
	res = ms.eval(st, ctx)
	qa.assertEqual res, 42
	
	//
	ns = {}
	ns.locals = {}
	ns.locals.f = function(x) ; return x + 42 ; end function
	ctx = ms.Context.assimilateMap({"namespaces": ns})
	//
	st = ms.parse("f 100").program.statements[0]
	qa.assertEqual st isa ms.StmtCall, true
	res = ms.eval(st, ctx)
	qa.assertEqual res, 142
	
	//
	ns = {}
	ns.locals = {}
	ns.locals.f = function(x, y) ; return x + y + 42 ; end function
	ctx = ms.Context.assimilateMap({"namespaces": ns})
	//
	st = ms.parse("f 100, 1000").program.statements[0]
	qa.assertEqual st isa ms.StmtCall, true
	res = ms.eval(st, ctx)
	qa.assertEqual res, 1142
	
	//
	ns = {}
	ns.locals = {}
	ns.locals.f = function(x, y) ; return x + y + 42 ; end function
	ctx = ms.Context.assimilateMap({"namespaces": ns})
	//
	st = ms.parse("{""foo"": @f}.foo 100, 1000").program.statements[0]
	qa.assertEqual st isa ms.StmtCall, true
	res = ms.eval(st, ctx)
	qa.assertEqual res, 1142
	
	//
	ns = {}
	ns.locals = {}
	ns.locals.f = function(x, y) ; return x + y + 42 ; end function
	ctx = ms.Context.assimilateMap({"namespaces": ns})
	//
	st = ms.parse("{""foo"": @f}[""foo""] 100, 1000").program.statements[0]
	qa.assertEqual st isa ms.StmtCall, true
	res = ms.eval(st, ctx)
	qa.assertEqual res, 1142
	
	//
	ns = {}
	ns.locals = {}
	ns.locals.f = function(x, y) ; return self.bar + x + y ; end function
	ctx = ms.Context.assimilateMap({"namespaces": ns})
	//
	st = ms.parse("{""foo"": @f, ""bar"": 42}.foo 100, 1000").program.statements[0]
	qa.assertEqual st isa ms.StmtCall, true
	res = ms.eval(st, ctx)
	qa.assertEqual res, 1142
	
	//
	ns = {}
	ns.locals = {}
	ns.locals.f = function(self, x, y) ; return self.bar + x + y ; end function
	ctx = ms.Context.assimilateMap({"namespaces": ns})
	//
	st = ms.parse("{""foo"": @f, ""bar"": 42}.foo 100, 1000").program.statements[0]
	qa.assertEqual st isa ms.StmtCall, true
	res = ms.eval(st, ctx)
	qa.assertEqual res, 1142
end function
