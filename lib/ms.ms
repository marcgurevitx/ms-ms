// MiniScript parser and evaluator.


// ensureImport: Imports a module and caches it in `globals`.
// Use an existing function if present.
// (Some platforms don't have this or the user might have implement their own `ensureImport`.)
if globals.hasIndex("ensureImport") then
	ensureImport = @globals.ensureImport
else
	// from /sys/lib/importUtil.ms
	ensureImport = function(moduleName)
		if globals.hasIndex(moduleName) then return
		globals[moduleName] = "PENDING"	// (module is being imported now)
		import moduleName
		globals[moduleName] = locals[moduleName]
	end function
end if


ensureImport "listUtil"
ensureImport "mapUtil"
ensureImport "stringUtil"
ensureImport "peg"  // grammar parser




//
ensureImport "../peg-ms/examples/playSteps"
globals.playSteps = globals["../peg-ms/examples/playSteps"]
//





// iVersion: Saved `version` intrinsic.
// (We're going to shadow it with our own `version`.)
iVersion = @version


// version: Current version of `ms.ms`.
version = "0.0.0"


// _NL: A platform specific line break.
// (We will use it to join strings before printing, mainly for debugging.)
if iVersion.hostName == "Mini Micro" then _NL = char(13) else _NL = char(10)


// abort: Prints error message and exits.
// Uses an existing function if present.
if globals.hasIndex("abort") then
	abort = @globals.abort
else
	maxStack = 15
	extraStack = 3
	abort = function(msg)
		print msg
		s = stackTrace[:-1]
		if s.len > maxStack + extraStack then s = s[:maxStack/2] + ["... (+" + (s.len - maxStack) + " lines) ..."] + s[-maxStack/2:]
		s.apply @print
		exit
	end function
end if


// refIndexOf: Finds index of an element in a list using `refEquals`.
// Uses an existing list method if present.
// (Our `str()` function will use this to check for data loops.)
if list.hasIndex("_refIndexOf") then
	refIndexOf = function(l, x)
		return l._refIndexOf(@x)
	end function
else
	// from /sys/startup.ms
	refIndexOf = function(l, x)
		i = 0; listLen = l.len
		while i < listLen
			if refEquals(l[i], @x) then return i
			i += 1
		end while
		return null
	end function
end if


// hasIndex: Returns whether a key exists in a map (walking the __isa chain).
// Very similar to `map.get`, but returns either `true` or `false`.
_has = function(m, key)
	noValue = {}
	value = m.get(@key, noValue)
	return not refEquals(@value, noValue)
end function


// iStr: Saved `str` intrinsic.
iStr = @str


// str: Converts `x` to a string.
// The difference between this and the intrinsic `str` is that we call `._str` callback in maps.
// (Probably overengineered a bit.)
str = function(x, depth=-1, seen=null)
	if seen == null then seen = []
	if refIndexOf(seen, @x) != null then return "..."
	if @x isa list then
		seen.push @x
		if x.len == 0 then return "[]"
		if depth == 0 then return "[ ...(" + x.len + " elems)... ]"
		listParts = []
		for elem in x
			listParts.push str(@elem, depth - 1, seen)
		end for
		return "[" + listParts.join(", ") + "]"
	else if @x isa map then
		seen.push @x
		if not _has(x, "_inited") then
			// a regular map
			if _has(x, "_str") then return iStr(x._str(depth, seen))
			if x.hasIndex("_name") then return iStr(x._name)
			if x.len == 0 then return "{}"
			if depth == 0 then return "{ ...(" + x.len + " elems)... }"
			return "{" + _strPairs(x, x.indexes, depth, seen) + "}"
		else if not x._inited then
			// a class
			if _has(x, "_name") then return iStr(x._name)
			if x.len == 0 then return "_name?{}"
			if depth == 0 then return "_name?{ ...(" + x.len + " elems)... }"
			return "_name?{" + _strPairs(x, x.indexes, depth, seen) + "}"
		else
			// an instance
			if _has(x, "_str") then return iStr(x._str(depth, seen))
			if _has(x, "_name") then
				name = iStr(x._name)
			else
				name = "_name?"
			end if
			if depth == 0 then return name + "( ... )"
			if _has(x, "_fields") then
				fields = x._fields
			else
				fields = []
				for key in x.indexes
					if not @key isa string or key[0] != "_" then fields.push @key
				end for
			end if
			return name + "(" + _strPairs(x, fields, depth, seen) + ")"
		end if
	end if
	return iStr(@x)
end function


// _strMap: Returns a string of key-value pairs of a map: "k1: v1, k2: v2 ... ".
// (Factored out from `str` to make it look shorter.)
_strPairs = function(m, indexes, depth, seen)
	parts = []
	for key in indexes
		parts.push str(@key, depth - 1, seen) + ": " + str(m[key], depth - 1, seen)
	end for
	return parts.join(", ")
end function


// splitLines: Finds all linebreaks in a text and returns an array of {"line":..., "ending":...} entries.
// It is called from `lineColumn` to calculate the line and column of a position in the source.
// We cannot just use `string.splitLines`, because we need to know the actual line break or at least its length.
// The last entry will always have `ending == ""` even when the `text` itself ends with a line break:
//  splitLines "a"+_NL  //  [{"line": "a", "ending": _NL},  {"line": "", "ending": ""}]
splitLines = function(text)
	lines = []
	prev = 0
	i = 0
	while i < text.len
		if text[i:i + 2] == char(13) + char(10) then
			line = {}
			line.text = text[prev:i]
			line.ending = char(13) + char(10)
			lines.push line
			i += 1
			prev = i + 1
		else if text[i] == char(13) or text[i] == char(10) then
			line = {}
			line.text = text[prev:i]
			line.ending = text[i]
			lines.push line
			prev = i + 1
		end if
		i += 1
	end while
	line = {}
	line.text = text[prev:]
	line.ending = ""
	lines.push line
	return lines
end function


// lineColumn: Calculates the line and column of text[i].
// Used for syntax nodes introspection and error reporting.
lineColumn = function(text, index)
	lines = splitLines(text[:index + 1])
	last = lines[-1]
	lc = {}
	lc.line = lines.len
	lc.column = last.text.len
	if last.text.len == 0 then  // index is on a line break or at an empty file start
		lastTwo = lines[-2:]
		column = 0
		for line in lastTwo
			column += line.text.len + line.ending.len
		end for
		lc.column = column
		if index < text.len then
			lc.line -= 1
		else
			lc.column = 0
		end if
	end if
	return lc
end function





// Error: ?
Error = peg.Error


// Continuation: ?
Continuation = new Error
Continuation._name = "ms.Continuation"


// ContLine: ?
ContLine = new Continuation
ContLine._name = "ms.ContLine"


// ContString: ?
ContString = new Continuation
ContString._name = "ms.ContString"


// ContIf: ?
ContIf = new Continuation
ContIf._name = "ms.ContIf"


// ContFor: ?
ContFor = new Continuation
ContFor._name = "ms.ContFor"


// ContWhile: ?
ContWhile = new Continuation
ContWhile._name = "ms.ContWhile"


// ContFunction: ?
ContFunction = new Continuation
ContFunction._name = "ms.ContFunction"









// v16: Default features for parsing and evaluating MiniScript 1.6
v16 = {}


// multilineContinuations: ?
v16.multilineContinuations = false


// multilineStrings: ?
v16.multilineStrings = false


// beheadedFunctions: ?
v16.beheadedFunctions = true


// confusedNamespaces: ?
v16.confusedFunctions = true


// parseShebang: ?
v16.parseShebang = false


// ?
v16File = new v16

v16File.multilineContinuations = true

v16File.multilineStrings = true

v16File.parseShebang = true









// SyntaxNode: ?
SyntaxNode = {}
SyntaxNode._name = "ms.SyntaxNode"
SyntaxNode._inited = false
SyntaxNode._subject = null
SyntaxNode.start = null
SyntaxNode.length = null
SyntaxNode.posFirst = null
SyntaxNode.posLast = null
SyntaxNode._propertyFullNames = []
SyntaxNode.properties = null


// init: ?
SyntaxNode.init = function(start, length, subject)
	self._inited = true
	self._subject = subject
	self.properties = {}
	self.adjust start, length
end function


// adjust: ?
SyntaxNode.adjust = function(start, length)
	self.start = start
	fragment = self._subject[start : start + length].trimRight
	self.length = fragment.len
	lc = lineColumn(self._subject, start)
	self.posFirst = {}
	self.posFirst.line = lc.line
	self.posFirst.column = lc.column
	stop = start + fragment.len - 1
	if stop < start then stop = start
	lc = lineColumn(self._subject, stop)
	self.posLast = {}
	self.posLast.line = lc.line
	self.posLast.column = lc.column
end function


// propertyNames: ?
SyntaxNode.propertyNames = function
	names = []
	for fullName in self._propertyFullNames
		names.push fullName - " =" - ":" - "." - "."
	end for
	return names
end function


// _str: ?
SyntaxNode._str = function(depth, seen)
	n = self._name
	l1 = self.posFirst.line
	c1 = self.posFirst.column
	l2 = self.posLast.line
	c2 = self.posLast.column
	header = []
	header.push "[{n} {l1}:{c1} {l2}:{c2}]".fill(locals)
	lines = []
	for fullName in self._propertyFullNames
		name = fullName - " =" - ":" - "." - "."
		v = self.properties.get(name, "")
		if fullName.endsWith(" =") then
			s = str(v, depth - 1, seen)
			
			//
			s = s.replace(char(13) + char(10), " ").replace(char(10), " ").replace(char(13), " ")
			//
			
			header.push fullName + " " + s
		else if fullName.endsWith(":") then
			lines.push " " + fullName
			if v then
				for part in str(v, depth - 1, seen).split(_NL)
					lines.push "  " + part
				end for
			end if
		else if fullName.endsWith("..") then
			if not v then
				lines.push " " + name + ".--.--"
			else
				for i in v.indexes
					w = v[i]
					if not w then
						lines.push " " + name + "." + i + ".--"
					else
						for j in w.indexes
							elem = w[j]
							lines.push " " + name + "." + i + "." + j
							for part in str(elem, depth - 1, seen).split(_NL)
								lines.push "  " + part
							end for
						end for
					end if
				end for
			end if
		else if fullName.endsWith(".") then
			if not v then
				lines.push " " + fullName + "--"
			else
				for i in v.indexes
					elem = v[i]
					lines.push " " + fullName + i
					for part in str(elem, depth - 1, seen).split(_NL)
						lines.push "  " + part
					end for
				end for
			end if
		end if
	end for
	if header.len == 1 then
		h = header[0]
	else
		h = header[0] + " " + header[1:].join(", ")
	end if
	lines.insert 0, h
	return lines.join(_NL)
end function


// addProperty: ?
SyntaxNode.addProperty = function(name, value, value2=null)
	if self._propertyFullNames.indexOf(name + " =") != null or self._propertyFullNames.indexOf(name + ":") != null then
		self.properties[name] = @value
	else if self._propertyFullNames.indexOf(name + ".") != null then
		if not self.properties.hasIndex(name) then self.properties[name] = []
		self.properties[name].push @value
	else if self._propertyFullNames.indexOf(name + "..") != null then
		index = value
		value = @value2
		if not self.properties.hasIndex(name) then self.properties[name] = []
		for _ in range(self.properties[name].len, index, 1)
			self.properties[name].push []
		end for
		self.properties[name][index].push @value
	else
		abort "Unable to add property `" + name + "` to " + self._name + " (available properties are " + self.propertyNames + ")"
	end if
end function


// getProperty: ?
SyntaxNode.getProperty = function(name, index=null)
	existsP = false
	for suffix in [" =", ":", ".", ".."]
		if self._propertyFullNames.indexOf(name + suffix) != null then
			existsP = true
			break
		end if
	end for
	if not existsP then abort "Unable to add property `" + name + "` to " + self._name + " (available properties are " + self.propertyNames + ")"
	v = self.properties.get(name)
	if @v == null then return null
	if index == null then return @v
	if index >= v.len then return null
	return v[index]
end function


// Expression: ?
Expression = new SyntaxNode
Expression._name = "ms.Expression"
Expression.parenthesized = null


Expression.init = function(start, length, subject)
	super.init start, length, subject
	self.parenthesized = 0
end function


Expression.parenthesize = function(start, length)
	self.adjust start, length
	self.parenthesized += 1
end function


// Literal: ?
Literal = new Expression
Literal._name = "ms.Literal"


// LitNull: ?
LitNull = new Literal
LitNull._name = "LitNull"


// LitTrue: ?
LitTrue = new Literal
LitTrue._name = "LitTrue"


// LitFalse: ?
LitFalse = new Literal
LitFalse._name = "LitFalse"


// LitNumeral: ?
LitNumeral = new Literal
LitNumeral._name = "LitNumeral"
LitNumeral._propertyFullNames = ["int =", "fract =", "eSign =", "exp =", "val ="]


// LitString: ?
LitString = new Literal
LitString._name = "LitString"
LitString._propertyFullNames = ["text ="]


// LitList: ?
LitList = new Literal
LitList._name = "LitList"
LitList._propertyFullNames = ["elements."]


// LitMap: ?
LitMap = new Literal
LitMap._name = "LitMap"
LitMap._propertyFullNames = ["keys.", "values."]


// LitFunction: ?
LitFunction = new Literal
LitFunction._name = "LitFunction"
LitFunction._propertyFullNames = ["args.", "defaults.", "statements."]
LitFunction.isConfusedFunc = true


// Identifier: ?
Identifier = new Expression
Identifier._name = "Identifier"
Identifier._propertyFullNames = ["name ="]


// Operation: ?
Operation = new Expression
Operation._name = "ms.Operation"
Operation._propertyFullNames = ["operands."]


// OpOr: ?
OpOr = new Operation
OpOr._name = "OpOr"


// OpAnd: ?
OpAnd = new Operation
OpAnd._name = "OpAnd"


// OpNot: ?
OpNot = new Operation
OpNot._name = "OpNot"


// OpIsa: ?
OpIsa = new Operation
OpIsa._name = "OpIsa"


// OpCompare: ?
OpCompare = new Operation
OpCompare._name = "OpCompare"
OpCompare._propertyFullNames = ["operands.", "operators."]


// OpAdd: ?
OpAdd = new Operation
OpAdd._name = "OpAdd"


// OpSubtract: ?
OpSubtract = new Operation
OpSubtract._name = "OpSubtract"


// OpMultiply: ?
OpMultiply = new Operation
OpMultiply._name = "OpMultiply"


// OpDivide: ?
OpDivide = new Operation
OpDivide._name = "OpDivide"


// OpModulo: ?
OpModulo = new Operation
OpModulo._name = "OpModulo"


// OpUMinus: ?
OpUMinus = new Operation
OpUMinus._name = "OpUMinus"


// OpNew: ?
OpNew = new Operation
OpNew._name = "OpNew"


// OpAddress: ?
OpAddress = new Operation
OpAddress._name = "OpAddress"


// OpPower: ?
OpPower = new Operation
OpPower._name = "OpPower"


// OpIndex: ?
OpIndex = new Operation
OpIndex._name = "OpIndex"
OpIndex._propertyFullNames = ["operands.", "key:"]


// OpSlice: ?
OpSlice = new Operation
OpSlice._name = "OpSlice"
OpSlice._propertyFullNames = ["operands.", "from:", "to:"]


// OpDot: ?
OpDot = new Operation
OpDot._name = "OpDot"
OpDot._propertyFullNames = ["operands.", "name ="]


// OpCall: ?
OpCall = new Operation
OpCall._name = "OpCall"
OpCall._propertyFullNames = ["operands.", "args."]


// Statement: ?
Statement = new SyntaxNode
Statement._name = "ms.Statement"
Statement.isLine = false


// StmtEmpty: ?
StmtEmpty = new Statement
StmtEmpty._name = "StmtEmpty"


// StmtCall: ?
StmtCall = new Statement
StmtCall._name = "StmtCall"
StmtCall.isLine = true
StmtCall._propertyFullNames = ["callable:", "args."]


// StmtAssign: ?
StmtAssign = new Statement
StmtAssign._name = "StmtAssign"
StmtAssign.isLine = true
StmtAssign._propertyFullNames = ["left:", "right:", "math ="]


// StmtIf: ?
StmtIf = new Statement
StmtIf._name = "StmtIf"
StmtIf._propertyFullNames = ["conditions.", "statements..", "elseStatements."]


// StmtWhile: ?
StmtWhile = new Statement
StmtWhile._name = "StmtWhile"
StmtWhile._propertyFullNames = ["condition:", "statements."]


// StmtFor: ?
StmtFor = new Statement
StmtFor._name = "StmtFor"
StmtFor._propertyFullNames = ["var =", "expression:", "statements."]


// StmtReturn: ?
StmtReturn = new Statement
StmtReturn._name = "StmtReturn"
StmtReturn.isLine = true
StmtReturn._propertyFullNames = ["expression:"]


// StmtBreak: ?
StmtBreak = new Statement
StmtBreak._name = "StmtBreak"
StmtBreak.isLine = true


// StmtContinue: ?
StmtContinue = new Statement
StmtContinue._name = "StmtContinue"
StmtContinue.isLine = true


// Program: ?
Program = new SyntaxNode
Program._name = "Program"
Program._propertyFullNames = ["file:", "shebang:", "statements."]





// binaryOperators: ?
binaryOperators = {}
binaryOperators["or"] = OpOr
binaryOperators["and"] = OpAnd
binaryOperators["isa"] = OpIsa
binaryOperators["+"] = OpAdd
binaryOperators["-"] = OpSubtract
binaryOperators["*"] = OpMultiply
binaryOperators["/"] = OpDivide
binaryOperators["%"] = OpModulo
binaryOperators["^"] = OpPower


// leftOperators: ?
leftOperators = {}
leftOperators["not"] = OpNot
leftOperators["-"] = OpUMinus
leftOperators["new"] = OpNew
leftOperators["@"] = OpAddress










// definitions: ?
definitions = "" +


"  PhysicalNL       <-  '\r\n'  /  [\r\n]                          " + _NL +
"  Comment          <-  '//'  ( ! PhysicalNL  . ) * {comment}      " + _NL +
"  LogicalNL        <-  Comment ?  PhysicalNL                      " + _NL +


"  LxSep            <-  [ \t] *                                         " + _NL +
"  LxCont           <-  [ \t] *                                         " + _NL +
"                       %if features.multilineContinuations then %      " + _NL +
"                           ( LogicalNL  [ \t] * ) *                    " + _NL +
"                       %else%                                          " + _NL +
"                           ( LogicalNL  [ \t] * ) ?                    " + _NL +
"                       %end if%                                        " + _NL +
"                       ( ! . ) <reportContLine> ?                      " + _NL +


"  StSep            <-  ( ';'  /  LogicalNL )  [ \t] *  " + _NL +


"  AlwaysFail       <-  '' <alwaysFail>  " + _NL +


"  # Keywords                                                                               " + _NL +
"  KeyAnd           <-  'and'       ! [a-zA-Z0-9_]                                          " + _NL +
"  KeyBreak         <-  'break'     ! [a-zA-Z0-9_]                                          " + _NL +
"  KeyContinue      <-  'continue'  ! [a-zA-Z0-9_]                                          " + _NL +
"  KeyElse          <-  'else'      ! [a-zA-Z0-9_]                                          " + _NL +
"  KeyEnd           <-  'end'       ! [a-zA-Z0-9_]                                          " + _NL +
"  KeyFalse         <-  'false'     ! [a-zA-Z0-9_]                                          " + _NL +
"  KeyFor           <-  'for'       ! [a-zA-Z0-9_]                                          " + _NL +
"  KeyFunction      <-  'function'  ! [a-zA-Z0-9_]                                          " + _NL +
"  KeyIf            <-  'if'        ! [a-zA-Z0-9_]                                          " + _NL +
"  KeyIn            <-  'in'        ! [a-zA-Z0-9_]                                          " + _NL +
"  KeyIsa           <-  'isa'       ! [a-zA-Z0-9_]                                          " + _NL +
"  KeyNew           <-  'new'       ! [a-zA-Z0-9_]                                          " + _NL +
"  KeyNot           <-  'not'       ! [a-zA-Z0-9_]                                          " + _NL +
"  KeyNull          <-  'null'      ! [a-zA-Z0-9_]                                          " + _NL +
"  KeyOr            <-  'or'        ! [a-zA-Z0-9_]                                          " + _NL +
"  KeyReturn        <-  'return'    ! [a-zA-Z0-9_]                                          " + _NL +
"  KeyThen          <-  'then'      ! [a-zA-Z0-9_]                                          " + _NL +
"  KeyTrue          <-  'true'      ! [a-zA-Z0-9_]                                          " + _NL +
"  KeyWhile         <-  'while'     ! [a-zA-Z0-9_]                                          " + _NL +
"  Keyword          <-  KeyAnd  /  KeyBreak     /  KeyContinue  /  KeyElse    /  KeyEnd   /  KeyFalse  /            " + _NL +
"                       KeyFor  /  KeyFunction  /  KeyIf        /  KeyIn      /  KeyIsa   /  KeyNew    /            " + _NL +
"                       KeyNot  /  KeyNull      /  KeyOr        /  KeyReturn  /  KeyThen  /  KeyTrue   /  KeyWhile  " + _NL +


"  LitNull          <-  KeyNull {litNull}  LxSep                                            " + _NL +
"  LitTrue          <-  KeyTrue {litTrue}  LxSep                                            " + _NL +
"  LitFalse         <-  KeyFalse {litFalse}  LxSep                                          " + _NL +


"  Identifier       <-  ! Keyword  ( [a-zA-Z_]  [a-zA-Z0-9_] * ) {identifier}  LxSep        " + _NL +


"  NumInt           <-  [0-9] + {int:}                                                      " + _NL +
"  NumFract         <-  [0-9] + {fract:}                                                    " + _NL +
"  NumExpSign       <-  [+-] ? {eSign:}                                                     " + _NL +
"  NumExpDigits     <-  [0-9] + {exp:}                                                      " + _NL +
"  NumSignifDigit   <-  NumInt  ( '.'  NumFract ? ) ?                                       " + _NL +
"  NumSignifDot     <-  '.'  NumFract                                                       " + _NL +
"  NumSignif        <-  NumSignifDigit  /  NumSignifDot                                     " + _NL +
"  NumExp           <-  [Ee]  NumExpSign  NumExpDigits <expectedNumeralExponent!>             " + _NL +
"  LitNumeral       <-  ( NumSignif  NumExp ? ) {litNumeral}  LxSep                         " + _NL +


"  StrChar          <-  %if features.multilineStrings then%                                 " + _NL +
"                           ( ! . ) <reportContString> ?  ! '""'  .                         " + _NL +
"                       %else%                                                              " + _NL +
"                           ! ( '""'  /  PhysicalNL )  .                                    " + _NL +
"                       %end if%                                                            " + _NL +
"  StrContent       <-  ( '""""'  /  StrChar ) * {}                                         " + _NL +
"  StrClose         <-  '""' <expectedStringClose!>                                           " + _NL +
"  LitString        <-  ( '""'  StrContent  StrClose ) {litString}  LxSep                   " + _NL +


"  ExpParens        <-  ( '('  LxCont  Expression <expectedExpression!>  ')' <expectedClosingParen!> ) {expParens}  LxSep     " + _NL +


"  LitList          <-  ( '['  LxCont  ( Expression  ( ','  LxCont  Expression ) *  ( ','  LxCont ) ? ) ?  ']' <expectedClosingBracket!> ) {litList}  LxSep  " + _NL +


"  MapPair          <-  Expression  ':'  LxCont  Expression <expectedValue!>  " + _NL +
"  LitMap           <-  ( '{'  LxCont  ( MapPair  ( ','  LxCont  MapPair ) *  ( ','  LxCont ) ? ) ?  '}' <expectedClosingBrace!> ) {litMap}  LxSep  " + _NL +


"  ExpSimple        <-  LitNull  /  LitTrue  /  LitFalse  /  LitNumeral  /  LitString  /  LitList  /  LitMap  /  Identifier  /  ExpParens  /  " + _NL +
"                       %if features.beheadedFunctions then%                    " + _NL +
"                           (                                                   " + _NL +
"                           %if befBegin then%                                  " + _NL +
"                               KeyFunction <cannotStartTwoFunctions>           " + _NL +
"                           %else%                                              " + _NL +
"                               KeyFunction                                     " + _NL +
"                           %end if%                                            " + _NL +
"                           LxSep  FuncArgList ) {befHead}  (+befBegin)  LxSep  " + _NL +
"                       %else%                                                  " + _NL +
"                           AlwaysFail                                          " + _NL +
"                       %end if%                                                " + _NL +


"  OpMulDivMod      <-  '*'  /  '/'  ! '/'  /  '%'                        " + _NL +
"  OpAddSub         <-  '+'  /  '-'                                       " + _NL +
"  OpCompare        <-  '=='  /  '!='  /  '>'  /  '<'  /  '>='  /  '<='   " + _NL +
"  OpAssign         <-  '='  /  '+='  /  '-='  /  '*='  /  '/='  /  '%='  " + _NL +


"  _OpIndex         <-  ( '['  LxCont  Expression <expectedKey!>  ']' <expectedClosingBracket!> ) {_opIndex}  LxSep  " + _NL +
"  _OpSlice         <-  ( '['  LxCont  Expression {from:0} ?  ':'  LxCont  Expression {to:0} ?  ']' <expectedClosingBracket!> ) {_opSlice}  LxSep  " + _NL +
"  _OpDot           <-  ( '.'  LxCont  Identifier <expectedIdentifier!> ) {_opDot}  LxSep                               " + _NL +
"  _OpCall          <-  ( '('  LxCont  ( Expression  ( ','  LxCont  Expression <expectedCallArg!> ) * ) ?  ')' <expectedClosingParen!> ) {_opCall}  LxSep  " + _NL +
"  ExpAccess        <-  ( ExpSimple  ( _OpIndex <noPrecedingSpaces>  /  _OpSlice  /  _OpDot  /  _OpCall ) * ) {expAccess}                   " + _NL +


"  ExpPower         <-  ( ExpAccess     ( '^' {}          LxCont  ExpAccess     <expectedOperand!> ) * ) {expBinOp}    " + _NL +
"  ExpAddress       <-  ( ( '@'    {op:}  LxCont ) ?  ExpPower )    {expLeftOp}                                           " + _NL +
"  ExpNew           <-  ( ( KeyNew {op:}  LxCont ) ?  ExpAddress )  {expLeftOp}                                           " + _NL +
"  ExpUminus        <-  ( ( '-'    {op:}  LxCont ) ?  ExpNew )      {expLeftOp}                                           " + _NL +
"  ExpMulDivMod     <-  ( ExpUminus     ( OpMulDivMod {}  LxCont  ExpUminus     <expectedOperand!> ) * ) {expBinOp}    " + _NL +
"  ExpAddSub        <-  ( ExpMulDivMod  ( OpAddSub {}     LxCont  ExpMulDivMod  <expectedOperand!> ) * ) {expBinOp}    " + _NL +
"  ExpCompare       <-  ( ExpAddSub     ( OpCompare {}    LxCont  ExpAddSub     <expectedOperand!> ) * ) {expCompare}  " + _NL +
"  ExpIsa           <-  ( ExpCompare    ( KeyIsa {}       LxCont  ExpCompare    <expectedType!>    ) * ) {expBinOp}    " + _NL +
"  ExpNot           <-  ( ( KeyNot {op:}  LxCont ) ?  ExpIsa    )   {expLeftOp}                                           " + _NL +
"  ExpAnd           <-  ( ExpNot        ( KeyAnd {}       LxCont  ExpNot        <expectedOperand!> ) * ) {expBinOp}    " + _NL +
"  ExpOr            <-  ( ExpAnd        ( KeyOr {}        LxCont  ExpAnd        <expectedOperand!> ) * ) {expBinOp}    " + _NL +
"  Expression       <-  ExpOr                                                                                             " + _NL +


"  FuncCont         <-  LxSep  ( ! . ) <reportContFunction> ?  StSep <expectedStatementSeparator!>  ( ! . ) <reportContFunction> ?  " + _NL +
"  FuncArgDefault   <-  LitNull  /  LitNumeral  /  LitString  " + _NL +
"  FuncArg          <-  ( Identifier  ( '='  LxCont  FuncArgDefault {default:0} ) ? ) {funcArg}  " + _NL +
"  FuncArgList      <-  '('  LxCont  ( FuncArg  ( ','  LxCont  FuncArg ) *  ( ','  LxCont ) ? ) ?  ')'  LxSep  " + _NL +
"  FuncEnd          <-  KeyEnd <expectedEndFunction!>  LxSep  KeyFunction <expectedFunctionAfterEnd!>  " + _NL +
"  FuncDef          <-  ( KeyFunction  LxSep  FuncArgList ?  FuncCont  (-insideLoop)  ( Statement  FuncCont ) *  FuncEnd  (/insideLoop) ) {funcDef}  LxSep  " + _NL +


"  StmtBreak        <-  KeyBreak <breakInsideLoop> {stmtBreak}  LxSep  " + _NL +


"  StmtContinue     <-  KeyContinue <continueInsideLoop> {stmtContinue}  LxSep  " + _NL +


"  StmtReturn       <-  ( KeyReturn  LxSep  ( Expression  /  FuncDef ) ? ) {stmtReturn}  LxSep  " + _NL +


"  ForCont          <-  LxSep  ( ! . ) <reportContFor> ?  StSep <expectedStatementSeparator!>  ( ! . ) <reportContFor> ?  " + _NL +
"  ForStart         <-  KeyFor  LxSep  Identifier <expectedForVariable!>  KeyIn <expectedIn!>  LxSep  Expression <expectedForExpression!>  ForCont  " + _NL +
"  ForEnd           <-  KeyEnd <expectedEndFor!>  LxSep  KeyFor <expectedForAfterEnd!>  " + _NL +
"  StmtFor          <-  ( ForStart  (+insideLoop)  ( Statement  ForCont ) *  ForEnd  (/insideLoop) ) {stmtFor}  LxSep  " + _NL +


"  WhileCont        <-  LxSep  ( ! . ) <reportContWhile> ?  StSep <expectedStatementSeparator!>  ( ! . ) <reportContWhile> ?  " + _NL +
"  WhileStart       <-  KeyWhile  LxSep  Expression <expectedCondition!>  WhileCont  " + _NL +
"  WhileEnd         <-  KeyEnd <expectedEndWhile!>  LxSep  KeyWhile <expectedWhileAfterEnd!>  " + _NL +
"  StmtWhile        <-  ( WhileStart  (+insideLoop)  ( Statement  WhileCont ) *  WhileEnd  (/insideLoop) ) {stmtWhile}  LxSep  " + _NL +


"  IfShortStart     <-  KeyIf  LxSep  Expression <expectedCondition!>  KeyThen <expectedThen!>  LxSep  " + _NL +
"  IfShortInside    <-  Statement <ifShortInside>  " + _NL +
"  IfShortElse      <-  KeyElse  LxSep  IfShortInside  " + _NL +
"  StmtIfShort      <-  ( IfShortStart  IfShortInside  IfShortElse ? ) {stmtIfShort}  LxSep  " + _NL +


"  IfCont           <-  LxSep  ( ! . ) <reportContIf> ?  StSep <expectedStatementSeparator!>  ( ! . ) <reportContIf> ?  " + _NL +
"  IfStart          <-  KeyIf  LxSep  Expression <expectedCondition!>  KeyThen <expectedThen!>  IfCont  " + _NL +
"  IfInside         <-  ( Statement  IfCont ) *  " + _NL +
"  IfElseIf         <-  KeyElse  LxSep  KeyIf  LxSep  Expression <expectedCondition!>  KeyThen <expectedThen!>  IfCont  IfInside  " + _NL +
"  IfElse           <-  KeyElse {}  IfCont  IfInside  " + _NL +
"  IfEnd            <-  KeyEnd <expectedEndIf!>  LxSep  KeyIf <expectedIfAfterEnd!>  " + _NL +
"  StmtIf           <-  ( IfStart  IfInside  IfElseIf *  IfElse ?  IfEnd ) {stmtIf}  LxSep  " + _NL +


"  StmtAssign       <-  ( Expression <leftAccess>  OpAssign {}  LxCont  ( Expression  /  FuncDef ) <expectedExpression!> ) {stmtAssign}  " + _NL +


"  CallArgList      <-  Expression  ( ','  LxCont  Expression <expectedCallArg!> ) *  (','  LxCont  FuncDef) ?  /  FuncDef  " + _NL +
"  StmtCall         <-  ( Expression <stmtCallFunc>  CallArgList ? ) {stmtCall}  " + _NL +


"  Statement        <-  %if befBegin then%  " + _NL +
"                           ( (/befBegin)  (-insideLoop)  ( Statement  FuncCont ) *  FuncEnd  (/insideLoop) ) {befBody}  LxSep  " + _NL +
"                       %else%  " + _NL +
"                           StmtBreak  /  StmtContinue  /  StmtReturn  /            " + _NL +
"                           StmtFor  /  StmtWhile  /  StmtIfShort  /  StmtIf  /     " + _NL +
"                           StmtAssign  /  StmtCall  /  '' {stmtEmpty}              " + _NL +
"                       %end if%  " + _NL +


"  Shebang          <-  %if features.parseShebang then%                                 " + _NL +
"                           ( '#!'  ( ! PhysicalNL  . ) * {shebang:}  PhysicalNL ) ?    " + _NL +
"                       %else%                                                          " + _NL +
"                           ''                                                          " + _NL +
"                       %end if%                                                        " + _NL +
"  Program          :   ( Shebang  [ \t] *  Statement  ( StSep  Statement ) *  Comment ? ) ? {program}  ( ! . ) <couldNotParseEverything!>  " + _NL +


""


// grammar: ?
grammar = new peg.Grammar
grammar.init definitions


// Captures a comment (// foo).
capComment = function(match, subcaptures, arg, ctx)
	lc = lineColumn(ctx.subject, match.start)
	arg.comments[lc.line] = match.fragment
	return subcaptures
end function
grammar.capture "comment", @capComment


// Captures `null` literal.
capLitNull = function(match, subcaptures, arg, ctx)
	node = new LitNull
	node.init match.start, match.length, ctx.subject
	return node
end function
grammar.capture "litNull", @capLitNull


// Captures `true` literal.
capLitTrue = function(match, subcaptures, arg, ctx)
	node = new LitTrue
	node.init match.start, match.length, ctx.subject
	return node
end function
grammar.capture "litTrue", @capLitTrue


// Captures `false` literal.
capLitFalse = function(match, subcaptures, arg, ctx)
	node = new LitFalse
	node.init match.start, match.length, ctx.subject
	return node
end function
grammar.capture "litFalse", @capLitFalse


// Captures numerals: 1.23e4.
capLitNumeral = function(match, subcaptures, arg, ctx)
	node = new LitNumeral
	node.init match.start, match.length, ctx.subject
	node.addProperty "int", subcaptures.map.get("int")
	node.addProperty "fract", subcaptures.map.get("fract")
	node.addProperty "eSign", subcaptures.map.get("eSign")
	node.addProperty "exp", subcaptures.map.get("exp")
	node.addProperty "val", match.fragment.val
	return node
end function
grammar.capture "litNumeral", @capLitNumeral


// Captures strings: "hello!".
capLitString = function(match, subcaptures, arg, ctx)
	node = new LitString
	node.init match.start, match.length, ctx.subject
	node.addProperty "text", subcaptures.list[0]
	return node
end function
grammar.capture "litString", @capLitString


// Captures list literals: [X, Y, Z].
capLitList = function(match, subcaptures, arg, ctx)
	node = new LitList
	node.init match.start, match.length, ctx.subject
	for cap in subcaptures.list
		node.addProperty "elements", cap
	end for
	return node
end function
grammar.capture "litList", @capLitList


// Captures map literals: {X: Y, Z: W}.
capLitMap = function(match, subcaptures, arg, ctx)
	node = new LitMap
	node.init match.start, match.length, ctx.subject
	for i in range(0, subcaptures.list.len - 1, 2)
		node.addProperty "keys", subcaptures.list[i]
		node.addProperty "values", subcaptures.list[i + 1]
	end for
	return node
end function
grammar.capture "litMap", @capLitMap


// Captures identifiers: foo.
capIdentifier = function(match, subcaptures, arg, ctx)
	node = new Identifier
	node.init match.start, match.length, ctx.subject
	node.addProperty "name", match.fragment
	return node
end function
grammar.capture "identifier", @capIdentifier


// Captures expressions in parens: (...).
capExpParens = function(match, subcaptures, arg, ctx)
	node = subcaptures.list[0]
	if node isa _BefHead then
		node.start = match.start
		node.length = match.length
		node.parenthesized += 1
	else
		node.parenthesize match.start, match.length
	end if
	return node
end function
grammar.capture "expParens", @capExpParens


// Captures binary operations: X + Y, X * Y, etc.
capExpBinOp = function(match, subcaptures, arg, ctx)
	node = subcaptures.list[0]
	for i in range(1, subcaptures.list.len - 1, 2)
		operator = subcaptures.list[i]
		rightOperand = subcaptures.list[i + 1]
		opclass = binaryOperators.get(operator)
		if opclass == null then abort "Unknown binary operator `" + operator + "`"
		_node = new opclass
		length = (rightOperand.start + rightOperand.length) - match.start
		_node.init match.start, length, ctx.subject
		_node.addProperty "operands", node
		_node.addProperty "operands", rightOperand
		node = _node
	end for
	return node
end function
grammar.capture "expBinOp", @capExpBinOp


// Captures left operations: not X, - X, etc.
capExpLeftOp = function(match, subcaptures, arg, ctx)
	node = subcaptures.list[0]
	operator = subcaptures.map.get("op")
	if operator == null then return node
	opclass = leftOperators.get(operator)
	if opclass == null then abort "Unknown left operator `" + operator + "`"
	_node = new opclass
	length = (node.start + node.length) - match.start
	_node.init match.start, length, ctx.subject
	_node.addProperty "operands", node
	return _node
end function
grammar.capture "expLeftOp", @capExpLeftOp


// Captures comparison chain: X < Y < Z.
capExpCompare = function(match, subcaptures, arg, ctx)
	node = subcaptures.list[0]
	if subcaptures.list.len == 1 then return node
	_node = new OpCompare
	_node.init match.start, match.length, ctx.subject
	_node.addProperty "operands", node
	for i in range(1, subcaptures.list.len - 1, 2)
		_node.addProperty "operators", subcaptures.list[i]
		_node.addProperty "operands", subcaptures.list[i + 1]
	end for
	return _node
end function
grammar.capture "expCompare", @capExpCompare


// Captures indexing with square brackets: ...[X].
cap_opIndex = function(match, subcaptures, arg, ctx)
	cap = {}
	cap.type = "index"
	cap.match = match
	cap.key = subcaptures.list[0]
	return cap
end function
grammar.capture "_opIndex", @cap_opIndex


// Captures slicing: ...[X:Y].
cap_opSlice = function(match, subcaptures, arg, ctx)
	cap = {}
	cap.type = "slice"
	cap.match = match
	cap.from = subcaptures.map.get("from")
	cap.to = subcaptures.map.get("to")
	return cap
end function
grammar.capture "_opSlice", @cap_opSlice


// Captures indexing with a dot: ... .X.
cap_opDot = function(match, subcaptures, arg, ctx)
	cap = {}
	cap.type = "dot"
	cap.match = match
	cap.name = subcaptures.list[0].getProperty("name")
	return cap
end function
grammar.capture "_opDot", @cap_opDot


// Captures function calls: ...(X,Y,Z).
cap_opCall = function(match, subcaptures, arg, ctx)
	cap = {}
	cap.type = "call"
	cap.match = match
	cap.args = subcaptures.list
	return cap
end function
grammar.capture "_opCall", @cap_opCall


// Captures an access action (indexing or func call).
capExpAccess = function(match, subcaptures, arg, ctx)
	node = subcaptures.list[0]
	for cap in subcaptures.list[1:]
		length = (cap.match.start + cap.match.length) - node.start
		if cap.type == "index" then
			_node = new OpIndex
			_node.init node.start, length, ctx.subject
			_node.addProperty("operands", node)
			_node.addProperty("key", cap.key)
			node = _node
		else if cap.type == "slice" then
			_node = new OpSlice
			_node.init node.start, length, ctx.subject
			_node.addProperty("operands", node)
			if cap.from != null then _node.addProperty("from", cap.from)
			if cap.to != null then _node.addProperty("to", cap.to)
			node = _node
		else if cap.type == "dot" then
			_node = new OpDot
			_node.init node.start, length, ctx.subject
			_node.addProperty("operands", node)
			_node.addProperty("name", cap.name)
			node = _node
		else if cap.type == "call" then
			_node = new OpCall
			_node.init node.start, length, ctx.subject
			_node.addProperty("operands", node)
			for _arg in cap.args
				_node.addProperty("args", _arg)
			end for
			node = _node
		else
			abort "Unknown access type: `" + cap.type + "`"
		end if
	end for
	return node
end function
grammar.capture "expAccess", @capExpAccess


// Captures an empty statement.
capStmtEmpty = function(match, subcaptures, arg, ctx)
	node = new StmtEmpty
	node.init match.start, 0, ctx.subject
	return node
end function
grammar.capture "stmtEmpty", @capStmtEmpty


// Captures a simple call statement: F X, Y, Z.
capStmtCall = function(match, subcaptures, arg, ctx)
	node = new StmtCall
	node.init match.start, match.length, ctx.subject
	node.addProperty "callable", subcaptures.list[0]
	for cap in subcaptures.list[1:]
		node.addProperty "args", cap
	end for
	return node
end function
grammar.capture "stmtCall", @capStmtCall


// Captures an assignment statement: X = Y.
capStmtAssign = function(match, subcaptures, arg, ctx)
	node = new StmtAssign
	node.init match.start, match.length, ctx.subject
	node.addProperty "left", subcaptures.list[0]
	node.addProperty "math", subcaptures.list[1][-2:-1]
	
	//
	right = subcaptures.list[2]
	if right isa LitFunction then
		right.isConfusedFunc = false
	end if
	//
	
	node.addProperty "right", right
	return node
end function
grammar.capture "stmtAssign", @capStmtAssign


// Captures an if statement: if ... end if.
capStmtIf = function(match, subcaptures, arg, ctx)
	node = new StmtIf
	node.init match.start, match.length, ctx.subject
	index = -1
	for cap in subcaptures.list
		if cap isa Expression then
			index += 1
			node.addProperty "conditions", cap
		else if cap isa Statement then
			if index >= 0 then
				node.addProperty "statements", index, cap
			else
				node.addProperty "elseStatements", cap
			end if
		else if cap == "else" then
			index = -1
		else
			abort "Unexpected capture inside if-statement: `" + str(cap) + "`"
		end if
	end for
	return node
end function
grammar.capture "stmtIf", @capStmtIf


// Captures a short if statement: if X then Y.
capStmtIfShort = function(match, subcaptures, arg, ctx)
	node = new StmtIf
	node.init match.start, match.length, ctx.subject
	node.isLine = true
	node.addProperty "conditions", subcaptures.list[0]
	node.addProperty "statements", 0, subcaptures.list[1]
	if subcaptures.list.len > 2 then node.addProperty "elseStatements", subcaptures.list[2]
	return node
end function
grammar.capture "stmtIfShort", @capStmtIfShort


// Captures a while statement: while ... end while.
capStmtWhile = function(match, subcaptures, arg, ctx)
	node = new StmtWhile
	node.init match.start, match.length, ctx.subject
	node.addProperty "condition", subcaptures.list[0]
	for cap in subcaptures.list[1:]
		node.addProperty "statements", cap
	end for
	return node
end function
grammar.capture "stmtWhile", @capStmtWhile


// Captures a for statement: for ... end for.
capStmtFor = function(match, subcaptures, arg, ctx)
	node = new StmtFor
	node.init match.start, match.length, ctx.subject
	node.addProperty "var", subcaptures.list[0].getProperty("name")
	node.addProperty "expression", subcaptures.list[1]
	for cap in subcaptures.list[2:]
		node.addProperty "statements", cap
	end for
	return node
end function
grammar.capture "stmtFor", @capStmtFor


// Captures a return statement: return X.
capStmtReturn = function(match, subcaptures, arg, ctx)
	node = new StmtReturn
	node.init match.start, match.length, ctx.subject
	if subcaptures.list.len > 0 then node.addProperty "expression", subcaptures.list[0]
	return node
end function
grammar.capture "stmtReturn", @capStmtReturn


// Captures a break statement: break.
capStmtBreak = function(match, subcaptures, arg, ctx)
	node = new StmtBreak
	node.init match.start, match.length, ctx.subject
	return node
end function
grammar.capture "stmtBreak", @capStmtBreak


// Captures a continue statement: continue.
capStmtContinue = function(match, subcaptures, arg, ctx)
	node = new StmtContinue
	node.init match.start, match.length, ctx.subject
	return node
end function
grammar.capture "stmtContinue", @capStmtContinue


_FuncArg = {"_name": "_FuncArg"}


// Captures a function argument: (... X ... Y=null ...).
capFuncArg = function(match, subcaptures, arg, ctx)
	fa = new _FuncArg
	fa.name = subcaptures.list[0].getProperty("name")
	fa.default = subcaptures.map.get("default")
	return fa
end function
grammar.capture "funcArg", @capFuncArg


// Captures a function definition: function ... end function.
capFuncDef = function(match, subcaptures, arg, ctx)
	node = new LitFunction
	node.init match.start, match.length, ctx.subject
	for cap in subcaptures.list
		if cap isa _FuncArg then
			node.addProperty "args", cap.name
			node.addProperty "defaults", cap.default
		else if cap isa Statement then
			node.addProperty "statements", cap
		else
			abort "Unknown element of a function definition: `" + str(cap) + "`"
		end if
	end for
	return node
end function
grammar.capture "funcDef", @capFuncDef


// _implantProperty: ?
_implantProperty = function(node, propertyName, befLiterals)
	p = node.getProperty(propertyName)
	if p isa _BefHead then
		
		//
		node.properties[propertyName] = befLiterals[p.id]
		//
		
		befLiterals.remove p.id
		return true  // break recursion
	else if _implantBefLiteral(p, befLiterals) then
		return true  // break recursion
	end if
end function


// _implantListProperty: ?
_implantListProperty = function(node, propertyName, befLiterals)
	pp = node.getProperty(propertyName)
	if not pp then return
	for i in pp.indexes
		p = pp[i]
		if p isa _BefHead then
			
			//
			pp[i] = befLiterals[p.id]
			//
			
			befLiterals.remove p.id
			return true  // break recursion
		else if _implantBefLiteral(p, befLiterals) then
			return true  // break recursion
		end if
	end for
end function


// _implantMatrixProperty: ?
_implantMatrixProperty = function(node, propertyName, befLiterals)
	ppp = node.getProperty(propertyName)
	if not ppp then return
	for i in ppp.indexes
		pp = ppp[i]
		if not pp then continue
		for j in pp.indexes
			p = pp[j]
			if p isa _BefHead then
				
				//
				pp[j] = befLiterals[p.id]
				//
				
				befLiterals.remove p.id
				return true  // break recursion
			else if _implantBefLiteral(p, befLiterals) then
				return true  // break recursion
			end if
		end for
	end for
end function


// _implantBefLiteral: ?
_implantBefLiteral = function(node, befLiterals)
	
	if node isa LitList then
		
		if _implantListProperty(node, "elements", befLiterals) then return true // break recursion
		
	else if node isa LitMap then
		
		if _implantListProperty(node, "keys", befLiterals) then return true // break recursion
		
		if _implantListProperty(node, "values", befLiterals) then return true // break recursion
		
	else if node isa LitFunction then
		
		if _implantListProperty(node, "statements", befLiterals) then return true // break recursion
		
	else if node isa OpIndex then
		
		if _implantListProperty(node, "operands", befLiterals) then return true // break recursion
		
		if _implantProperty(node, "key", befLiterals) then return true // break recursion
		
	else if node isa OpSlice then
		
		if _implantListProperty(node, "operands", befLiterals) then return true // break recursion
		
		if _implantProperty(node, "from", befLiterals) then return true // break recursion
		
		if _implantProperty(node, "to", befLiterals) then return true // break recursion
		
	else if node isa OpCall then
		
		if _implantListProperty(node, "operands", befLiterals) then return true // break recursion
		
		if _implantListProperty(node, "args", befLiterals) then return true // break recursion
		
	else if node isa Operation then
		
		if _implantListProperty(node, "operands", befLiterals) then return true // break recursion
		
	else if node isa StmtCall then
		
		if _implantProperty(node, "callable", befLiterals) then return true // break recursion
		
		if _implantListProperty(node, "args", befLiterals) then return true // break recursion
		
	else if node isa StmtAssign then
		
		if _implantProperty(node, "left", befLiterals) then return true // break recursion
		
		if _implantProperty(node, "right", befLiterals) then return true // break recursion
		
	else if node isa StmtIf then
		
		if _implantListProperty(node, "conditions", befLiterals) then return true // break recursion
		
		if _implantMatrixProperty(node, "statements", befLiterals) then return true // break recursion
		
		if _implantListProperty(node, "elseStatements", befLiterals) then return true // break recursion
		
	else if node isa StmtWhile then
		
		if _implantProperty(node, "condition", befLiterals) then return true // break recursion
		
		if _implantListProperty(node, "statements", befLiterals) then return true // break recursion
		
	else if node isa StmtFor then
		
		if _implantProperty(node, "expression", befLiterals) then return true // break recursion
		
		if _implantListProperty(node, "statements", befLiterals) then return true // break recursion
		
	else if node isa StmtReturn then
		
		if _implantProperty(node, "expression", befLiterals) then return true // break recursion
		
	else if node isa Program then
		
		if _implantListProperty(node, "statements", befLiterals) then return true // break recursion
		
	end if
	
end function


// Captures a whole program.
capProgram = function(match, subcaptures, arg, ctx)
	node = new Program
	node.init match.start, match.length, ctx.subject
	node.addProperty "shebang", subcaptures.map.get("shebang")
	for cap in subcaptures.list
		node.addProperty "statements", cap
	end for
	if arg and arg.hasIndex("befLiterals") then
		while arg.befLiterals.len > 0
			_implantBefLiteral node, arg.befLiterals
		end while
	end if
	return node
end function
grammar.capture "program", @capProgram


_BefHead = {"_name": "_BefHead"}


// Captures a function header inside expression: ( ... function() ... ).
capBefHead = function(match, subcaptures, arg, ctx)
	head = new _BefHead
	head.start = match.start
	head.length = match.length
	head.parenthesized = 0
	head.arg = []
	head.default = []
	for cap in subcaptures.list
		if cap isa _FuncArg then
			head.arg.push cap.name
			head.default.push cap.default
		else
			abort "Unknown element of a beheaded function start: `" + str(cap) + "`"
		end if
	end for
	head.id = arg.befNextId
	arg.befNextId += 1
	arg.befHeadStack.push head
	return head
end function
grammar.capture "befHead", @capBefHead


// Captures a beheaded function body: ... end function.
capBefBody = function(match, subcaptures, arg, ctx)
	head = arg.befHeadStack.pop
	if not head then return peg.SemanticError("Lost function head (probably ms.ms bug)")
	start = head.start
	length = match.start + match.length - start
	node = new LitFunction
	node.init start, length, ctx.subject
	for i in head.arg.indexes
		node.addProperty "args", head.arg[i]
		node.addProperty "defaults", head.default[i]
	end for
	for cap in subcaptures.list
		if cap isa Statement then
			node.addProperty "statements", cap
		else
			abort "Unknown element of a function definition: `" + str(cap) + "`"
		end if
	end for
	node.parenthesized = head.parenthesized
	arg.befLiterals[head.id] = node
	while subcaptures.list
		subcaptures.list.pop
	end while
	return subcaptures
end function
grammar.capture "befBody", @capBefBody






//






// _makeContinuationError: Creates a continuation error.
_makeContinuationError = function(errorTag)
	if errorTag == "contLine" then
		err = new ContLine
		err.message = "Need more input to complete an expression or complex literal"
	else if errorTag == "contString" then
		err = new ContString
		err.message = "Need more input to complete a string literal"
	else if errorTag == "contIf" then
		err = new ContIf
		err.message = "Need more input to complete an if-statement"
	else if errorTag == "contWhile" then
		err = new ContWhile
		err.message = "Need more input to complete a while-statement"
	else if errorTag == "contFor" then
		err = new ContFor
		err.message = "Need more input to complete a for-statement"
	else if errorTag == "contFunction" then
		err = new ContFunction
		err.message = "Need more input to complete a function"
	else
		abort "Unknown continuation tag `" + errorTag + "`"
	end if
	err.tag = errorTag
	return err
end function


// Adds a continuation error in the middle of an expression or complex literal.
mtReportContLine = function(match, subcaptures, arg, ctx)
	if match != null then
		ctx.syntaxErrors.push _makeContinuationError("contLine")
	end if
end function
grammar.matchTime "reportContLine", @mtReportContLine


// Adds a continuation error in the middle of a string literal.
mtReportContString = function(match, subcaptures, arg, ctx)
	if match != null then
		ctx.syntaxErrors.push _makeContinuationError("contString")
	end if
end function
grammar.matchTime "reportContString", @mtReportContString


// Adds a continuation error in the middle of an if-statement.
mtReportContIf = function(match, subcaptures, arg, ctx)
	if match != null then
		ctx.syntaxErrors.push _makeContinuationError("contIf")
	end if
end function
grammar.matchTime "reportContIf", @mtReportContIf


// Adds a continuation error in the middle of a while-loop.
mtReportContWhile = function(match, subcaptures, arg, ctx)
	if match != null then
		ctx.syntaxErrors.push _makeContinuationError("contWhile")
	end if
end function
grammar.matchTime "reportContWhile", @mtReportContWhile


// Adds a continuation error in the middle of a for-loop.
mtReportContFor = function(match, subcaptures, arg, ctx)
	if match != null then
		ctx.syntaxErrors.push _makeContinuationError("contFor")
	end if
end function
grammar.matchTime "reportContFor", @mtReportContFor


// Adds a continuation error in the middle of a function definition.
mtReportContFunction = function(match, subcaptures, arg, ctx)
	if match != null then
		ctx.syntaxErrors.push _makeContinuationError("contFunction")
	end if
end function
grammar.matchTime "reportContFunction", @mtReportContFunction




//





// Makes pattern fail no matter what.
mtAlwaysFail = function(match, subcaptures, arg, ctx)
	return null
end function
grammar.matchTime "alwaysFail", @mtAlwaysFail


// Checks that there are no spaces before the match.
mtNoPrecedingSpaces = function(match, subcaptures, arg, ctx)
	if match == null then return null
	charBefore = ctx.subject[match.start - 1 : match.start]
	if charBefore == "" then return match
	if charBefore == " " then return null
	if charBefore == char(9) then return null
	return match
end function
grammar.matchTime "noPrecedingSpaces", @mtNoPrecedingSpaces


// Checks that the left side of assignment is lvalue.
mtLeftAccess = function(match, subcaptures, arg, ctx)
	if match == null then return null
	lvalue = subcaptures.list[0]
	_lv = lvalue
	while _lv isa OpAddress
		_lv = _lv.getProperty("operands")[0]
	end while
	for nodeClass in [OpIndex, OpDot, Identifier]
		if _lv isa nodeClass then return match
	end for
	ctx.addSyntaxError "badLValue", "Bad lvalue: " + str(_lv)
	return null
end function
grammar.matchTime "leftAccess", @mtLeftAccess


// Checks that `X -Y` is interpreted as a call and not a subtraction.
mtStmtCallFunc = function(match, subcaptures, arg, ctx)
	if match == null then return null
	func = subcaptures.list[0]
	if func isa OpSubtract then
		operands = func.getProperty("operands")
		left = operands[0]
		right = operands[1]
		between = ctx.subject[left.start + left.length : right.start]
		spaces = between.split("-")
		if spaces[0].len > 0 and spaces[1].len == 0 then
			func = operands[0]
			start = func.start
			length = func.length + spaces[0].len
			fragment = ctx.subject[start : start + length]
			m = new peg.Match
			m.init start, length, fragment
			m.capture = function(_,_,_,_)
				return func
			end function
			return m
		end if
	end if
	return match
end function
grammar.matchTime "stmtCallFunc", @mtStmtCallFunc


// Checks that only one-line statements can be placed inside "short if"s.
mtIfShortInside = function(match, subcaptures, arg, ctx)
	if match == null then return null
	statement = subcaptures.list[0]
	if statement.isLine then return match
	if statement isa StmtEmpty then return null
	ctx.addSyntaxError "complexStatementInsideShortIf", "Expected a simple statement inside a 'short if', got `" + str(statement) + "`"
	return null
end function
grammar.matchTime "ifShortInside", @mtIfShortInside


// Checks that a break statement is inside a loop.
mtBreakInsideLoop = function(match, subcaptures, arg, ctx)
	if match == null then return null
	if not ctx.getFlag(match.start, "insideLoop") then
		lc = lineColumn(ctx.subject, match.start)
		ctx.addSyntaxError "breakOutsideLoop", "Break-statement outside a loop at line {line}, column {column}".fill(lc)
		return null
	end if
	return match
end function
grammar.matchTime "breakInsideLoop", @mtBreakInsideLoop


// Checks that a continue statement is inside a loop.
mtContinueInsideLoop = function(match, subcaptures, arg, ctx)
	if match == null then return null
	if not ctx.getFlag(match.start, "insideLoop") then
		lc = lineColumn(ctx.subject, match.start)
		ctx.addSyntaxError "continueOutsideLoop", "Continue-statement outside a loop at line {line}, column {column}".fill(lc)
		return null
	end if
	return match
end function
grammar.matchTime "continueInsideLoop", @mtContinueInsideLoop


// Report if more than one beheaded function started in a statement.
mtCannotStartTwoFunctions = function(match, subcaptures, arg, ctx)
	if match == null then return null
	lc = lineColumn(ctx.subject, match.start)
	ctx.addSyntaxError "cannotStartTwoFunctions", "Attempted to start a second function on the same line {line}, column {column}".fill(lc)
	return null
end function
grammar.matchTime "cannotStartTwoFunctions", @mtCannotStartTwoFunctions




//








// EvalMode: ?
EvalMode = {}
EvalMode.line = "line"
EvalMode.run = "run"
EvalMode.import = "import"







// Context: ?
Context = {}
Context._name = "ms.Context"
Context._inited = false
Context.mode = null
Context.features = null
Context.intrinsics = null
Context.globals = null
Context.outer = null
Context.locals = null
Context.globalName = null
Context.trimRightSpaces = true


Context.init = function(m=null)
	self._inited = true
	if m == null then m = {}
	self.evalMode = m.get("evalMode", EvalMode.line)
	if self.evalMode == EvalMode.line then
		defaultFeatures = v16
	else
		defaultFeatures = v16File
	end if
	self.features = defaultFeatures + m.get("features", {})
	self.intrinsics = m.get("intrinsics")
	self.globals = m.get("globals", globals)
	self.outer = m.get("outer", self.globals)
	if self.evalMode == EvalMode.import then
		self.locals = m.get("locals", {})
	else
		self.locals = m.get("locals", self.globals)
	end if
	if m.hasIndex("globalName") then
		self.globalName = m.globalName
		self.globals[m.globalName] = self
	end if
	
	
	
	
	
	
end function


// build: ?
Context.build = function(m=null)
	if m == null then m = {}
	if not m isa Context then
		c = new Context
		c.init m
		for kv in c
			m[@kv.key] = @kv.value
		end for
	end if
	return m
end function







// _makeParseArg: ?
_makeParseArg = function(features=null)
	if features == null then features = {}
	arg = {}
	arg.features = features
	arg.comments = {}
	arg.befNextId = 1
	arg.befHeadStack = []
	arg.befLiterals = {}
	return arg
end function








// ParseResult: ?
ParseResult = {}
ParseResult._name = "ms.ParseResult"
ParseResult._inited = false
ParseResult.program = null
ParseResult.errors = null
ParseResult.comments = null
ParseResult.needMoreInput = null
ParseResult._result = null


ParseResult.init = function(pegResult, arg)
	self._inited = true
	self._result = pegResult
	self.comments = arg.comments
	if pegResult.length != null then self.program = pegResult.capture
	self.errors = pegResult.errors
	self.needMoreInput = pegResult.hasErrorType(Continuation)
end function















// parse: ?
parse = function(text, context=null)
	context = Context.build(context)
	arg = _makeParseArg(context.features)
	if context.trimRightSpaces then text = text.trimRight
	pegResult = grammar.parse(text, 0, arg)
	result = new ParseResult
	result.init pegResult, arg
	return result
end function


// parseFile: ?
parseFile = function(fileName, context=null)
	f = file.open(fileName)
	text = f.read()
	f.close
	if context == null then context = {}
	if not context.hasIndex("evalMode") then context.evalMode = EvalMode.run
	result = parse(text, context)
	if result.program != null then result.program.addProperty "file", fileName
	return result
end function
















// eval: ?
eval = function(text, context=null)
	
	
	
	// return result or error ?
	
end function


// evalFile: ?
evalFile = function(fileName, context=null)
	
	
	
	// return result or error ?
	
end function


















