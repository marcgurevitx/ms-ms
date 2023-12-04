import "qa"

//
if not globals.hasIndex("ms") then
	import "ms"
	globals.ms = ms
end if
//


_NL = ms._NL


testStmtEmpty = function
	st = ms.parse("").program.statements[0]
	qa.assertEqual st isa ms.StmtEmpty, true
	res = ms.eval(st)
	qa.assertEqual res, null
	
	//
	params = {}
	params.valueOnNone = "none"
	ctx = ms.Context.assimilateMap({"params": params})
	//
	st = ms.parse("").program.statements[0]
	qa.assertEqual st isa ms.StmtEmpty, true
	res = ms.eval(st, ctx)
	qa.assertEqual res, "none"
	
	//
	params = {}
	params.valueOnNone = function ; return "nada" ; end function
	ctx = ms.Context.assimilateMap({"params": params})
	//
	st = ms.parse("").program.statements[0]
	qa.assertEqual st isa ms.StmtEmpty, true
	res = ms.eval(st, ctx)
	qa.assertEqual res, "nada"
end function
