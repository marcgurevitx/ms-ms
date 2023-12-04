import "qa"

//
if not globals.hasIndex("ms") then
	import "ms"
	globals.ms = ms
end if
//


_NL = ms._NL


testStmtFor = function
	//
	ns = {}
	ns.locals = {}
	ns.locals.x = 0
	params = {}
	params.valueOnNone = "none"
	ctx = {"namespaces": ns, "params": params}
	//
	st = ms.parse("for i in [5,6,7] ; x += i ; end for").program.statements[0]
	qa.assertEqual st isa ms.StmtFor, true
	res = ms.eval(st, ctx)
	qa.assertEqual res, "none"
	qa.assertEqual ns.locals.x, 18
	qa.assertEqual ns.locals.i, 7
end function


testStmtForBreak = function
	//
	ns = {}
	ns.locals = {}
	ns.locals.x = 0
	ctx = {"namespaces": ns}
	//
	st = ms.parse("for i in [5,6,7] ; x += i ; break ; end for").program.statements[0]
	qa.assertEqual st isa ms.StmtFor, true
	res = ms.eval(st, ctx)
	qa.assertEqual ns.locals.x, 5
	qa.assertEqual ns.locals.i, 5
	
	//
	ns = {}
	ns.locals = {}
	ns.locals.x = 0
	ctx = {"namespaces": ns}
	//
	st = ms.parse("for i in [5,6,7] ; x += i ; if x >= 10 then break ; end for").program.statements[0]
	qa.assertEqual st isa ms.StmtFor, true
	res = ms.eval(st, ctx)
	qa.assertEqual ns.locals.x, 11
	qa.assertEqual ns.locals.i, 6
end function


testStmtForContinue = function
	//
	ns = {}
	ns.locals = {}
	ns.locals.x = 0
	ns.locals.xx = []
	ctx = {"namespaces": ns}
	//
	st = ms.parse("for i in [5,6,7] ; x += i ; continue ; xx.push x ; end for").program.statements[0]
	qa.assertEqual st isa ms.StmtFor, true
	res = ms.eval(st, ctx)
	qa.assertEqual ns.locals.x, 18
	qa.assertEqual ns.locals.xx, []
	qa.assertEqual ns.locals.i, 7
	
	//
	ns = {}
	ns.locals = {}
	ns.locals.x = 0
	ns.locals.xx = []
	ctx = {"namespaces": ns}
	//
	st = ms.parse("for i in [5,6,7] ; x += i ; if x >= 10 then continue ; xx.push x ; end for").program.statements[0]
	qa.assertEqual st isa ms.StmtFor, true
	res = ms.eval(st, ctx)
	qa.assertEqual ns.locals.x, 18
	qa.assertEqual ns.locals.xx, [5]
	qa.assertEqual ns.locals.i, 7
end function


testStmtForNonsequence = function
	//
	params = {}
	params.valueOnNone = "none"
	ctx = {"params": params}
	//
	st = ms.parse("for i in 42 ; x += i ; end for").program.statements[0]
	qa.assertEqual st isa ms.StmtFor, true
	res = ms.eval(st, ctx)
	qa.assertEqual res, "none"
	
	//
	features = {}
	features.raiseNonsequenceFor = true
	params = {}
	params.catchErrors = ms.NonsequenceForError
	ctx = {"features": features, "params": params}
	//
	st = ms.parse("for i in 42 ; x += i ; end for").program.statements[0]
	qa.assertEqual st isa ms.StmtFor, true
	res = ms.eval(st, ctx)
	qa.assertEqual res, null
	qa.assertEqual ctx.out.type, "error"
	qa.assertEqual ctx.out.error isa ms.NonsequenceForError, true
	qa.assertEqual ctx.out.error.objectType, "LitNumeral"
end function
