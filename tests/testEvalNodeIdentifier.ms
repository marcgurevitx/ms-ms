import "qa"

//
if not globals.hasIndex("ms") then
	import "ms"
	globals.ms = ms
end if
//


_NL = ms._NL


testEvalNodeIdentifier = function
	ident = ms.parse("foo").program.statements[0].callable
	qa.assertEqual ident isa ms.Identifier, true
	
	namespaces = {}
	namespaces.locals = {"foo": "bar"}
	ctx = ms.Context.assimilateMap({"namespaces": namespaces})
	res = ms.eval(ident, ctx)
	qa.assertEqual res, "bar"
	
	//
	f = function
		return "FUNC"
	end function
	//
	namespaces = {}
	namespaces.locals = {"foo": @f}
	ctx = ms.Context.assimilateMap({"namespaces": namespaces})
	res = ms.eval(ident, ctx)
	qa.assertEqual @res, "FUNC"
end function


testEvalNodeUnknownIdentifier = function
	ident = ms.parse("foo").program.statements[0].callable
	qa.assertEqual ident isa ms.Identifier, true
	
	//
	params = {}
	params.catchErrors = ms.UnknownIdentifierError
	ctx = ms.Context.assimilateMap({"params": params})
	//
	
	res = ms.eval(ident, ctx)
	qa.assertEqual res, null
	qa.assertEqual ctx.out.type, "error"
	qa.assertEqual ctx.out.error isa ms.UnknownIdentifierError, true
	qa.assertEqual ctx.out.error.name, "foo"
	
	//
	params = {}
	params.catchErrors = ms.RuntimeError
	ctx = ms.Context.assimilateMap({"params": params})
	//
	
	res = ms.eval(ident, ctx)
	qa.assertEqual res, null
	qa.assertEqual ctx.out.type, "error"
	qa.assertEqual ctx.out.error isa ms.UnknownIdentifierError, true
	qa.assertEqual ctx.out.error.name, "foo"
	
	//
	params = {}
	params.catchErrors = ms.Error
	ctx = ms.Context.assimilateMap({"params": params})
	//
	
	res = ms.eval(ident, ctx)
	qa.assertEqual res, null
	qa.assertEqual ctx.out.type, "error"
	qa.assertEqual ctx.out.error isa ms.UnknownIdentifierError, true
	qa.assertEqual ctx.out.error.name, "foo"
	
	//
	params = {}
	params.catchErrors = true
	ctx = ms.Context.assimilateMap({"params": params})
	//
	
	res = ms.eval(ident, ctx)
	qa.assertEqual res, null
	qa.assertEqual ctx.out.type, "error"
	qa.assertEqual ctx.out.error isa ms.UnknownIdentifierError, true
	qa.assertEqual ctx.out.error.name, "foo"
	
	//
	params = {}
	params.catchErrors = [ms.UnknownIdentifierError]
	ctx = ms.Context.assimilateMap({"params": params})
	//
	
	res = ms.eval(ident, ctx)
	qa.assertEqual res, null
	qa.assertEqual ctx.out.type, "error"
	qa.assertEqual ctx.out.error isa ms.UnknownIdentifierError, true
	qa.assertEqual ctx.out.error.name, "foo"
	
	//
	params = {}
	params.catchErrors = [ms.ParseError, ms.UnknownIdentifierError]
	ctx = ms.Context.assimilateMap({"params": params})
	//
	
	res = ms.eval(ident, ctx)
	qa.assertEqual res, null
	qa.assertEqual ctx.out.type, "error"
	qa.assertEqual ctx.out.error isa ms.UnknownIdentifierError, true
	qa.assertEqual ctx.out.error.name, "foo"
end function
