import "qa"

//
if not globals.hasIndex("ms") then
	import "ms"
	globals.ms = ms
end if
//


_NL = ms._NL


testStmtWhile = function
	//
	ns = {}
	ns.locals = {}
	ns.locals.x = 1
	ns.locals.xx = []
	params = {}
	params.valueOnNone = "none"
	ctx = ms.Context.assimilateMap({"namespaces": ns, "params": params})
	//
	st = ms.parse("while x < 5 ; xx.push x ; x += 1 ; end while").program.statements[0]
	qa.assertEqual st isa ms.StmtWhile, true
	res = ms.eval(st, ctx)
	qa.assertEqual res, "none"
	qa.assertEqual ns.locals.x, 5
	qa.assertEqual ns.locals.xx, [1, 2, 3, 4]
	
	//
	ns = {}
	ns.locals = {}
	ns.locals.x = 1
	ns.locals.xx = []
	params = {}
	params.valueOnNone = "none"
	ctx = ms.Context.assimilateMap({"namespaces": ns, "params": params})
	//
	st = ms.parse("while x > 5 ; xx.push x ; x += 1 ; end while").program.statements[0]
	qa.assertEqual st isa ms.StmtWhile, true
	res = ms.eval(st, ctx)
	qa.assertEqual res, "none"
	qa.assertEqual ns.locals.x, 1
	qa.assertEqual ns.locals.xx, []
	
	//
	i = 5
	f = function ; outer.i -= 1 ; return i ; end function
	ns = {}
	ns.locals = {}
	ns.locals.f = @f
	params = {}
	params.valueOnNone = "none"
	ctx = ms.Context.assimilateMap({"namespaces": ns, "params": params})
	//
	st = ms.parse("while f ; end while").program.statements[0]
	qa.assertEqual st isa ms.StmtWhile, true
	res = ms.eval(st, ctx)
	qa.assertEqual res, "none"
	qa.assertEqual i, 0
end function


testStmtWhileBreak = function
	//
	ns = {}
	ns.locals = {}
	ns.locals.x = 1
	ctx = ms.Context.assimilateMap({"namespaces": ns})
	//
	st = ms.parse("while x < 5 ; x += 1 ; break ; end while").program.statements[0]
	qa.assertEqual st isa ms.StmtWhile, true
	res = ms.eval(st, ctx)
	qa.assertEqual ns.locals.x, 2
	
	//
	ns = {}
	ns.locals = {}
	ns.locals.x = 1
	ctx = ms.Context.assimilateMap({"namespaces": ns})
	//
	st = ms.parse("while x < 5 ; x += 1 ; if x > 2 then break ; end while").program.statements[0]
	qa.assertEqual st isa ms.StmtWhile, true
	res = ms.eval(st, ctx)
	qa.assertEqual ns.locals.x, 3
end function


testStmtWhileContinue = function
	//
	ns = {}
	ns.locals = {}
	ns.locals.x = 1
	ns.locals.xx = []
	ctx = ms.Context.assimilateMap({"namespaces": ns})
	//
	st = ms.parse("while x < 5 ; x += 1 ; continue ; xx.push x ; end while").program.statements[0]
	qa.assertEqual st isa ms.StmtWhile, true
	res = ms.eval(st, ctx)
	qa.assertEqual ns.locals.x, 5
	qa.assertEqual ns.locals.xx, []
	
	//
	ns = {}
	ns.locals = {}
	ns.locals.x = 1
	ns.locals.xx = []
	ctx = ms.Context.assimilateMap({"namespaces": ns})
	//
	st = ms.parse("while x < 5 ; x += 1 ; if x > 2 then continue ; xx.push x ; end while").program.statements[0]
	qa.assertEqual st isa ms.StmtWhile, true
	res = ms.eval(st, ctx)
	qa.assertEqual ns.locals.x, 5
	qa.assertEqual ns.locals.xx, [2]
end function
