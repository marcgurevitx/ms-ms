import "qa"

//
if not globals.hasIndex("ms") then
	import "ms"
	globals.ms = ms
end if
//


_NL = ms._NL


testInvFuncEvalWithoutSelf = function
	ctx = new ms.Context
	ctx.init
	
	litFunc = ms.parse("f = function ; return 42 ; end function").program.statements[0].right
	invFunc = new ms.ParsedFunction
	invFunc.init litFunc, ctx
	
	res = invFunc.evalWithoutSelf([], ctx)
	qa.assertEqual res, 42
	
	litFunc = ms.parse("f = function(a) ; return 42 + a ; end function").program.statements[0].right
	invFunc = new ms.ParsedFunction
	invFunc.init litFunc, ctx
	
	res = invFunc.evalWithoutSelf([43], ctx)
	qa.assertEqual res, 85
end function


testInvFuncEvalWithSelf = function
	ctx = new ms.Context
	ctx.init
	
	litFunc = ms.parse("f = function ; return 42 + self.foo ; end function").program.statements[0].right
	invFunc = new ms.ParsedFunction
	invFunc.init litFunc, ctx
	
	res = invFunc.evalWithSelf({"foo": 100}, [], ctx)
	qa.assertEqual res, 142
	
	litFunc = ms.parse("f = function(a) ; return 42 + a + self.foo ; end function").program.statements[0].right
	invFunc = new ms.ParsedFunction
	invFunc.init litFunc, ctx
	
	res = invFunc.evalWithSelf({"foo": 100}, [43], ctx)
	qa.assertEqual res, 185
end function
