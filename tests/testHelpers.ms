import "qa"

//
if not globals.hasIndex("ms") then
	import "ms"
	globals.ms = ms
end if
//


_NL = ms._NL


testToFuncRef = function
	x = null
	res = ms.toFuncRef(@x)
	qa.assertEqual res, null
	
	x = 42
	res = ms.toFuncRef(@x)
	qa.assertEqual res, 42
	
	x = "foo"
	res = ms.toFuncRef(@x)
	qa.assertEqual res, "foo"
	
	f = function ; end function
	x = @f
	res = ms.toFuncRef(@x)
	qa.assertEqual @res == @f, true
	
	x = [5,"hello",null, @f]
	res = ms.toFuncRef(@x)
	qa.assertEqual res, [5,"hello",null, @f]
	
	x = {5:"hello",null: @f}
	res = ms.toFuncRef(@x)
	qa.assertEqual res, {5:"hello",null: @f}
	
	x = [5, ["hello", [null, null]]]
	x[1][1][1] = x
	res = ms.toFuncRef(@x)
	qa.assertEqual res, x
	
	x = {"foo": {"bar": {"baz": null}}}
	x.foo.bar.baz = x
	res = ms.toFuncRef(@x)
	qa.assertEqual res, x
	
	
	//
	ctx = new ms.Context
	ctx.init
	//
	
	
	litFunc = ms.parse("f = function ; return 42 ; end function").program.statements[0].right
	inv = new ms.ParsedFunction
	inv.init litFunc, ctx
	
	x = inv
	res = ms.toFuncRef(@x)
	qa.assertEqual @res isa funcRef, true
	qa.assertEqual res, 42
	
	
	litFunc = ms.parse("f = function ; return 42 ; end function").program.statements[0].right
	inv = new ms.ParsedFunction
	inv.init litFunc, ctx
	
	x = [11, 12, {"foo": inv}]
	res = ms.toFuncRef(@x)
	qa.assertEqual @res[2].foo isa funcRef, true
	qa.assertEqual @res[2].foo == @x[2].foo, true
	qa.assertEqual res[2].foo, 42
	
	
	litFunc = ms.parse("f = function(self, a) ; return 42 + self.foo + a ; end function").program.statements[0].right
	inv = new ms.ParsedFunction
	inv.init litFunc, ctx
	
	x = inv
	res = ms.toFuncRef(@x)
	qa.assertEqual res({"foo": 100}, 43), 185
	
	
	litFunc = ms.parse("f = function(self, a) ; return 42 + self.foo + a ; end function").program.statements[0].right
	inv = new ms.ParsedFunction
	inv.init litFunc, ctx
	
	x = inv
	res = ms.toFuncRef(@x)
	m = {"foo": 100}
	m.f = @res
	qa.assertEqual m.f(43), 185
	
	
	litFunc = ms.parse("f = function(a) ; return 42 + self.foo + a ; end function").program.statements[0].right
	inv = new ms.ParsedFunction
	inv.init litFunc, ctx
	
	x = inv
	res = ms.toFuncRef(@x)
	m = {"foo": 100}
	m.f = @res
	qa.assertEqual m.f(43), 185
end function


testToFuncRefIsaLoop = function
	m = {}
	m.__isa = m
	res = ms.toFuncRef(@m)
	qa.assertEqual res, m
end function
