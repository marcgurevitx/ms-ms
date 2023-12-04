import "qa"

//
if not globals.hasIndex("ms") then
	import "ms"
	globals.ms = ms
end if
//


_NL = ms._NL


testStmtAssign = function
	//
	ns = {}
	ns.locals = {}
	ctx = ms.Context.assimilateMap({"namespaces": ns})
	//
	st = ms.parse("x = 42").program.statements[0]
	qa.assertEqual st isa ms.StmtAssign, true
	res = ms.eval(st, ctx)
	qa.assertEqual res, null
	qa.assertEqual ns.locals.x, 42
	
	//
	ns = {}
	ns.locals = {}
	ns.locals.m = {}
	ctx = ms.Context.assimilateMap({"namespaces": ns})
	//
	st = ms.parse("m.x = 42").program.statements[0]
	qa.assertEqual st isa ms.StmtAssign, true
	res = ms.eval(st, ctx)
	qa.assertEqual res, null
	qa.assertEqual ns.locals.m.x, 42
	
	//
	ns = {}
	ns.locals = {}
	ns.locals.m = {}
	ctx = ms.Context.assimilateMap({"namespaces": ns})
	//
	st = ms.parse("m[""x""] = 42").program.statements[0]
	qa.assertEqual st isa ms.StmtAssign, true
	res = ms.eval(st, ctx)
	qa.assertEqual res, null
	qa.assertEqual ns.locals.m.x, 42
	
	//
	i = 0
	f = function ; outer.i += 1 ; return i ; end function
	ns = {}
	ns.locals = {}
	ns.locals.m = {}
	ns.locals.f = @f
	ctx = ms.Context.assimilateMap({"namespaces": ns})
	//
	st = ms.parse("m[@f] = 42").program.statements[0]
	qa.assertEqual st isa ms.StmtAssign, true
	res = ms.eval(st, ctx)
	qa.assertEqual res, null
	qa.assertEqual ns.locals.m[@f], 42
	qa.assertEqual i, 0
	
	//
	ns = {}
	ns.locals = {}
	ns.locals.x = 42
	ctx = ms.Context.assimilateMap({"namespaces": ns})
	//
	st = ms.parse("x += 43").program.statements[0]
	qa.assertEqual st isa ms.StmtAssign, true
	res = ms.eval(st, ctx)
	qa.assertEqual res, null
	qa.assertEqual ns.locals.x, 85
	
	
	//
	ns = {}
	ns.locals = {}
	ns.locals.m = {}
	ns.locals.m.x = 42
	ctx = ms.Context.assimilateMap({"namespaces": ns})
	//
	st = ms.parse("m.x *= 2").program.statements[0]
	qa.assertEqual st isa ms.StmtAssign, true
	res = ms.eval(st, ctx)
	qa.assertEqual res, null
	qa.assertEqual ns.locals.m.x, 84
	
	//
	ns = {}
	ns.locals = {}
	ns.locals.m = {}
	ns.locals.m.x = 42
	ctx = ms.Context.assimilateMap({"namespaces": ns})
	//
	st = ms.parse("m[""x""] /= 2").program.statements[0]
	qa.assertEqual st isa ms.StmtAssign, true
	res = ms.eval(st, ctx)
	qa.assertEqual res, null
	qa.assertEqual ns.locals.m.x, 21
end function


testStmtAssignLocalFromNonlocal = function
	//
	ns = {}
	ns.locals = {}
	ns.globals = {}
	ns.globals.x = 42
	params = {}
	params.printWarnings = false
	ctx = ms.Context.assimilateMap({"namespaces": ns, "params": params})
	//
	st = ms.parse("x = x").program.statements[0]
	qa.assertEqual st isa ms.StmtAssign, true
	res = ms.eval(st, ctx)
	qa.assertEqual res, null
	qa.assertEqual ns.locals.x, 42
	qa.assertEqual ctx.out.warnings[0] isa ms.LocalFromNonlocalWarning, true
	
	//
	ns = {}
	ns.locals = {}
	ns.globals = {}
	ns.locals.x = 42
	params = {}
	params.printWarnings = false
	ctx = ms.Context.assimilateMap({"namespaces": ns, "params": params})
	//
	st = ms.parse("x = x").program.statements[0]
	qa.assertEqual st isa ms.StmtAssign, true
	res = ms.eval(st, ctx)
	qa.assertEqual res, null
	qa.assertEqual ns.locals.x, 42
	qa.assertEqual ctx.out.warnings.len, 0
end function
