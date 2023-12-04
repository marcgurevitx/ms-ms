import "qa"

//
if not globals.hasIndex("ms") then
	import "ms"
	globals.ms = ms
end if
//


_NL = ms._NL


testStr = function
	qa.assertEqual ms.str(null), ""
	qa.assertEqual ms.str(42), "42"
	qa.assertEqual ms.str("hello"), "hello"
	qa.assertEqual ms.str([]), "[]"
	qa.assertEqual ms.str([5, 6, 7]), "[5, 6, 7]"
	qa.assertEqual ms.str([[[[[42]]]]], 2), "[[[ … 1 … ]]]"
	qa.assertEqual ms.str({}), "{}"
	qa.assertEqual ms.str({13: 14}), "{13: 14}"
	qa.assertEqual ms.str({13: {13: {13: {13: {13: {}}}}}}, 2), "{13: {13: { … 1 … }}}"
	
	l = []
	l.push l
	qa.assertEqual ms.str(l), "[…]"
	
	m = {}
	m[13] = m
	qa.assertEqual ms.str(m), "{13: …}"
	
	A = {}
	A._str = function(depth, seen)
		return "this is A"
	end function
	a = new A
	
	qa.assertEqual ms.str(A), "this is A"
	qa.assertEqual ms.str(a), "this is A"
	
	A = {}
	A._name = "A"
	a = new A
	
	qa.assertEqual ms.str(A), "A"
	qa.assertEqual ms.str(a), "A{""__isa"": A}"
	
	A = {}
	A._name = "A"
	A._inited = false
	a = new A
	a._inited = true
	a.foo = 13
	
	qa.assertEqual ms.str(A), "A"
	qa.assertEqual ms.str(a).startsWith("A{"), true
	qa.assertEqual ms.str(a).endsWith("}"), true
	qa.assertEqual ms.str(a).indexOf("""foo"": 13") != null, true
	
	A = {}
	A._name = "A"
	A._inited = false
	A._str = function(depth, seen)
		return "this is A"
	end function
	a = new A
	a._inited = true
	
	qa.assertEqual ms.str(A), "A"
	qa.assertEqual ms.str(a), "this is A"
	
	A = {}
	A._name = "A"
	A._inited = false
	a = new A
	a._inited = true
	a.x = a
	
	qa.assertEqual ms.str(a).startsWith("A{"), true
	qa.assertEqual ms.str(a).endsWith("}"), true
	qa.assertEqual ms.str(a).indexOf("""x"": …") != null, true
	
	qa.assertEqual ms.str(null), ""
	qa.assertEqual ms.str([null]), "[null]"
	qa.assertEqual ms.str({42: null}), "{42: null}"
end function


testStrIsaLoop = function
	m = {}
	m.__isa = m
	qa.assertEqual ms.str(m), "{""__isa"": …}"
end function


testStrQuot = function
	qa.assertEqual ms.str("hi"), "hi"
	qa.assertEqual ms.str("h""i"), "h""i"
	qa.assertEqual ms.str(["hi"]), "[""hi""]"
	qa.assertEqual ms.str({"hi": "bye"}), "{""hi"": ""bye""}"
	qa.assertEqual ms.str(["h""i"]), "[""h""""i""]"
end function


testSplitLines = function
	text = ""
	lines = ms.splitLines(text)
	qa.assertEqual lines.len,       1
	qa.assertEqual lines[0].text,   ""
	qa.assertEqual lines[0].ending, ""
	
	text = "a"
	lines = ms.splitLines(text)
	qa.assertEqual lines.len,       1
	qa.assertEqual lines[0].text,   "a"
	qa.assertEqual lines[0].ending, ""
	
	text = "a" + char(13)
	lines = ms.splitLines(text)
	qa.assertEqual lines.len,       2
	qa.assertEqual lines[0].text,   "a"
	qa.assertEqual lines[0].ending, char(13)
	qa.assertEqual lines[1].text,   ""
	qa.assertEqual lines[1].ending, ""
	
	text = "a" + char(13) + "b"
	lines = ms.splitLines(text)
	qa.assertEqual lines.len,       2
	qa.assertEqual lines[0].text,   "a"
	qa.assertEqual lines[0].ending, char(13)
	qa.assertEqual lines[1].text,   "b"
	qa.assertEqual lines[1].ending, ""
	
	text = "a" + char(13) + "b" + char(13) + char(10)
	lines = ms.splitLines(text)
	qa.assertEqual lines.len,       3
	qa.assertEqual lines[0].text,   "a"
	qa.assertEqual lines[0].ending, char(13)
	qa.assertEqual lines[1].text,   "b"
	qa.assertEqual lines[1].ending, char(13) + char(10)
	qa.assertEqual lines[2].text,   ""
	qa.assertEqual lines[2].ending, ""
	
	text = "a" + char(13) + "b" + char(13) + char(10) + "c"
	lines = ms.splitLines(text)
	qa.assertEqual lines.len,       3
	qa.assertEqual lines[0].text,   "a"
	qa.assertEqual lines[0].ending, char(13)
	qa.assertEqual lines[1].text,   "b"
	qa.assertEqual lines[1].ending, char(13) + char(10)
	qa.assertEqual lines[2].text,   "c"
	qa.assertEqual lines[2].ending, ""
	
	text = "a" + char(13) + "b" + char(13) + char(10) + "c" + char(10)
	lines = ms.splitLines(text)
	qa.assertEqual lines.len,       4
	qa.assertEqual lines[0].text,   "a"
	qa.assertEqual lines[0].ending, char(13)
	qa.assertEqual lines[1].text,   "b"
	qa.assertEqual lines[1].ending, char(13) + char(10)
	qa.assertEqual lines[2].text,   "c"
	qa.assertEqual lines[2].ending, char(10)
	qa.assertEqual lines[3].text,   ""
	qa.assertEqual lines[3].ending, ""
	
	text = "a" + char(13) + "b" + char(13) + char(10) + "c" + char(10) + "d"
	lines = ms.splitLines(text)
	qa.assertEqual lines.len,       4
	qa.assertEqual lines[0].text,   "a"
	qa.assertEqual lines[0].ending, char(13)
	qa.assertEqual lines[1].text,   "b"
	qa.assertEqual lines[1].ending, char(13) + char(10)
	qa.assertEqual lines[2].text,   "c"
	qa.assertEqual lines[2].ending, char(10)
	qa.assertEqual lines[3].text,   "d"
	qa.assertEqual lines[3].ending, ""
	
	text = "a" + char(13) + "b" + char(13) + char(10) + char(10) + "d"
	lines = ms.splitLines(text)
	qa.assertEqual lines.len,       4
	qa.assertEqual lines[0].text,   "a"
	qa.assertEqual lines[0].ending, char(13)
	qa.assertEqual lines[1].text,   "b"
	qa.assertEqual lines[1].ending, char(13) + char(10)
	qa.assertEqual lines[2].text,   ""
	qa.assertEqual lines[2].ending, char(10)
	qa.assertEqual lines[3].text,   "d"
	qa.assertEqual lines[3].ending, ""
	
	text = "a" + char(13) + char(13) + char(10) + char(10) + "d"
	lines = ms.splitLines(text)
	qa.assertEqual lines.len,       4
	qa.assertEqual lines[0].text,   "a"
	qa.assertEqual lines[0].ending, char(13)
	qa.assertEqual lines[1].text,   ""
	qa.assertEqual lines[1].ending, char(13) + char(10)
	qa.assertEqual lines[2].text,   ""
	qa.assertEqual lines[2].ending, char(10)
	qa.assertEqual lines[3].text,   "d"
	qa.assertEqual lines[3].ending, ""
end function


testLineColumn = function
	text = ""
	qa.assertEqual ms.lineColumn(text, 0), {"line": 1, "column": 0}
	qa.assertEqual ms.lineColumn(text, 1), {"line": 1, "column": 0}
	
	text = "a"
	qa.assertEqual ms.lineColumn(text, 0), {"line": 1, "column": 1}
	qa.assertEqual ms.lineColumn(text, 1), {"line": 1, "column": 1}
	
	text = "a" + char(13)
	qa.assertEqual ms.lineColumn(text, 0), {"line": 1, "column": 1}
	qa.assertEqual ms.lineColumn(text, 1), {"line": 1, "column": 2}
	qa.assertEqual ms.lineColumn(text, 2), {"line": 2, "column": 0}
	
	text = "a" + char(13) + "b"
	qa.assertEqual ms.lineColumn(text, 0), {"line": 1, "column": 1}
	qa.assertEqual ms.lineColumn(text, 1), {"line": 1, "column": 2}
	qa.assertEqual ms.lineColumn(text, 2), {"line": 2, "column": 1}
	qa.assertEqual ms.lineColumn(text, 3), {"line": 2, "column": 1}
	
	text = "a" + char(13) + "b" + char(13) + char(10)
	qa.assertEqual ms.lineColumn(text, 0), {"line": 1, "column": 1}
	qa.assertEqual ms.lineColumn(text, 1), {"line": 1, "column": 2}
	qa.assertEqual ms.lineColumn(text, 2), {"line": 2, "column": 1}
	qa.assertEqual ms.lineColumn(text, 3), {"line": 2, "column": 2}
	qa.assertEqual ms.lineColumn(text, 4), {"line": 2, "column": 3}
	qa.assertEqual ms.lineColumn(text, 5), {"line": 3, "column": 0}
	
	text = "a" + char(13) + "b" + char(13) + char(10) + "c"
	qa.assertEqual ms.lineColumn(text, 0), {"line": 1, "column": 1}
	qa.assertEqual ms.lineColumn(text, 1), {"line": 1, "column": 2}
	qa.assertEqual ms.lineColumn(text, 2), {"line": 2, "column": 1}
	qa.assertEqual ms.lineColumn(text, 3), {"line": 2, "column": 2}
	qa.assertEqual ms.lineColumn(text, 4), {"line": 2, "column": 3}
	qa.assertEqual ms.lineColumn(text, 5), {"line": 3, "column": 1}
	qa.assertEqual ms.lineColumn(text, 6), {"line": 3, "column": 1}
end function


testSetMissing = function
	m = {}
	qa.assertEqual ms.setMissing(m, "x", 42), 42
	qa.assertEqual m.x, 42
	qa.assertEqual ms.setMissing(m, "x", 420), 42
end function


testIsInstance = function
	qa.assertEqual ms.isInstance({}, map), true
	qa.assertEqual ms.isInstance({}, list), false
	M = {}
	qa.assertEqual ms.isInstance({}, M), false
	qa.assertEqual ms.isInstance(new M, M), true
	M._inited = false
	qa.assertEqual ms.isInstance(new M, M), false
	m = new M
	m._inited = true
	qa.assertEqual ms.isInstance(m, M), true
end function


testIsTruthy = function
	qa.assertEqual ms.isTruthy(null), false
	qa.assertEqual ms.isTruthy(0), false
	qa.assertEqual ms.isTruthy(1), true
	qa.assertEqual ms.isTruthy(-1), true
	qa.assertEqual ms.isTruthy(0.1), true
	qa.assertEqual ms.isTruthy(1000), true
	qa.assertEqual ms.isTruthy(1/0), true
	qa.assertEqual ms.isTruthy(-1/0), true
	qa.assertEqual ms.isTruthy(0/0), true
	qa.assertEqual ms.isTruthy(""), false
	qa.assertEqual ms.isTruthy(" "), true
	qa.assertEqual ms.isTruthy("foo"), true
	qa.assertEqual ms.isTruthy([]), false
	qa.assertEqual ms.isTruthy([42]), true
	qa.assertEqual ms.isTruthy([false]), true
	qa.assertEqual ms.isTruthy({}), false
	qa.assertEqual ms.isTruthy({42: 42}), true
	qa.assertEqual ms.isTruthy({false: false}), true
	qa.assertEqual ms.isTruthy(@print), true
	
	m = {}
	m.__isa = m
	qa.assertEqual ms.isTruthy(m), true
end function


testIsFuzzyNumber = function
	qa.assertEqual ms.isFuzzyNumber(0), true
	qa.assertEqual ms.isFuzzyNumber(0.5), true
	qa.assertEqual ms.isFuzzyNumber(1), true
	qa.assertEqual ms.isFuzzyNumber(-1), false
	qa.assertEqual ms.isFuzzyNumber(42), false
	qa.assertEqual ms.isFuzzyNumber(1/0), false
	qa.assertEqual ms.isFuzzyNumber(0/0), false
	qa.assertEqual ms.isFuzzyNumber(""), false
	qa.assertEqual ms.isFuzzyNumber("foo"), false
	qa.assertEqual ms.isFuzzyNumber([]), false
	qa.assertEqual ms.isFuzzyNumber([1, 2, 3]), false
	qa.assertEqual ms.isFuzzyNumber({}), false
	qa.assertEqual ms.isFuzzyNumber({13: 14}), false
	qa.assertEqual ms.isFuzzyNumber(@print), false
	
	m = {}
	m.__isa = m
	qa.assertEqual ms.isFuzzyNumber(m), false
end function


testListInsertFillNulls = function
	x = [1, 2, 3]
	ms.listInsertFillNulls x, 5, "foo"
	qa.assertEqual x, [1, 2, 3, null, null, "foo"]
	ms.listInsertFillNulls x, 4, "bar"
	qa.assertEqual x, [1, 2, 3, null, "bar", null, "foo"]
end function


testCallFunction = function
	f = function ; return 42 ; end function
	qa.assertEqual ms.callFunction(@f), 42
	
	f = function(a0) ; return [a0].join(",") ; end function
	qa.assertEqual ms.callFunction(@f, []), ""
	qa.assertEqual ms.callFunction(@f, [1]), "1"
	
	f = function(a0, a1) ; return [a0, a1].join(",") ; end function
	qa.assertEqual ms.callFunction(@f, []), ","
	qa.assertEqual ms.callFunction(@f, [1]), "1,"
	qa.assertEqual ms.callFunction(@f, [1, 2]), "1,2"
	
	f = function(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9) ; return [a0, a1, a2, a3, a4, a5, a6, a7, a8, a9].join(",") ; end function
	qa.assertEqual ms.callFunction(@f, []), ",,,,,,,,,"
	qa.assertEqual ms.callFunction(@f, [1]), "1,,,,,,,,,"
	qa.assertEqual ms.callFunction(@f, [1, 2]), "1,2,,,,,,,,"
	qa.assertEqual ms.callFunction(@f, range(1, 10)), "1,2,3,4,5,6,7,8,9,10"
end function


testCallCthulhuMethod = function
	m = {"foo": 42}
	
	m.Ph_nglui_mglw_nafh_Cthulhu_R_lyeh_wgah_nagl_fhtagn = function
		return self.foo
	end function
	qa.assertEqual ms.callCthulhuMethod(m), 42
	
	m.Ph_nglui_mglw_nafh_Cthulhu_R_lyeh_wgah_nagl_fhtagn = function(a0)
		return [self.foo, a0].join(",")
	end function
	qa.assertEqual ms.callCthulhuMethod(m), "42,"
	qa.assertEqual ms.callCthulhuMethod(m, []), "42,"
	qa.assertEqual ms.callCthulhuMethod(m, [1]), "42,1"
	
	m.Ph_nglui_mglw_nafh_Cthulhu_R_lyeh_wgah_nagl_fhtagn = function(a0, a1)
		return [self.foo, a0, a1].join(",")
	end function
	qa.assertEqual ms.callCthulhuMethod(m), "42,,"
	qa.assertEqual ms.callCthulhuMethod(m, []), "42,,"
	qa.assertEqual ms.callCthulhuMethod(m, [1]), "42,1,"
	qa.assertEqual ms.callCthulhuMethod(m, [1, 2]), "42,1,2"
	
	m.Ph_nglui_mglw_nafh_Cthulhu_R_lyeh_wgah_nagl_fhtagn = function(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9)
		return [self.foo, a0, a1, a2, a3, a4, a5, a6, a7, a8, a9].join(",")
	end function
	qa.assertEqual ms.callCthulhuMethod(m), "42,,,,,,,,,,"
	qa.assertEqual ms.callCthulhuMethod(m, []), "42,,,,,,,,,,"
	qa.assertEqual ms.callCthulhuMethod(m, [1]), "42,1,,,,,,,,,"
	qa.assertEqual ms.callCthulhuMethod(m, [1, 2]), "42,1,2,,,,,,,,"
	qa.assertEqual ms.callCthulhuMethod(m, range(1, 10)), "42,1,2,3,4,5,6,7,8,9,10"
end function


testNArgsFunction = function
	f = function(self, xx) ; return [self, xx] ; end function
	
	uf = ms.nArgsFunction(@f, 0)
	qa.assertEqual uf, [null, []]
	qa.assertEqual uf(), [null, []]
	
	uf = ms.nArgsFunction(@f, 1)
	qa.assertEqual uf, [null, [null]]
	qa.assertEqual uf(), [null, [null]]
	qa.assertEqual uf(10), [null, [10]]
	
	uf = ms.nArgsFunction(@f, 2)
	qa.assertEqual uf, [null, [null, null]]
	qa.assertEqual uf(), [null, [null, null]]
	qa.assertEqual uf(10), [null, [10, null]]
	qa.assertEqual uf(10, 11), [null, [10, 11]]
	
	uf = ms.nArgsFunction(@f, 10)
	qa.assertEqual uf, [null, [null, null, null, null, null, null, null, null, null, null]]
	qa.assertEqual uf(), [null, [null, null, null, null, null, null, null, null, null, null]]
	qa.assertEqual uf(10), [null, [10, null, null, null, null, null, null, null, null, null]]
	qa.assertEqual uf(10, 11), [null, [10, 11, null, null, null, null, null, null, null, null]]
	qa.assertEqual uf(10, 11, 12, 13, 14, 15, 16, 17, 18, 19), [null, [10, 11, 12, 13, 14, 15, 16, 17, 18, 19]]
end function


testNArgsFunctionAsMethod = function
	f = function(self, xx) ; return [self.foo, xx] ; end function
	
	m = {"foo": 42}
	
	m.uf = ms.nArgsFunction(@f, 0)
	qa.assertEqual m.uf, [42, []]
	qa.assertEqual m.uf(), [42, []]
	
	m.uf = ms.nArgsFunction(@f, 1)
	qa.assertEqual m.uf, [42, [null]]
	qa.assertEqual m.uf(), [42, [null]]
	qa.assertEqual m.uf(10), [42, [10]]
	
	m.uf = ms.nArgsFunction(@f, 2)
	qa.assertEqual m.uf, [42, [null, null]]
	qa.assertEqual m.uf(), [42, [null, null]]
	qa.assertEqual m.uf(10), [42, [10, null]]
	qa.assertEqual m.uf(10, 11), [42, [10, 11]]
	
	m.uf = ms.nArgsFunction(@f, 10)
	qa.assertEqual m.uf, [42, [null, null, null, null, null, null, null, null, null, null]]
	qa.assertEqual m.uf(), [42, [null, null, null, null, null, null, null, null, null, null]]
	qa.assertEqual m.uf(10), [42, [10, null, null, null, null, null, null, null, null, null]]
	qa.assertEqual m.uf(10, 11), [42, [10, 11, null, null, null, null, null, null, null, null]]
	qa.assertEqual m.uf(10, 11, 12, 13, 14, 15, 16, 17, 18, 19), [42, [10, 11, 12, 13, 14, 15, 16, 17, 18, 19]]
end function


testNArgsSelfFunction = function
	f = function(s, xx) ; return [s.foo, xx] ; end function
	
	m = {}
	m.foo = 42
	m.uf = ms.nArgsSelfFunction(@f, 0)
	qa.assertEqual m.uf, [42, []]
	qa.assertEqual m.uf(), [42, []]
	
	m.uf = ms.nArgsSelfFunction(@f, 1)
	qa.assertEqual m.uf, [42, [null]]
	qa.assertEqual m.uf(), [42, [null]]
	qa.assertEqual m.uf(10), [42, [10]]
	
	m.uf = ms.nArgsSelfFunction(@f, 2)
	qa.assertEqual m.uf, [42, [null, null]]
	qa.assertEqual m.uf(), [42, [null, null]]
	qa.assertEqual m.uf(10), [42, [10, null]]
	qa.assertEqual m.uf(10, 11), [42, [10, 11]]
	
	m.uf = ms.nArgsSelfFunction(@f, 10)
	qa.assertEqual m.uf, [42, [null, null, null, null, null, null, null, null, null, null]]
	qa.assertEqual m.uf(), [42, [null, null, null, null, null, null, null, null, null, null]]
	qa.assertEqual m.uf(10), [42, [10, null, null, null, null, null, null, null, null, null]]
	qa.assertEqual m.uf(10, 11), [42, [10, 11, null, null, null, null, null, null, null, null]]
	qa.assertEqual m.uf(10, 11, 12, 13, 14, 15, 16, 17, 18, 19), [42, [10, 11, 12, 13, 14, 15, 16, 17, 18, 19]]
end function


testUpdateInPlace = function
	m1 = {}
	m2 = {}
	ms.updateInPlace m1, m2
	qa.assertEqual m1, {}
	qa.assertEqual m2, {}
	
	m1 = {"foo": 42}
	m2 = {}
	ms.updateInPlace m1, m2
	qa.assertEqual m1, {"foo": 42}
	qa.assertEqual m2, {}
	
	m1 = {}
	m2 = {"foo": 42}
	ms.updateInPlace m1, m2
	qa.assertEqual m1, {"foo": 42}
	qa.assertEqual m2, {"foo": 42}
	
	m1 = {"foo": 42}
	m2 = {"foo": 43}
	ms.updateInPlace m1, m2
	qa.assertEqual m1, {"foo": 43}
	qa.assertEqual m2, {"foo": 43}
	
	m1 = {"foo": 42}
	m2 = {"bar": 43}
	ms.updateInPlace m1, m2
	qa.assertEqual m1, {"foo": 42, "bar": 43}
	qa.assertEqual m2, {"bar": 43}
end function


testSafeMapGet = function
	m = {"foo": 42}
	qa.assertEqual ms.safeMapGet(100, m, "foo"), 42
	qa.assertEqual ms.safeMapGet(100, m, "foo", 55), 42
	qa.assertEqual ms.safeMapGet(100, m, "foo", 55, "exceeded"), 42
	qa.assertEqual ms.safeMapGet(100, m, "bar"), null
	qa.assertEqual ms.safeMapGet(100, m, "bar", 55), 55
	qa.assertEqual ms.safeMapGet(100, m, "bar", 55, "exceeded"), 55
	
	m = {"foo": 42}
	mm = {"__isa": m}
	qa.assertEqual ms.safeMapGet(100, mm, "foo"), 42
	qa.assertEqual ms.safeMapGet(100, mm, "foo", 55), 42
	qa.assertEqual ms.safeMapGet(100, mm, "foo", 55, "exceeded"), 42
	qa.assertEqual ms.safeMapGet(100, mm, "bar"), null
	qa.assertEqual ms.safeMapGet(100, mm, "bar", 55), 55
	qa.assertEqual ms.safeMapGet(100, mm, "bar", 55, "exceeded"), 55
	
	m = {"foo": 42}
	mmm = {"__isa": {"__isa": {"__isa": {"__isa": m}}}}
	qa.assertEqual ms.safeMapGet(100, mmm, "foo"), 42
	qa.assertEqual ms.safeMapGet(100, mmm, "foo", 55), 42
	qa.assertEqual ms.safeMapGet(100, mmm, "foo", 55, "exceeded"), 42
	qa.assertEqual ms.safeMapGet(100, mmm, "bar"), null
	qa.assertEqual ms.safeMapGet(100, mmm, "bar", 55), 55
	qa.assertEqual ms.safeMapGet(100, mmm, "bar", 55, "exceeded"), 55
	qa.assertEqual ms.safeMapGet(2, mmm, "foo"), null
	qa.assertEqual ms.safeMapGet(2, mmm, "foo", 55), null
	qa.assertEqual ms.safeMapGet(2, mmm, "foo", 55, "exceeded"), "exceeded"
	
	m = {}
	m.__isa = m
	qa.assertEqual ms.safeMapGet(2, m, "foo"), null
	qa.assertEqual ms.safeMapGet(2, m, "foo", 55), null
	qa.assertEqual ms.safeMapGet(2, m, "foo", 55, "exceeded"), "exceeded"
	qa.assertEqual ms.safeMapGet(100, m, "foo"), null
	qa.assertEqual ms.safeMapGet(100, m, "foo", 55), null
	qa.assertEqual ms.safeMapGet(100, m, "foo", 55, "exceeded"), "exceeded"
end function


testSafeIsa = function
	qa.assertEqual ms.safeIsa(100, null, null, "exceeded"), true
	qa.assertEqual ms.safeIsa(100, null, number, "exceeded"), false
	
	qa.assertEqual ms.safeIsa(100, 42, number, "exceeded"), true
	qa.assertEqual ms.safeIsa(100, 42, string, "exceeded"), false
	
	qa.assertEqual ms.safeIsa(100, "foo", string, "exceeded"), true
	qa.assertEqual ms.safeIsa(100, "foo", list, "exceeded"), false
	
	qa.assertEqual ms.safeIsa(100, [], list, "exceeded"), true
	qa.assertEqual ms.safeIsa(100, [], map, "exceeded"), false
	
	m = {}
	qa.assertEqual ms.safeIsa(100, m, {}, "exceeded"), false
	qa.assertEqual ms.safeIsa(100, m, map, "exceeded"), true
	
	M = {}
	m = {"__isa": M}
	qa.assertEqual ms.safeIsa(100, m, M, "exceeded"), true
	
	M = {}
	m = {"__isa": {"__isa": {"__isa": {"__isa": {"__isa": M}}}}}
	qa.assertEqual ms.safeIsa(100, m, M, "exceeded"), true
	qa.assertEqual ms.safeIsa(2, m, M, "exceeded"), "exceeded"
	qa.assertEqual ms.safeIsa(2, m, M), false
	
	m = {}
	m.__isa = m
	qa.assertEqual ms.safeIsa(100, m, {}, "exceeded"), "exceeded"
	qa.assertEqual ms.safeIsa(100, m, {}), false
	qa.assertEqual ms.safeIsa(100, m, map, "exceeded"), true
	qa.assertEqual ms.safeIsa(100, m, string, "exceeded"), false
	
	qa.assertEqual ms.safeIsa(100, null, {}, "exceeded"), false
	qa.assertEqual ms.safeIsa(100, 42, {}, "exceeded"), false
	qa.assertEqual ms.safeIsa(100, "foo", {}, "exceeded"), false
	qa.assertEqual ms.safeIsa(100, [], {}, "exceeded"), false
	qa.assertEqual ms.safeIsa(100, @print, {}, "exceeded"), false
end function


testSafeMapHas = function
	m = {}
	m.foo = 42
	qa.assertEqual ms.safeMapHas(100, m, "foo"), true
	qa.assertEqual ms.safeMapHas(100, m, "bar"), false
	
	m = {}
	m.foo = 42
	mm = {}
	mm.__isa = m
	mm.bar = 43
	qa.assertEqual ms.safeMapHas(100, mm, "foo"), true
	qa.assertEqual ms.safeMapHas(100, mm, "bar"), true
	
	m = {}
	m.foo = 42
	mm = {"__isa": {"__isa": {"__isa": {"__isa": {"__isa": m}}}}}
	qa.assertEqual ms.safeMapHas(100, mm, "foo"), true
	qa.assertEqual ms.safeMapHas(2, mm, "foo"), false
	
	m = {}
	m.__isa = m
	qa.assertEqual ms.safeMapHas(100, m, "foo"), false
end function


testTagToPhrase = function
	qa.assertEqual ms.tagToPhrase("foo"), "Foo"
	qa.assertEqual ms.tagToPhrase("fooBarBaz"), "Foo bar baz"
end function
