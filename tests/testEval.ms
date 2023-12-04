import "qa"

//
if not globals.hasIndex("ms") then
	import "ms"
	globals.ms = ms
end if
//


_NL = ms._NL


testEvalBasic = function
	res = ms.eval(" xx = [] ; xx.push 42 ; xx.push ""foo"" ; xx.push {} ; xx ")
	qa.assertEqual res, [42, "foo", {}]
end function


testEvalFuncDef = function
	res = ms.eval(" f = function ; end function ; x = f ; x ")
	qa.assertEqual res, null
	
	res = ms.eval(" f = function ; end function ; f ")
	qa.assertEqual res, null
	
	res = ms.eval(" f = function ; return 42 ; end function ; x = f ; x ")
	qa.assertEqual res, 42
	
	res = ms.eval(" f = function ; return 42 ; end function ; f ")
	qa.assertEqual res, 42
	
	res = ms.eval(" f = function(x) ; return 42 + x ; end function ; x = f(43) ; x ")
	qa.assertEqual res, 85
	
	res = ms.eval(" f = function(x) ; return 42 + x ; end function ; f(43) ")
	qa.assertEqual res, 85
	
	res = ms.eval(" f = function(self) ; return 42 + self ; end function ; x = f(43) ; x ")
	qa.assertEqual res, 85
	
	res = ms.eval(" f = function(x=""hi"") ; return 42 + x ; end function ; x = f(43) ; x ")
	qa.assertEqual res, 85
	
	res = ms.eval(" f = function(x=""hi"") ; return 42 + x ; end function ; x = f() ; x ")
	qa.assertEqual res, "42hi"
	
	res = ms.eval(" f = function(x=""hi"") ; return 42 + x ; end function ; x = f ; x ")
	qa.assertEqual res, "42hi"
	
	res = ms.eval(" f = function(a, b=13) ; return a + b ; end function ; x = f(5) ; x ")
	qa.assertEqual res, 18
	
	res = ms.eval(" f = function(a, b=13) ; return a + b ; end function ; x = f(5, 6) ; x ")
	qa.assertEqual res, 11
	
	res = ms.eval(" f = function(a, b=13) ; return [a, b] ; end function ; x = f(null, 6) ; x ")
	qa.assertEqual res, [null, 6]
	
	res = ms.eval(" f = function(a, b=13) ; return [a, b] ; end function ; x = f(null, null) ; x ")
	qa.assertEqual res, [null, null]
	
	//
	params = {}
	params.catchErrors = ms.UnknownIdentifierError
	ctx = {"params": params}
	//
	res = ms.eval(" f = function ; return self ; end function ; x = f ; x ", ctx)
	qa.assertEqual res, null
	qa.assertEqual ctx.out.type, "error"
	qa.assertEqual ctx.out.error isa ms.UnknownIdentifierError, true
	qa.assertEqual ctx.out.error.name, "self"
end function


testEvalFuncDefMember = function
	res = ms.eval(" m = {} ; m.f = function ; end function ; x = m.f ; x ")
	qa.assertEqual res, null
	
	res = ms.eval(" m = {} ; m.f = function ; end function ; x = m.f() ; x ")
	qa.assertEqual res, null
	
	res = ms.eval(" m = {} ; m.f = function ; return 42 ; end function ; x = m.f ; x ")
	qa.assertEqual res, 42
	
	res = ms.eval(" m = {} ; m.f = function ; return 42 ; end function ; x = m.f() ; x ")
	qa.assertEqual res, 42
	
	res = ms.eval(" m = {} ; m.f = function ; return 42 ; end function ; m.f")
	qa.assertEqual res, 42
	
	res = ms.eval(" m = {""foo"": 42} ; m.f = function ; return self.foo ; end function ; m.f")
	qa.assertEqual res, 42
	
	res = ms.eval(" m = {""foo"": 42} ; m.f = function(x) ; return self.foo + x ; end function ; m.f 43")
	qa.assertEqual res, 85
	
	res = ms.eval(" m = {""foo"": 42} ; m.f = function(x, y) ; return self.foo + x + y ; end function ; m.f 43, 44")
	qa.assertEqual res, 129
	
	res = ms.eval(" m = {""foo"": 42} ; m.f = function(x, y=100) ; return self.foo + x + y ; end function ; m.f 43, 44")
	qa.assertEqual res, 129
	
	res = ms.eval(" m = {""foo"": 42} ; m.f = function(x, y=100) ; return self.foo + x + y ; end function ; m.f 43")
	qa.assertEqual res, 185
	
	res = ms.eval(" m = {""foo"": 42} ; m.f = function(self, x, y=100) ; return self.foo + x + y ; end function ; m.f 43")
	qa.assertEqual res, 185
end function


testEvalFuncDefSuper = function
	//
	params = {}
	params.catchErrors = ms.UnknownIdentifierError
	ctx = {"params": params}
	//
	res = ms.eval(" f = function ; return super ; end function ; f ", ctx)
	qa.assertEqual res, null
	qa.assertEqual ctx.out.type, "error"
	qa.assertEqual ctx.out.error isa ms.UnknownIdentifierError, true
	qa.assertEqual ctx.out.error.name, "super"
	
	//
	ctx = {}
	//
	res = ms.eval(" m = {} ; m.f = function ; return super ; end function ; m.f ", ctx)
	qa.assertEqual res, null
	qa.assertEqual ctx.out.type, "result"
	
	res = ms.eval(" m = {""foo"": 42} ; mm = new m ; mm.f = function ; return super ; end function ; mm.f ")
	qa.assertEqual res, {"foo": 42}
	
	res = ms.eval("" + _NL +
		"m = {}"                                                        + _NL +
		"m.foo = 42"                                                    + _NL +
		"m.f = function ; return ""m_"" + self.foo ; end function"      + _NL +
		"mm = new m"                                                    + _NL +
		"mm.foo = 43"                                                   + _NL +
		"mm.f = function ; return ""mm_"" + self.foo ; end function"    + _NL +
		"mm.g = function ; return [self.f, super.f] ; end function"     + _NL +
		"mm.g"                                                          + _NL +
		"")
	qa.assertEqual res, ["mm_43", "m_43"]
	
	res = ms.eval(""                                                    + _NL +
		"m = {}"                                                        + _NL +
		"m.foo = 42"                                                    + _NL +
		"m.f = function ; return ""m_"" + self.foo ; end function"      + _NL +
		"mm = new m"                                                    + _NL +
		"mm.foo = 43"                                                   + _NL +
		"mm.f = function ; return ""mm_"" + self.foo ; end function"    + _NL +
		"mm.g = function ; return [self.f(), super.f()] ; end function" + _NL +
		"mm.g"                                                          + _NL +
		"")
	qa.assertEqual res, ["mm_43", "m_43"]
	
	res = ms.eval(""                                                    + _NL +
		"m = {}"                                                        + _NL +
		"m.foo = 42"                                                    + _NL +
		"mm = new m"                                                    + _NL +
		"mm.foo = 43"                                                   + _NL +
		"mm.g = function ; return [self.foo, super.foo] ; end function" + _NL +
		"mm.g"                                                          + _NL +
		"")
	qa.assertEqual res, [43, 42]
end function


testEvalFuncDefDeepSuper = function
	res = ms.eval(""                                                    + _NL +
		"A = {}"                                                        + _NL +
		"A.foo = ""A"""                                                 + _NL +
		"B = new A"                                                     + _NL +
		"B.foo = ""B"""                                                 + _NL +
		"C = new B"                                                     + _NL +
		"C.foo = ""C"""                                                 + _NL +
		"D = new C"                                                     + _NL +
		"D.foo = ""D"""                                                 + _NL +
		"E = new D"                                                     + _NL +
		"E.foo = ""E"""                                                 + _NL +
		"F = new E"                                                     + _NL +
		"F.foo = ""F"""                                                 + _NL +
		"D.ff = function; return [self.foo, super.foo] ; end function"  + _NL +
		"F.ff"                                                          + _NL +
		"")
	qa.assertEqual res, ["F", "C"]
	
	res = ms.eval(""                                                    + _NL +
		"A = {}"                                                        + _NL +
		"A.foo = ""A"""                                                 + _NL +
		"B = new A"                                                     + _NL +
		"B.foo = ""B"""                                                 + _NL +
		"C = new B"                                                     + _NL +
		"C.foo = ""C"""                                                 + _NL +
		"D = new C"                                                     + _NL +
		"D.foo = ""D"""                                                 + _NL +
		"E = new D"                                                     + _NL +
		"E.foo = ""E"""                                                 + _NL +
		"F = new E"                                                     + _NL +
		"F.foo = ""F"""                                                 + _NL +
		"D.ff = function; return [self.foo, super.foo] ; end function"  + _NL +
		"F.ff()"                                                        + _NL +
		"")
	qa.assertEqual res, ["F", "C"]
end function


testEvalNamespaces = function
	//
	ns = {}
	ns.locals = {}
	ns.locals.x = 42
	ctx = {"namespaces": ns}
	//
	res = ms.eval(" locals.x ", ctx)
	qa.assertEqual res, 42
	
	//
	ns = {}
	ns.outer = {}
	ns.outer.x = 42
	ctx = {"namespaces": ns}
	//
	res = ms.eval(" outer.x ", ctx)
	qa.assertEqual res, 42
	
	//
	ns = {}
	ns.globals = {}
	ns.globals.x = 42
	ctx = {"namespaces": ns}
	//
	res = ms.eval(" globals.x ", ctx)
	qa.assertEqual res, 42
	
	//
	ns = {}
	ns.intrinsics = {}
	ns.intrinsics.x = 42
	params = {}
	params.catchErrors = ms.UnknownIdentifierError
	ctx = {"namespaces": ns, "params": params}
	//
	res = ms.eval(" intrinsics.x ", ctx)
	qa.assertEqual res, null
	qa.assertEqual ctx.out.type, "error"
	qa.assertEqual ctx.out.error isa ms.UnknownIdentifierError, true
	qa.assertEqual ctx.out.error.name, "intrinsics"
	
	//
	ns = {}
	ns.intrinsics = {}
	ns.intrinsics.x = 42
	features = {}
	features.introspectIntrinsics = true
	ctx = {"namespaces": ns, "features": features}
	//
	res = ms.eval(" intrinsics.x ", ctx)
	qa.assertEqual res, 42
end function


testEvalFuncDefDefaults = function
	res = ms.eval(" f = function(a=null) ; return [a] ; end function ; f ")
	qa.assertEqual res, [null]
	
	res = ms.eval(" f = function(a=42) ; return [a] ; end function ; f ")
	qa.assertEqual res, [42]
	
	res = ms.eval(" f = function(a=""foo"") ; return [a] ; end function ; f ")
	qa.assertEqual res, ["foo"]
	
	res = ms.eval(" f = function(a=""foo,bar"") ; return [a] ; end function ; f ")
	qa.assertEqual res, ["foo,bar"]
	
	res = ms.eval(" f = function(a=""foo, """"b""""ar"") ; return [a] ; end function ; f ")
	qa.assertEqual res, ["foo, ""b""ar"]
	
	res = ms.eval(" f = function(a=5, b=6) ; return [a, b] ; end function ; f ")
	qa.assertEqual res, [5, 6]
end function


testEvalFuncDefEvalAndCall = function
	//
	params = {}
	params.rawParsedFunctions = true
	ctx = {"params": params}
	//
	res = ms.eval(" f = function ; end function ; @f ", ctx)
	qa.assertEqual @res isa ms.ParsedFunction, true
	
	res = ms.eval(" f = function ; end function ; @f ")
	qa.assertEqual @res isa funcRef, true
	qa.assertEqual res, null
	
	res = ms.eval(" f = function ; return 42 ; end function ; @f ")
	qa.assertEqual @res isa funcRef, true
	qa.assertEqual res, 42
	
	res = ms.eval(" m = {""foo"": 42} ; m.f = function(x) ; return self.foo + x ; end function ; m ")
	qa.assertEqual @res.f isa funcRef, true
	qa.assertEqual res.f(43), 85
	
	res = ms.eval(  "f = function"  + _NL +
	                " g = function" + _NL +
	                "  return 42"   + _NL +
	                " end function" + _NL +
	                " return @g"    + _NL +
	                "end function"  + _NL +
	                "@f"            + _NL +
	                "")
	qa.assertEqual @res isa funcRef, true
	g = res
	qa.assertEqual @g isa funcRef, true
	qa.assertEqual g, 42
end function


testEvalFuncNamespaces = function
	ctx = {}
	ctx.namespaces = {}
	ctx.namespaces.locals = {}
	ctx.namespaces.locals.x = 42
	
	res = ms.eval("f = function ; return x ; end function ; f", ctx)
	qa.assertEqual res, 42
	
	ctx = {}
	ctx.namespaces = {}
	ctx.namespaces.locals = {}
	ctx.namespaces.locals.x = 42
	
	res = ms.eval("f = function() ; return x ; end function ; f", ctx)
	qa.assertEqual res, 42
end function


testEvalMapIndexes = function
	res = ms.eval("m = {} ; m.A = 42 ; m.B = true ; m.indexes")
	res.sort
	qa.assertEqual res, ["A", "B"]
	
	
	m = {}
	ctx = {}
	ctx.namespaces = {}
	ctx.namespaces.locals = {}
	ctx.namespaces.locals.m = m
	
	res = ms.eval("m.A = 42 ; m.B = true ; x = m[""indexes""] ; x m", ctx)
	res.sort
	qa.assertEqual res, ["A", "B"]
end function


testEvalDefaultDefault = function
	ctx = {}
	res = ms.eval("f = function(x) ; return x ; end function ; f", ctx)
	qa.assertEqual res, null
	qa.assertEqual ctx.out.type, "result"
end function


testEvalExceededIsaDepth = function
	ctx = {}
	ctx.params = {}
	ctx.params.catchErrors = ms.IsaDepthExceededError
	
	res = ms.eval("m = {} ; m.__isa = m ; m.foo", ctx)
	
	qa.assertEqual res, null
	qa.assertEqual ctx.out.type, "error"
	qa.assertEqual ctx.out.error isa ms.IsaDepthExceededError, true
	
	
	ctx = {}
	ctx.params = {}
	ctx.params.catchErrors = ms.IsaDepthExceededError
	
	res = ms.eval("m = {} ; m.__isa = m ; m[""foo""]", ctx)
	
	qa.assertEqual res, null
	qa.assertEqual ctx.out.type, "error"
	qa.assertEqual ctx.out.error isa ms.IsaDepthExceededError, true
	
	
	ctx = {}
	ctx.params = {}
	ctx.params.catchErrors = ms.IsaDepthExceededError
	
	res = ms.eval("m = {} ; m.__isa = m ; m isa {}", ctx)
	
	qa.assertEqual res, null
	qa.assertEqual ctx.out.type, "error"
	qa.assertEqual ctx.out.error isa ms.IsaDepthExceededError, true
end function


testEvalNoExceededIsaDepth = function
	m = {}
	m.__isa = m
	m.foo = 42
	
	ctx = {}
	ctx.params = {}
	ctx.params.catchErrors = ms.IsaDepthExceededError
	ctx.namespaces = {}
	ctx.namespaces.locals = {}
	ctx.namespaces.locals.m = m
	
	res = ms.eval(  ""                                                                          + _NL +
	                "m.f = function ; return [self, super, self.foo, super.foo] ; end function" + _NL +
	                "mm = {""__isa"": m}"                                                       + _NL +
	                "mm.foo = 43"                                                               + _NL +
	                "mm.f"                                                                      + _NL +
	                "", ctx)
	
	qa.assertEqual res[0], {"__isa": m, "foo": 43}
	qa.assertEqual res[1], m
	qa.assertEqual res[2], 43
	qa.assertEqual res[3], 42
	
	
	m = {}
	m.__isa = m
	m.foo = 42
	
	ctx = {}
	ctx.params = {}
	ctx.params.catchErrors = ms.IsaDepthExceededError
	ctx.namespaces = {}
	ctx.namespaces.locals = {}
	ctx.namespaces.locals.m = m
	
	res = ms.eval("kk = {} ; for kv in m ; kk.push @kv.value ; end for ; kk", ctx)
	qa.assertEqual res, {m: true, 42: true}
end function


testEvalMethodNotFoundError = function
	m = {}
	m.__isa = m
	m.foo = 42
	m.f = function ; return m.foo ; end function
	
	ctx = {}
	ctx.params = {}
	ctx.params.catchErrors = ms.MethodNotFoundError
	ctx.namespaces = {}
	ctx.namespaces.locals = {}
	ctx.namespaces.locals.m = m
	
	res = ms.eval("m.f", ctx)
	qa.assertEqual res, null
	qa.assertEqual ctx.out.type, "error"
	qa.assertEqual ctx.out.error isa ms.MethodNotFoundError, true
end function


testEvalStrangeIsaKeyError = function
	ctx = {}
	ctx.params = {}
	ctx.params.catchErrors = ms.KeyNotFoundError
	
	res = ms.eval("m = {""__isa"": 42} ; m.indexes", ctx)
	qa.assertEqual res, null
	qa.assertEqual ctx.out.type, "error"
	qa.assertEqual ctx.out.error isa ms.KeyNotFoundError, true
	
	
	ctx = {}
	ctx.params = {}
	ctx.params.catchErrors = ms.KeyNotFoundError
	
	res = ms.eval("m = {""__isa"": 42} ; m.indexes()", ctx)
	qa.assertEqual res, null
	qa.assertEqual ctx.out.type, "error"
	qa.assertEqual ctx.out.error isa ms.KeyNotFoundError, true
end function


testEvalIndexNonmaps = function
	res = ms.eval("x = [][""push""] ; y = """"[""indexOf""] ; [@x, @y]")
	qa.assertEqual @res[0], @list.push
	qa.assertEqual @res[1], @string.indexOf
end function


testEvalIndexErrors = function
	ctx = {}
	ctx.params = {}
	ctx.params.catchErrors = [ms.IndexError]
	
	res = ms.eval("[][100]", ctx)
	
	qa.assertEqual res, null
	qa.assertEqual ctx.out.type, "error"
	qa.assertEqual ctx.out.error isa ms.IndexError, true
	qa.assertEqual ctx.out.error.index, 100
	
	
	ctx = {}
	ctx.params = {}
	ctx.params.catchErrors = [ms.IndexError]
	
	res = ms.eval("""""[-100]", ctx)
	
	qa.assertEqual res, null
	qa.assertEqual ctx.out.type, "error"
	qa.assertEqual ctx.out.error isa ms.IndexError, true
	qa.assertEqual ctx.out.error.index, -100
	
	
	ctx = {}
	ctx.params = {}
	ctx.params.catchErrors = [ms.UnableToIndexNullError]
	
	res = ms.eval("(null)[200]", ctx)
	
	qa.assertEqual res, null
	qa.assertEqual ctx.out.type, "error"
	qa.assertEqual ctx.out.error isa ms.UnableToIndexNullError, true
	
	
	ctx = {}
	ctx.params = {}
	ctx.params.catchErrors = [ms.UnableToIndexError]
	
	res = ms.eval("42[-200]", ctx)
	
	qa.assertEqual res, null
	qa.assertEqual ctx.out.type, "error"
	qa.assertEqual ctx.out.error isa ms.UnableToIndexError, true
end function


testEvalNullLookupError = function
	ctx = {}
	ctx.params = {}
	ctx.params.catchErrors = ms.NullLookupError
	
	res = ms.eval("a = null ; a.foo", ctx)
	
	qa.assertEqual res, null
	qa.assertEqual ctx.out.type, "error"
	qa.assertEqual ctx.out.error isa ms.NullLookupError, true
	qa.assertEqual ctx.out.error.index, "foo"
	
	
	ctx = {}
	ctx.params = {}
	ctx.params.catchErrors = ms.NullLookupError
	
	res = ms.eval("a = null ; a[""foo""]", ctx)
	
	qa.assertEqual res, null
	qa.assertEqual ctx.out.type, "error"
	qa.assertEqual ctx.out.error isa ms.NullLookupError, true
	qa.assertEqual ctx.out.error.index, "foo"
end function


testEvalArithAssignFunc = function
	res = ms.eval("f = function ; return 42 ; end function ;   f += 1 ;   @f")
	qa.assertEqual res, 43
end function
