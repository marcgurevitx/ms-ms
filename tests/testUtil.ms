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
	qa.assertEqual ms.str([[[[[42]]]]], 2), "[[[ ...(1 elems)... ]]]"
	qa.assertEqual ms.str({}), "{}"
	qa.assertEqual ms.str({13: 14}), "{13: 14}"
	qa.assertEqual ms.str({13: {13: {13: {13: {13: {}}}}}}, 2), "{13: {13: { ...(1 elems)... }}}"
	
	l = []
	l.push l
	qa.assertEqual ms.str(l), "[...]"
	
	m = {}
	m[13] = m
	qa.assertEqual ms.str(m), "{13: ...}"
	
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
	qa.assertEqual ms.str(a), "{__isa: A}"
	
	A = {}
	A._name = "A"
	A._inited = false
	a = new A
	a._inited = true
	a.foo = 13
	a._bar = 14
	
	qa.assertEqual ms.str(A), "A"
	qa.assertEqual ms.str(a), "A(foo: 13)"
	
	A = {}
	A._name = "A"
	A._inited = false
	A._fields = ["bar", "foo"]
	a = new A
	a._inited = true
	a.foo = 13
	a.bar = 14
	
	qa.assertEqual ms.str(A), "A"
	qa.assertEqual ms.str(a), "A(bar: 14, foo: 13)"
	
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
	a.x = new A
	a.x._inited = true
	a.x.x = new A
	a.x.x._inited = true
	a.x.x.x = new A
	a.x.x.x._inited = true
	a.x.x.x.x = new A
	a.x.x.x.x._inited = true
	
	qa.assertEqual ms.str(a, 2), "A(x: A(x: A( ... )))"
	
	A = {}
	A._name = "A"
	A._inited = false
	a = new A
	a._inited = true
	a.x = a
	
	qa.assertEqual ms.str(a), "A(x: ...)"
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

