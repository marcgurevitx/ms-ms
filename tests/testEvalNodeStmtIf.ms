import "qa"

//
if not globals.hasIndex("ms") then
	import "ms"
	globals.ms = ms
end if
//


_NL = ms._NL


testStmtIf = function
	//
	ns = {}
	ns.locals = {}
	params = {}
	params.valueOnNone = "none"
	ctx = ms.Context.assimilateMap({"namespaces": ns, "params": params})
	//
	st = ms.parse("if true then ; x = 42 ; end if").program.statements[0]
	qa.assertEqual st isa ms.StmtIf, true
	res = ms.eval(st, ctx)
	qa.assertEqual res, "none"
	qa.assertEqual ns.locals.x, 42
	
	//
	ns = {}
	ns.locals = {}
	params = {}
	params.valueOnNone = "none"
	ctx = ms.Context.assimilateMap({"namespaces": ns, "params": params})
	//
	st = ms.parse("if false then ; x = 42 ; end if").program.statements[0]
	qa.assertEqual st isa ms.StmtIf, true
	res = ms.eval(st, ctx)
	qa.assertEqual res, "none"
	qa.assertEqual ns.locals.get("x"), null
	
	//
	ns = {}
	ns.locals = {}
	params = {}
	params.valueOnNone = "none"
	ctx = ms.Context.assimilateMap({"namespaces": ns, "params": params})
	//
	st = ms.parse("if false then ; x = 42 ; else ; end if").program.statements[0]
	qa.assertEqual st isa ms.StmtIf, true
	res = ms.eval(st, ctx)
	qa.assertEqual res, "none"
	qa.assertEqual ns.locals.get("x"), null
	
	//
	ns = {}
	ns.locals = {}
	params = {}
	params.valueOnNone = "none"
	ctx = ms.Context.assimilateMap({"namespaces": ns, "params": params})
	//
	st = ms.parse("if false then ; x = 42 ; else ; x = 43 ; end if").program.statements[0]
	qa.assertEqual st isa ms.StmtIf, true
	res = ms.eval(st, ctx)
	qa.assertEqual res, "none"
	qa.assertEqual ns.locals.x, 43
	
	//
	ns = {}
	ns.locals = {}
	params = {}
	params.valueOnNone = "none"
	ctx = ms.Context.assimilateMap({"namespaces": ns, "params": params})
	//
	st = ms.parse("if false then ; x = 42 ; else if true then ; x = 43 ; else if true then ; x = 44 ; else ; x = 45 ; end if").program.statements[0]
	qa.assertEqual st isa ms.StmtIf, true
	res = ms.eval(st, ctx)
	qa.assertEqual res, "none"
	qa.assertEqual ns.locals.x, 43
	
	//
	ns = {}
	ns.locals = {}
	params = {}
	params.valueOnNone = "none"
	ctx = ms.Context.assimilateMap({"namespaces": ns, "params": params})
	//
	st = ms.parse("if true then ; x = 42 ; x = 43 ; x = 44 ; else ; x = 45 ; end if").program.statements[0]
	qa.assertEqual st isa ms.StmtIf, true
	res = ms.eval(st, ctx)
	qa.assertEqual res, "none"
	qa.assertEqual ns.locals.x, 44
end function
