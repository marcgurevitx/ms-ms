// MiniScript parser and evaluator.


// ensureImport: Imports a module and caches it in `globals`.
// Use an existing function if present.
// (Some platforms don't have this or the user might have implemented their own `ensureImport`.)
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
ensureImport "peg"


// _noVal: ?
_noVal = {}


// _exceeded: ?
_exceeded = {}


iVersion = @version
version = "0.0.0"


// _NL: A platform specific line break.
if iVersion.hostName == "Mini Micro" then _NL = char(13) else _NL = char(10)


// intrinsics: ?
if iVersion.miniscript.split(".")[:2].join(".").val <= 1.6 then
	intrinsics = {}
	intrinsics.abs = @abs
	intrinsics.acos = @acos
	intrinsics.asin = @asin
	intrinsics.atan = @atan
	intrinsics.bitAnd = @bitAnd
	intrinsics.bitOr = @bitOr
	intrinsics.bitXor = @bitXor
	intrinsics.code = @code
	intrinsics.cos = @cos
	intrinsics.funcRef = @funcRef
	intrinsics.hasIndex = @hasIndex
	intrinsics.hash = @hash
	intrinsics.indexOf = @indexOf
	intrinsics.indexes = @indexes
	intrinsics.insert = @insert
	intrinsics.join = @join
	intrinsics.len = @len
	intrinsics.list = @list
	intrinsics.log = @log
	intrinsics.lower = @lower
	intrinsics.map = @map
	intrinsics.number = @number
	intrinsics.pi = @pi
	intrinsics.pop = @pop
	intrinsics.print = @print
	intrinsics.pull = @pull
	intrinsics.push = @push
	intrinsics.range = @range
	intrinsics.refEquals = @refEquals
	intrinsics.remove = @remove
	intrinsics.replace = @replace
	intrinsics.rnd = @rnd
	intrinsics.round = @round
	intrinsics.shuffle = @shuffle
	intrinsics.sin = @sin
	intrinsics.slice = @slice
	intrinsics.sort = @sort
	intrinsics.split = @split
	intrinsics.str = @str
	intrinsics.string = @string
	intrinsics.sum = @sum
	intrinsics.tan = @tan
	intrinsics.time = @time
	intrinsics.upper = @upper
	intrinsics.val = @val
	intrinsics.values = @values
	intrinsics.wait = @wait
end if


// None: ?
None = {}
None._name = "None"










//            _|      _|  _|            
//_|    _|  _|_|_|_|      _|    _|_|_|  
//_|    _|    _|      _|  _|  _|_|      
//_|    _|    _|      _|  _|      _|_|  
//  _|_|_|      _|_|  _|  _|  _|_|_|    


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


// safeMapGet: ?
safeMapGet = function(maxDepth, m, k, default=null, onExceeded=null, xch=null)
	if xch == null then xch = {}
	if not @maxDepth isa number then abort "maxDepth should be a number, got `" + @maxDepth + "`"
	if not @m isa map then abort "`m` should be a map, got `" + @m + "`"
	for _ in range(maxDepth)
		base = null
		for kv in m
			if @kv.key == @k then
				xch.owner = m
				return @kv.value
			end if
			if @kv.key == "__isa" then base = @kv.value
		end for
		if @base == null then return default
		if not @base isa map then
			xch.strangeIsa = @base
			return default
		end if
		m = @base
	end for
	return onExceeded
end function


// safeMapHas: ?
safeMapHas = function(maxDepth, m, k)
	v = safeMapGet(@maxDepth, @m, @k, _noVal, _noVal)
	return not refEquals(@v, _noVal)
end function


// safeIsa: ?
safeIsa = function(maxDepth, m, type, onExceeded=false)
	if not @maxDepth isa number then abort "maxDepth should be a number, got `" + @maxDepth + "`"
	if @m == null then return type == null
	if refEquals(type, map) then return m isa map
	for t in [number, string, list, funcRef]
		if refEquals(t, type) then
			if @m isa map then
				return false
			else
				return @m isa t
			end if
		end if
	end for
	if not @m isa map then return false
	for _ in range(maxDepth)
		base = null
		for kv in m
			if @kv.key == "__isa" then
				base = @kv.value
				break
			end if
		end for
		if base == null then return false
		if refEquals(base, type) then return true
		m = base
	end for
	return onExceeded
end function


// iStr: Saved `str` intrinsic.
iStr = @str


// str: Converts `x` to a string.
// The difference between this and the intrinsic `str` is that we call `._str` callback in maps.
// (Probably overengineered a bit.)
str = function(x, depth=3, seen=null)
	if seen == null then seen = []
	if seen then
		isTopLevel = false
	else
		isTopLevel = true
	end if
	if refIndexOf(seen, @x) != null then return "…"
	if not isTopLevel and @x == null then
		return "null"
	else if @x isa map then
		seen.push @x
		inited = safeMapGet(depth, x, "_inited")
		if inited != false then
			if safeMapHas(depth + 20, x, "_str") then return iStr(x._str(depth - 1, seen))
		end if
		if not inited and hasIndex(x, "_name") then return iStr(x._name)
		name = safeMapGet(depth + 20, x, "_name", "", "")
		if len(x) == 0 and not inited then return name + "{}"
		if depth == 0 then return name + "{ … " + len(x) + " … }"
		elems = []
		for key in indexes(x)
			elems.push str(@key, depth - 1, seen) + ": " + str(x[@key], depth - 1, seen)
		end for
		return name + "{" + elems.join(", ") + "}"
	else if @x isa list then
		seen.push @x
		if len(x) == 0 then return "[]"
		if depth == 0 then return "[ … " + len(x) + " … ]"
		listParts = []
		for elem in x
			listParts.push str(@elem, depth - 1, seen)
		end for
		return "[" + listParts.join(", ") + "]"
	else if not isTopLevel and @x isa string then
		return """" + @x.replace("""", """""") + """"
	end if
	return iStr(@x)
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


// setMissing: ?
setMissing = function(m, k, v)
	if not hasIndex(m, @k) then m[@k] = @v
	return m[@k]
end function


// isInstance: ?
isInstance = function(x, X)
	if not x isa X then return false
	if refEquals(x.get("_inited", _noVal), _noVal) then return true
	return x._inited
end function


// isTruthy: ?
isTruthy = function(x)
	if safeIsa(20, @x, funcRef) then return true
	if safeIsa(20, @x, number) then return x != 0
	return not (not @x)
end function


// isFuzzyNumber: ?
isFuzzyNumber = function(x)
	return safeIsa(20, @x, number) and 0 <= x <= 1
end function


// listInsertFillNulls: ?
listInsertFillNulls = function(lst, index, value)
	if index > lst.len then
		for i in range(lst.len + 1, index, 1)
			lst.push null
		end for
	end if
	return lst.insert(index, @value)
end function


// _genClauses: ?
_genClauses = function(stmtTpl, argTpl, nArgs)
	clauseTpl = char(9) + "else if nArgs == {i} then" + _NL + char(9) + char(9) + stmtTpl
	clauses = []
	for i in range(1, nArgs)
		argParts = []
		for j in range(0, i - 1)
			argParts.push argTpl.fill({"j": j})
		end for
		args = argParts.join(", ")
		clauses.push clauseTpl.fill(locals)
	end for
	return clauses.join(_NL)
end function


// callFunction: ?
callFunction = function(callable, args=null)
	if args == null then args = []
	nArgs = args.len
	if nArgs > 33 then abort "Unable to pass `" + nArgs + "` args to a call"
	if nArgs == 0 then
		return callable
	
	// generated by _genClauses("return callable({args})", "args[{j}]", 33)
	
	else if nArgs == 1 then
		return callable(args[0])
	else if nArgs == 2 then
		return callable(args[0], args[1])
	else if nArgs == 3 then
		return callable(args[0], args[1], args[2])
	else if nArgs == 4 then
		return callable(args[0], args[1], args[2], args[3])
	else if nArgs == 5 then
		return callable(args[0], args[1], args[2], args[3], args[4])
	else if nArgs == 6 then
		return callable(args[0], args[1], args[2], args[3], args[4], args[5])
	else if nArgs == 7 then
		return callable(args[0], args[1], args[2], args[3], args[4], args[5], args[6])
	else if nArgs == 8 then
		return callable(args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7])
	else if nArgs == 9 then
		return callable(args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7], args[8])
	else if nArgs == 10 then
		return callable(args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7], args[8], args[9])
	else if nArgs == 11 then
		return callable(args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7], args[8], args[9], args[10])
	else if nArgs == 12 then
		return callable(args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7], args[8], args[9], args[10], args[11])
	else if nArgs == 13 then
		return callable(args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7], args[8], args[9], args[10], args[11], args[12])
	else if nArgs == 14 then
		return callable(args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7], args[8], args[9], args[10], args[11], args[12], args[13])
	else if nArgs == 15 then
		return callable(args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7], args[8], args[9], args[10], args[11], args[12], args[13], args[14])
	else if nArgs == 16 then
		return callable(args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7], args[8], args[9], args[10], args[11], args[12], args[13], args[14], args[15])
	else if nArgs == 17 then
		return callable(args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7], args[8], args[9], args[10], args[11], args[12], args[13], args[14], args[15], args[16])
	else if nArgs == 18 then
		return callable(args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7], args[8], args[9], args[10], args[11], args[12], args[13], args[14], args[15], args[16], args[17])
	else if nArgs == 19 then
		return callable(args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7], args[8], args[9], args[10], args[11], args[12], args[13], args[14], args[15], args[16], args[17], args[18])
	else if nArgs == 20 then
		return callable(args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7], args[8], args[9], args[10], args[11], args[12], args[13], args[14], args[15], args[16], args[17], args[18], args[19])
	else if nArgs == 21 then
		return callable(args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7], args[8], args[9], args[10], args[11], args[12], args[13], args[14], args[15], args[16], args[17], args[18], args[19], args[20])
	else if nArgs == 22 then
		return callable(args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7], args[8], args[9], args[10], args[11], args[12], args[13], args[14], args[15], args[16], args[17], args[18], args[19], args[20], args[21])
	else if nArgs == 23 then
		return callable(args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7], args[8], args[9], args[10], args[11], args[12], args[13], args[14], args[15], args[16], args[17], args[18], args[19], args[20], args[21], args[22])
	else if nArgs == 24 then
		return callable(args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7], args[8], args[9], args[10], args[11], args[12], args[13], args[14], args[15], args[16], args[17], args[18], args[19], args[20], args[21], args[22], args[23])
	else if nArgs == 25 then
		return callable(args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7], args[8], args[9], args[10], args[11], args[12], args[13], args[14], args[15], args[16], args[17], args[18], args[19], args[20], args[21], args[22], args[23], args[24])
	else if nArgs == 26 then
		return callable(args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7], args[8], args[9], args[10], args[11], args[12], args[13], args[14], args[15], args[16], args[17], args[18], args[19], args[20], args[21], args[22], args[23], args[24], args[25])
	else if nArgs == 27 then
		return callable(args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7], args[8], args[9], args[10], args[11], args[12], args[13], args[14], args[15], args[16], args[17], args[18], args[19], args[20], args[21], args[22], args[23], args[24], args[25], args[26])
	else if nArgs == 28 then
		return callable(args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7], args[8], args[9], args[10], args[11], args[12], args[13], args[14], args[15], args[16], args[17], args[18], args[19], args[20], args[21], args[22], args[23], args[24], args[25], args[26], args[27])
	else if nArgs == 29 then
		return callable(args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7], args[8], args[9], args[10], args[11], args[12], args[13], args[14], args[15], args[16], args[17], args[18], args[19], args[20], args[21], args[22], args[23], args[24], args[25], args[26], args[27], args[28])
	else if nArgs == 30 then
		return callable(args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7], args[8], args[9], args[10], args[11], args[12], args[13], args[14], args[15], args[16], args[17], args[18], args[19], args[20], args[21], args[22], args[23], args[24], args[25], args[26], args[27], args[28], args[29])
	else if nArgs == 31 then
		return callable(args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7], args[8], args[9], args[10], args[11], args[12], args[13], args[14], args[15], args[16], args[17], args[18], args[19], args[20], args[21], args[22], args[23], args[24], args[25], args[26], args[27], args[28], args[29], args[30])
	else if nArgs == 32 then
		return callable(args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7], args[8], args[9], args[10], args[11], args[12], args[13], args[14], args[15], args[16], args[17], args[18], args[19], args[20], args[21], args[22], args[23], args[24], args[25], args[26], args[27], args[28], args[29], args[30], args[31])
	else if nArgs == 33 then
		return callable(args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7], args[8], args[9], args[10], args[11], args[12], args[13], args[14], args[15], args[16], args[17], args[18], args[19], args[20], args[21], args[22], args[23], args[24], args[25], args[26], args[27], args[28], args[29], args[30], args[31], args[32])
		
	end if
end function


callCthulhuMethod = function(object, args)
	if args == null then args = []
	nArgs = args.len
	if nArgs > 33 then abort "Unable to pass `" + nArgs + "` args to a cthulhu method"
	if nArgs == 0 then
		return (@object).Ph_nglui_mglw_nafh_Cthulhu_R_lyeh_wgah_nagl_fhtagn
	
	// generated by _genClauses("return (@object).Ph_nglui_mglw_nafh_Cthulhu_R_lyeh_wgah_nagl_fhtagn({args})", "args[{j}]", 33)
	
	else if nArgs == 1 then
		return (@object).Ph_nglui_mglw_nafh_Cthulhu_R_lyeh_wgah_nagl_fhtagn(args[0])
	else if nArgs == 2 then
		return (@object).Ph_nglui_mglw_nafh_Cthulhu_R_lyeh_wgah_nagl_fhtagn(args[0], args[1])
	else if nArgs == 3 then
		return (@object).Ph_nglui_mglw_nafh_Cthulhu_R_lyeh_wgah_nagl_fhtagn(args[0], args[1], args[2])
	else if nArgs == 4 then
		return (@object).Ph_nglui_mglw_nafh_Cthulhu_R_lyeh_wgah_nagl_fhtagn(args[0], args[1], args[2], args[3])
	else if nArgs == 5 then
		return (@object).Ph_nglui_mglw_nafh_Cthulhu_R_lyeh_wgah_nagl_fhtagn(args[0], args[1], args[2], args[3], args[4])
	else if nArgs == 6 then
		return (@object).Ph_nglui_mglw_nafh_Cthulhu_R_lyeh_wgah_nagl_fhtagn(args[0], args[1], args[2], args[3], args[4], args[5])
	else if nArgs == 7 then
		return (@object).Ph_nglui_mglw_nafh_Cthulhu_R_lyeh_wgah_nagl_fhtagn(args[0], args[1], args[2], args[3], args[4], args[5], args[6])
	else if nArgs == 8 then
		return (@object).Ph_nglui_mglw_nafh_Cthulhu_R_lyeh_wgah_nagl_fhtagn(args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7])
	else if nArgs == 9 then
		return (@object).Ph_nglui_mglw_nafh_Cthulhu_R_lyeh_wgah_nagl_fhtagn(args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7], args[8])
	else if nArgs == 10 then
		return (@object).Ph_nglui_mglw_nafh_Cthulhu_R_lyeh_wgah_nagl_fhtagn(args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7], args[8], args[9])
	else if nArgs == 11 then
		return (@object).Ph_nglui_mglw_nafh_Cthulhu_R_lyeh_wgah_nagl_fhtagn(args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7], args[8], args[9], args[10])
	else if nArgs == 12 then
		return (@object).Ph_nglui_mglw_nafh_Cthulhu_R_lyeh_wgah_nagl_fhtagn(args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7], args[8], args[9], args[10], args[11])
	else if nArgs == 13 then
		return (@object).Ph_nglui_mglw_nafh_Cthulhu_R_lyeh_wgah_nagl_fhtagn(args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7], args[8], args[9], args[10], args[11], args[12])
	else if nArgs == 14 then
		return (@object).Ph_nglui_mglw_nafh_Cthulhu_R_lyeh_wgah_nagl_fhtagn(args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7], args[8], args[9], args[10], args[11], args[12], args[13])
	else if nArgs == 15 then
		return (@object).Ph_nglui_mglw_nafh_Cthulhu_R_lyeh_wgah_nagl_fhtagn(args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7], args[8], args[9], args[10], args[11], args[12], args[13], args[14])
	else if nArgs == 16 then
		return (@object).Ph_nglui_mglw_nafh_Cthulhu_R_lyeh_wgah_nagl_fhtagn(args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7], args[8], args[9], args[10], args[11], args[12], args[13], args[14], args[15])
	else if nArgs == 17 then
		return (@object).Ph_nglui_mglw_nafh_Cthulhu_R_lyeh_wgah_nagl_fhtagn(args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7], args[8], args[9], args[10], args[11], args[12], args[13], args[14], args[15], args[16])
	else if nArgs == 18 then
		return (@object).Ph_nglui_mglw_nafh_Cthulhu_R_lyeh_wgah_nagl_fhtagn(args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7], args[8], args[9], args[10], args[11], args[12], args[13], args[14], args[15], args[16], args[17])
	else if nArgs == 19 then
		return (@object).Ph_nglui_mglw_nafh_Cthulhu_R_lyeh_wgah_nagl_fhtagn(args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7], args[8], args[9], args[10], args[11], args[12], args[13], args[14], args[15], args[16], args[17], args[18])
	else if nArgs == 20 then
		return (@object).Ph_nglui_mglw_nafh_Cthulhu_R_lyeh_wgah_nagl_fhtagn(args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7], args[8], args[9], args[10], args[11], args[12], args[13], args[14], args[15], args[16], args[17], args[18], args[19])
	else if nArgs == 21 then
		return (@object).Ph_nglui_mglw_nafh_Cthulhu_R_lyeh_wgah_nagl_fhtagn(args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7], args[8], args[9], args[10], args[11], args[12], args[13], args[14], args[15], args[16], args[17], args[18], args[19], args[20])
	else if nArgs == 22 then
		return (@object).Ph_nglui_mglw_nafh_Cthulhu_R_lyeh_wgah_nagl_fhtagn(args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7], args[8], args[9], args[10], args[11], args[12], args[13], args[14], args[15], args[16], args[17], args[18], args[19], args[20], args[21])
	else if nArgs == 23 then
		return (@object).Ph_nglui_mglw_nafh_Cthulhu_R_lyeh_wgah_nagl_fhtagn(args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7], args[8], args[9], args[10], args[11], args[12], args[13], args[14], args[15], args[16], args[17], args[18], args[19], args[20], args[21], args[22])
	else if nArgs == 24 then
		return (@object).Ph_nglui_mglw_nafh_Cthulhu_R_lyeh_wgah_nagl_fhtagn(args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7], args[8], args[9], args[10], args[11], args[12], args[13], args[14], args[15], args[16], args[17], args[18], args[19], args[20], args[21], args[22], args[23])
	else if nArgs == 25 then
		return (@object).Ph_nglui_mglw_nafh_Cthulhu_R_lyeh_wgah_nagl_fhtagn(args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7], args[8], args[9], args[10], args[11], args[12], args[13], args[14], args[15], args[16], args[17], args[18], args[19], args[20], args[21], args[22], args[23], args[24])
	else if nArgs == 26 then
		return (@object).Ph_nglui_mglw_nafh_Cthulhu_R_lyeh_wgah_nagl_fhtagn(args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7], args[8], args[9], args[10], args[11], args[12], args[13], args[14], args[15], args[16], args[17], args[18], args[19], args[20], args[21], args[22], args[23], args[24], args[25])
	else if nArgs == 27 then
		return (@object).Ph_nglui_mglw_nafh_Cthulhu_R_lyeh_wgah_nagl_fhtagn(args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7], args[8], args[9], args[10], args[11], args[12], args[13], args[14], args[15], args[16], args[17], args[18], args[19], args[20], args[21], args[22], args[23], args[24], args[25], args[26])
	else if nArgs == 28 then
		return (@object).Ph_nglui_mglw_nafh_Cthulhu_R_lyeh_wgah_nagl_fhtagn(args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7], args[8], args[9], args[10], args[11], args[12], args[13], args[14], args[15], args[16], args[17], args[18], args[19], args[20], args[21], args[22], args[23], args[24], args[25], args[26], args[27])
	else if nArgs == 29 then
		return (@object).Ph_nglui_mglw_nafh_Cthulhu_R_lyeh_wgah_nagl_fhtagn(args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7], args[8], args[9], args[10], args[11], args[12], args[13], args[14], args[15], args[16], args[17], args[18], args[19], args[20], args[21], args[22], args[23], args[24], args[25], args[26], args[27], args[28])
	else if nArgs == 30 then
		return (@object).Ph_nglui_mglw_nafh_Cthulhu_R_lyeh_wgah_nagl_fhtagn(args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7], args[8], args[9], args[10], args[11], args[12], args[13], args[14], args[15], args[16], args[17], args[18], args[19], args[20], args[21], args[22], args[23], args[24], args[25], args[26], args[27], args[28], args[29])
	else if nArgs == 31 then
		return (@object).Ph_nglui_mglw_nafh_Cthulhu_R_lyeh_wgah_nagl_fhtagn(args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7], args[8], args[9], args[10], args[11], args[12], args[13], args[14], args[15], args[16], args[17], args[18], args[19], args[20], args[21], args[22], args[23], args[24], args[25], args[26], args[27], args[28], args[29], args[30])
	else if nArgs == 32 then
		return (@object).Ph_nglui_mglw_nafh_Cthulhu_R_lyeh_wgah_nagl_fhtagn(args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7], args[8], args[9], args[10], args[11], args[12], args[13], args[14], args[15], args[16], args[17], args[18], args[19], args[20], args[21], args[22], args[23], args[24], args[25], args[26], args[27], args[28], args[29], args[30], args[31])
	else if nArgs == 33 then
		return (@object).Ph_nglui_mglw_nafh_Cthulhu_R_lyeh_wgah_nagl_fhtagn(args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7], args[8], args[9], args[10], args[11], args[12], args[13], args[14], args[15], args[16], args[17], args[18], args[19], args[20], args[21], args[22], args[23], args[24], args[25], args[26], args[27], args[28], args[29], args[30], args[31], args[32])
		
	end if
end function


// installCthulhuMethod: ?
installCthulhuMethod = function(object, callable)
	for type in [number, string, list, map, funcRef]
		if safeIsa(0, @object, type) then
			type.Ph_nglui_mglw_nafh_Cthulhu_R_lyeh_wgah_nagl_fhtagn = @callable
			return type
		end if
	end for
	abort "Unable to install cthulhu method"
end function


// nArgsFunction: ?
nArgsFunction = function(func, nArgs)
	
	if nArgs < 0 or nArgs > 33 then abort "Unable to generate a function with `" + nArgs + "` args"
	
	noVal = _noVal
	self = _noVal
	
	if nArgs == 0 then
		_f = function
			if refEquals(self, noVal) then self = null
			return func(self, [])
		end function
	
	// generated by _genClauses("_f = function({args})" + char(10) + char(9) + char(9) + char(9) + "if refEquals(self, noVal) then self = null" + char(10) + char(9) + char(9) + char(9) + "return func(self, [{args}])" + char(10) + char(9) + char(9) + "end function", "a{j}", 33)
	
	else if nArgs == 1 then
		_f = function(a0)
			if refEquals(self, noVal) then self = null
			return func(self, [a0])
		end function
	else if nArgs == 2 then
		_f = function(a0, a1)
			if refEquals(self, noVal) then self = null
			return func(self, [a0, a1])
		end function
	else if nArgs == 3 then
		_f = function(a0, a1, a2)
			if refEquals(self, noVal) then self = null
			return func(self, [a0, a1, a2])
		end function
	else if nArgs == 4 then
		_f = function(a0, a1, a2, a3)
			if refEquals(self, noVal) then self = null
			return func(self, [a0, a1, a2, a3])
		end function
	else if nArgs == 5 then
		_f = function(a0, a1, a2, a3, a4)
			if refEquals(self, noVal) then self = null
			return func(self, [a0, a1, a2, a3, a4])
		end function
	else if nArgs == 6 then
		_f = function(a0, a1, a2, a3, a4, a5)
			if refEquals(self, noVal) then self = null
			return func(self, [a0, a1, a2, a3, a4, a5])
		end function
	else if nArgs == 7 then
		_f = function(a0, a1, a2, a3, a4, a5, a6)
			if refEquals(self, noVal) then self = null
			return func(self, [a0, a1, a2, a3, a4, a5, a6])
		end function
	else if nArgs == 8 then
		_f = function(a0, a1, a2, a3, a4, a5, a6, a7)
			if refEquals(self, noVal) then self = null
			return func(self, [a0, a1, a2, a3, a4, a5, a6, a7])
		end function
	else if nArgs == 9 then
		_f = function(a0, a1, a2, a3, a4, a5, a6, a7, a8)
			if refEquals(self, noVal) then self = null
			return func(self, [a0, a1, a2, a3, a4, a5, a6, a7, a8])
		end function
	else if nArgs == 10 then
		_f = function(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9)
			if refEquals(self, noVal) then self = null
			return func(self, [a0, a1, a2, a3, a4, a5, a6, a7, a8, a9])
		end function
	else if nArgs == 11 then
		_f = function(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10)
			if refEquals(self, noVal) then self = null
			return func(self, [a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10])
		end function
	else if nArgs == 12 then
		_f = function(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11)
			if refEquals(self, noVal) then self = null
			return func(self, [a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11])
		end function
	else if nArgs == 13 then
		_f = function(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12)
			if refEquals(self, noVal) then self = null
			return func(self, [a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12])
		end function
	else if nArgs == 14 then
		_f = function(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13)
			if refEquals(self, noVal) then self = null
			return func(self, [a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13])
		end function
	else if nArgs == 15 then
		_f = function(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14)
			if refEquals(self, noVal) then self = null
			return func(self, [a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14])
		end function
	else if nArgs == 16 then
		_f = function(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15)
			if refEquals(self, noVal) then self = null
			return func(self, [a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15])
		end function
	else if nArgs == 17 then
		_f = function(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16)
			if refEquals(self, noVal) then self = null
			return func(self, [a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16])
		end function
	else if nArgs == 18 then
		_f = function(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17)
			if refEquals(self, noVal) then self = null
			return func(self, [a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17])
		end function
	else if nArgs == 19 then
		_f = function(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18)
			if refEquals(self, noVal) then self = null
			return func(self, [a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18])
		end function
	else if nArgs == 20 then
		_f = function(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19)
			if refEquals(self, noVal) then self = null
			return func(self, [a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19])
		end function
	else if nArgs == 21 then
		_f = function(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20)
			if refEquals(self, noVal) then self = null
			return func(self, [a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20])
		end function
	else if nArgs == 22 then
		_f = function(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20, a21)
			if refEquals(self, noVal) then self = null
			return func(self, [a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20, a21])
		end function
	else if nArgs == 23 then
		_f = function(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20, a21, a22)
			if refEquals(self, noVal) then self = null
			return func(self, [a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20, a21, a22])
		end function
	else if nArgs == 24 then
		_f = function(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20, a21, a22, a23)
			if refEquals(self, noVal) then self = null
			return func(self, [a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20, a21, a22, a23])
		end function
	else if nArgs == 25 then
		_f = function(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20, a21, a22, a23, a24)
			if refEquals(self, noVal) then self = null
			return func(self, [a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20, a21, a22, a23, a24])
		end function
	else if nArgs == 26 then
		_f = function(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20, a21, a22, a23, a24, a25)
			if refEquals(self, noVal) then self = null
			return func(self, [a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20, a21, a22, a23, a24, a25])
		end function
	else if nArgs == 27 then
		_f = function(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20, a21, a22, a23, a24, a25, a26)
			if refEquals(self, noVal) then self = null
			return func(self, [a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20, a21, a22, a23, a24, a25, a26])
		end function
	else if nArgs == 28 then
		_f = function(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20, a21, a22, a23, a24, a25, a26, a27)
			if refEquals(self, noVal) then self = null
			return func(self, [a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20, a21, a22, a23, a24, a25, a26, a27])
		end function
	else if nArgs == 29 then
		_f = function(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20, a21, a22, a23, a24, a25, a26, a27, a28)
			if refEquals(self, noVal) then self = null
			return func(self, [a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20, a21, a22, a23, a24, a25, a26, a27, a28])
		end function
	else if nArgs == 30 then
		_f = function(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20, a21, a22, a23, a24, a25, a26, a27, a28, a29)
			if refEquals(self, noVal) then self = null
			return func(self, [a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20, a21, a22, a23, a24, a25, a26, a27, a28, a29])
		end function
	else if nArgs == 31 then
		_f = function(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20, a21, a22, a23, a24, a25, a26, a27, a28, a29, a30)
			if refEquals(self, noVal) then self = null
			return func(self, [a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20, a21, a22, a23, a24, a25, a26, a27, a28, a29, a30])
		end function
	else if nArgs == 32 then
		_f = function(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20, a21, a22, a23, a24, a25, a26, a27, a28, a29, a30, a31)
			if refEquals(self, noVal) then self = null
			return func(self, [a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20, a21, a22, a23, a24, a25, a26, a27, a28, a29, a30, a31])
		end function
	else if nArgs == 33 then
		_f = function(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20, a21, a22, a23, a24, a25, a26, a27, a28, a29, a30, a31, a32)
			if refEquals(self, noVal) then self = null
			return func(self, [a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20, a21, a22, a23, a24, a25, a26, a27, a28, a29, a30, a31, a32])
		end function
		
	end if
	return @_f
end function


// nArgsSelfFunction: ?
nArgsSelfFunction = function(func, nArgs)
	
	if nArgs < 0 or nArgs > 33 then abort "Unable to generate a function with `" + nArgs + "` args"
	
	if nArgs == 0 then
		_f = function(self) ; return func(self, []) ; end function
	
	// generated by _genClauses("_f = function(self, {args}) ; return func(self, [{args}]) ; end function", "a{j}", 33)
	
	else if nArgs == 1 then
		_f = function(self, a0) ; return func(self, [a0]) ; end function
	else if nArgs == 2 then
		_f = function(self, a0, a1) ; return func(self, [a0, a1]) ; end function
	else if nArgs == 3 then
		_f = function(self, a0, a1, a2) ; return func(self, [a0, a1, a2]) ; end function
	else if nArgs == 4 then
		_f = function(self, a0, a1, a2, a3) ; return func(self, [a0, a1, a2, a3]) ; end function
	else if nArgs == 5 then
		_f = function(self, a0, a1, a2, a3, a4) ; return func(self, [a0, a1, a2, a3, a4]) ; end function
	else if nArgs == 6 then
		_f = function(self, a0, a1, a2, a3, a4, a5) ; return func(self, [a0, a1, a2, a3, a4, a5]) ; end function
	else if nArgs == 7 then
		_f = function(self, a0, a1, a2, a3, a4, a5, a6) ; return func(self, [a0, a1, a2, a3, a4, a5, a6]) ; end function
	else if nArgs == 8 then
		_f = function(self, a0, a1, a2, a3, a4, a5, a6, a7) ; return func(self, [a0, a1, a2, a3, a4, a5, a6, a7]) ; end function
	else if nArgs == 9 then
		_f = function(self, a0, a1, a2, a3, a4, a5, a6, a7, a8) ; return func(self, [a0, a1, a2, a3, a4, a5, a6, a7, a8]) ; end function
	else if nArgs == 10 then
		_f = function(self, a0, a1, a2, a3, a4, a5, a6, a7, a8, a9) ; return func(self, [a0, a1, a2, a3, a4, a5, a6, a7, a8, a9]) ; end function
	else if nArgs == 11 then
		_f = function(self, a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10) ; return func(self, [a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10]) ; end function
	else if nArgs == 12 then
		_f = function(self, a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11) ; return func(self, [a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11]) ; end function
	else if nArgs == 13 then
		_f = function(self, a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12) ; return func(self, [a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12]) ; end function
	else if nArgs == 14 then
		_f = function(self, a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13) ; return func(self, [a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13]) ; end function
	else if nArgs == 15 then
		_f = function(self, a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14) ; return func(self, [a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14]) ; end function
	else if nArgs == 16 then
		_f = function(self, a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15) ; return func(self, [a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15]) ; end function
	else if nArgs == 17 then
		_f = function(self, a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16) ; return func(self, [a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16]) ; end function
	else if nArgs == 18 then
		_f = function(self, a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17) ; return func(self, [a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17]) ; end function
	else if nArgs == 19 then
		_f = function(self, a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18) ; return func(self, [a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18]) ; end function
	else if nArgs == 20 then
		_f = function(self, a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19) ; return func(self, [a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19]) ; end function
	else if nArgs == 21 then
		_f = function(self, a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20) ; return func(self, [a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20]) ; end function
	else if nArgs == 22 then
		_f = function(self, a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20, a21) ; return func(self, [a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20, a21]) ; end function
	else if nArgs == 23 then
		_f = function(self, a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20, a21, a22) ; return func(self, [a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20, a21, a22]) ; end function
	else if nArgs == 24 then
		_f = function(self, a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20, a21, a22, a23) ; return func(self, [a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20, a21, a22, a23]) ; end function
	else if nArgs == 25 then
		_f = function(self, a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20, a21, a22, a23, a24) ; return func(self, [a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20, a21, a22, a23, a24]) ; end function
	else if nArgs == 26 then
		_f = function(self, a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20, a21, a22, a23, a24, a25) ; return func(self, [a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20, a21, a22, a23, a24, a25]) ; end function
	else if nArgs == 27 then
		_f = function(self, a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20, a21, a22, a23, a24, a25, a26) ; return func(self, [a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20, a21, a22, a23, a24, a25, a26]) ; end function
	else if nArgs == 28 then
		_f = function(self, a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20, a21, a22, a23, a24, a25, a26, a27) ; return func(self, [a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20, a21, a22, a23, a24, a25, a26, a27]) ; end function
	else if nArgs == 29 then
		_f = function(self, a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20, a21, a22, a23, a24, a25, a26, a27, a28) ; return func(self, [a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20, a21, a22, a23, a24, a25, a26, a27, a28]) ; end function
	else if nArgs == 30 then
		_f = function(self, a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20, a21, a22, a23, a24, a25, a26, a27, a28, a29) ; return func(self, [a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20, a21, a22, a23, a24, a25, a26, a27, a28, a29]) ; end function
	else if nArgs == 31 then
		_f = function(self, a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20, a21, a22, a23, a24, a25, a26, a27, a28, a29, a30) ; return func(self, [a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20, a21, a22, a23, a24, a25, a26, a27, a28, a29, a30]) ; end function
	else if nArgs == 32 then
		_f = function(self, a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20, a21, a22, a23, a24, a25, a26, a27, a28, a29, a30, a31) ; return func(self, [a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20, a21, a22, a23, a24, a25, a26, a27, a28, a29, a30, a31]) ; end function
	else if nArgs == 33 then
		_f = function(self, a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20, a21, a22, a23, a24, a25, a26, a27, a28, a29, a30, a31, a32) ; return func(self, [a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20, a21, a22, a23, a24, a25, a26, a27, a28, a29, a30, a31, a32]) ; end function
		
	end if
	return @_f
end function


// updateInPlace: ?
updateInPlace = function(m1, m2)
	for kv in m2
		m1[@kv.key] = @kv.value
	end for
end function










//  _|_|    _|  _|_|  _|  _|_|    _|_|    _|  _|_|    _|_|_|  
//_|_|_|_|  _|_|      _|_|      _|    _|  _|_|      _|_|      
//_|        _|        _|        _|    _|  _|            _|_|  
//  _|_|_|  _|        _|          _|_|    _|        _|_|_|    
                                                            

// Error: ?
Error = {}
Error._name = "ms.Error"
Error._inited = false
Error.messageTemplate = "ERROR [line {line}]"
Error.line = null


Error.init = function
	self._inited = true
end function


Error.message = function
	return self.messageTemplate.fill(self)
end function


// ParseError: ?
ParseError = new Error
ParseError._name = "ms.ParseError"
ParseError.messageTemplate = "Parse error: {submessages}"
ParseError.submessages = null


// Continuation: ?
Continuation = new ParseError
Continuation._name = "ms.Continuation"


// ContLine: ?
ContLine = new Continuation
ContLine._name = "ms.ContLine"
ContLine.messageTemplate = "Continuation Error: Need more input to complete an expression or literal [line {line}]"


// ContString: ?
ContString = new Continuation
ContString._name = "ms.ContString"
ContString.messageTemplate = "Continuation Error: Need more input to complete a string literal [line {line}]"


// ContIf: ?
ContIf = new Continuation
ContIf._name = "ms.ContIf"
ContIf.messageTemplate = "Continuation Error: Need more input to complete an if-statement [line {line}]"


// ContFor: ?
ContFor = new Continuation
ContFor._name = "ms.ContFor"
ContFor.messageTemplate = "Continuation Error: Need more input to complete a for-statement [line {line}]"


// ContWhile: ?
ContWhile = new Continuation
ContWhile._name = "ms.ContWhile"
ContWhile.messageTemplate = "Continuation Error: Need more input to complete a while-statement [line {line}]"


// ContFunction: ?
ContFunction = new Continuation
ContFunction._name = "ms.ContFunction"
ContFunction.messageTemplate = "Continuation Error: Need more input to complete a function [line {line}]"


// RuntimeError: ?
RuntimeError = new Error
RuntimeError._name = "ms.RuntimeError"


// UnknownIdentifierError: ?
UnknownIdentifierError = new RuntimeError
UnknownIdentifierError._name = "ms.UnknownIdentifierError"
UnknownIdentifierError.messageTemplate = "Runtime Error: Undefined Identifier: '{name}' is unknown in this context [line {line}]"
UnknownIdentifierError.name = null


// LookupError: ?
LookupError = new RuntimeError
LookupError._name = "ms.LookupError"
LookupError.index = null


// KeyNotFoundError: ?
KeyNotFoundError = new LookupError
KeyNotFoundError._name = "ms.KeyNotFoundError"
KeyNotFoundError.messageTemplate = "Runtime Error: Key Not Found: '{index}' not found in map [line {line}]"


// MethodNotFoundError: ?
MethodNotFoundError = new LookupError
MethodNotFoundError._name = "ms.MethodNotFoundError"
MethodNotFoundError.messageTemplate = "Runtime Error: Can't find and/or call native method '{index}' [line {line}]"


// IndexError: ?
IndexError = new LookupError
IndexError._name = "ms.IndexError"
IndexError.messageTemplate = "Runtime Error: Index Error ({typeName} index {index} out of range) [line {line}]"
IndexError.typeName = null



// UnableToIndexError: ?
UnableToIndexError = new LookupError
UnableToIndexError._name = "ms.UnableToIndexError"
UnableToIndexError.messageTemplate = "Runtime Error: Type Exception: can't index into this type [line {line}]"


// UnableToIndexNullError: ?
UnableToIndexNullError = new UnableToIndexError
UnableToIndexNullError._name = "ms.UnableToIndexNullError"
UnableToIndexNullError.messageTemplate = "Runtime Error: Null Reference Exception: can't index into null [line {line}]"


// NullLookupError: ?
NullLookupError = new LookupError
NullLookupError._name = "ms.NullLookupError"
NullLookupError.messageTemplate = "Runtime Error: Type Error (while attempting to look up {index}) [line {line}]"


// MaxArgsExceededError: ?
MaxArgsExceededError = new RuntimeError
MaxArgsExceededError._name = "ms.MaxArgsExceededError"
MaxArgsExceededError.messageTemplate = "Runtime Error: Unable to call a native function with {nArgs} args [line {line}]"
MaxArgsExceededError.nArgs = null


// TooManyArgsError: ?
TooManyArgsError = new RuntimeError
TooManyArgsError._name = "ms.TooManyArgsError"
TooManyArgsError.messageTemplate = "Runtime Error: Too Many Arguments [line {line}]"
TooManyArgsError.maxAccept = null
TooManyArgsError.got = null


// NotCallableError: ?
NotCallableError = new TooManyArgsError
NotCallableError._name = "ms.NotCallableError"


// NullForExpressionError: ?
NullForExpressionError = new RuntimeError
NullForExpressionError._name = "ms.NullForExpressionError"
NullForExpressionError.messageTemplate = "Runtime Error: Got null as a 'for' expression [line {line}]"


// NonsequenceForError: ?
NonsequenceForError = new RuntimeError
NonsequenceForError._name = "ms.NonsequenceForError"
NonsequenceForError.messageTemplate = "Runtime Error: {objectType} can't be used as a 'for' expression [line {line}]"
NonsequenceForError.objectType = null


// IsaDepthExceededError: ?
IsaDepthExceededError = new RuntimeError
IsaDepthExceededError._name = "ms.IsaDepthExceededError"
IsaDepthExceededError.messageTemplate = "Runtime Error: __isa depth exceeded (perhaps a reference loop?) [line {line}]"


// LocalFromNonlocalWarning: ?
LocalFromNonlocalWarning = new Error
LocalFromNonlocalWarning._name = "ms.LocalFromNonlocalWarning"
LocalFromNonlocalWarning.messageTemplate = "Assignment of unqualified local '{identifier}' based on nonlocal is deprecated [line {line}]"
LocalFromNonlocalWarning.identifier = null


// SmuggleThrow: ?
SmuggleThrow = {}
SmuggleThrow._name = "ms.SmuggleThrow"
SmuggleThrow.message = "<_Smuggle>"
SmuggleThrow.map = null


// BreakThrow: ?
BreakThrow = {}
BreakThrow._name = "ms.BreakThrow"
BreakThrow.message = "<_Break>"


// ContinueThrow: ?
ContinueThrow = {}
ContinueThrow._name = "ms.ContinueThrow"
ContinueThrow.message = "<_Continue>"


// ReturnThrow: ?
ReturnThrow = {}
ReturnThrow._name = "ms.ReturnThrow"
ReturnThrow.message = "<_Return>"
ReturnThrow.object = null










//    _|_|                        _|                                    
//  _|        _|_|      _|_|_|  _|_|_|_|  _|    _|  _|  _|_|    _|_|      _|_|_|  
//_|_|_|_|  _|_|_|_|  _|    _|    _|      _|    _|  _|_|      _|_|_|_|  _|_|      
//  _|      _|        _|    _|    _|      _|    _|  _|        _|            _|_|  
//  _|        _|_|_|    _|_|_|      _|_|    _|_|_|  _|          _|_|_|  _|_|_|    


// v16: Default language features when parsing and evaluating MiniScript 1.6
v16 = {}


// multilineContinuations: ?
v16.multilineContinuations = false


// multilineStrings: ?
v16.multilineStrings = false


// beheadedFunctions: ?
v16.beheadedFunctions = true


// parseShebang: ?
v16.parseShebang = false


// confusedNamespaces: ?
v16.confusedFunctions = true


// raiseNonsequenceFor: ?
v16.raiseNonsequenceFor = false


// introspectIntrinsics: ?
v16.introspectIntrinsics = false


// faithfulAddress: ?
v16.faithfulAddress = true


// ?
v16File = new v16

v16File.multilineContinuations = true

v16File.multilineStrings = true

v16File.parseShebang = true










//_|                        _|                                      _|      _|                                
//    _|_|_|      _|_|_|  _|_|_|_|  _|  _|_|  _|    _|    _|_|_|  _|_|_|_|        _|_|    _|_|_|      _|_|_|  
//_|  _|    _|  _|_|        _|      _|_|      _|    _|  _|          _|      _|  _|    _|  _|    _|  _|_|      
//_|  _|    _|      _|_|    _|      _|        _|    _|  _|          _|      _|  _|    _|  _|    _|      _|_|  
//_|  _|    _|  _|_|_|        _|_|  _|          _|_|_|    _|_|_|      _|_|  _|    _|_|    _|    _|  _|_|_|    


// BaseInstruction: ?
BaseInstruction = {}
BaseInstruction._name = "BaseInstruction"
BaseInstruction.stepInfo = null


// InstDone: ?
InstDone = new BaseInstruction
InstDone._name = "InstDone"
InstDone.result = null


// InstChild: ?
InstChild = new BaseInstruction
InstChild._name = "InstChild"
InstChild.child = null
InstChild.inject = null
InstChild.catch = null


// InstPause: ?
InstPause = new BaseInstruction
InstPause._name = "InstPause"


// InstThrow: ?
InstThrow = new BaseInstruction
InstThrow._name = "InstThrow"
InstThrow.object = null


// InstNext: ?
InstNext = new BaseInstruction
InstNext._name = "InstNext"










//                          _|                      
//_|_|_|      _|_|      _|_|_|    _|_|      _|_|_|  
//_|    _|  _|    _|  _|    _|  _|_|_|_|  _|_|      
//_|    _|  _|    _|  _|    _|  _|            _|_|  
//_|    _|    _|_|      _|_|_|    _|_|_|  _|_|_|    


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
SyntaxNode._callableCandidate = null
SyntaxNode.programName = null
SyntaxNode._stepComments = {}


// init: ?
SyntaxNode.init = function(start, length, subject, programName)
	self._inited = true
	self._subject = subject
	self.programName = programName
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
		v = self.get(name, "")
		if fullName.endsWith(" =") then
			s = str(v, depth - 1, seen)
			
			//
			s = s.replace(char(13) + char(10), "←").replace(char(10), "←").replace(char(13), "←")
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
		self[name] = @value
	else if self._propertyFullNames.indexOf(name + ".") != null then
		setMissing(self, name, []).push @value
	else if self._propertyFullNames.indexOf(name + "..") != null then
		index = value
		value = @value2
		setMissing(self, name, [])
		for _ in range(self[name].len, index, 1)
			self[name].push []
		end for
		self[name][index].push @value
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
	if not existsP then abort "Unable to get property `" + name + "` of " + self._name + " (available properties are " + self.propertyNames + ")"
	v = self.get(name)
	if @v == null then return null
	if index == null then return @v
	if index >= v.len then return null
	return v[index]
end function


// Expression: ?
Expression = new SyntaxNode
Expression._name = "ms.Expression"
Expression.parenthesized = null
Expression.identSet = null


Expression.init = function(start, length, subject, programName)
	super.init start, length, subject, programName
	self.parenthesized = 0
	self.identSet = {}
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
LitNull.steps = {}
LitNull.steps._INIT = {}


LitNull.steps._INIT.onClean = function(node, state, stepInfo)
	inst = new InstDone
	inst.result = null
	return inst
end function


// LitTrue: ?
LitTrue = new Literal
LitTrue._name = "LitTrue"
LitTrue.steps = {}
LitTrue.steps._INIT = {}


LitTrue.steps._INIT.onClean = function(node, state, stepInfo)
	inst = new InstDone
	inst.result = true
	return inst
end function


// LitFalse: ?
LitFalse = new Literal
LitFalse._name = "LitFalse"
LitFalse.steps = {}
LitFalse.steps._INIT = {}


LitFalse.steps._INIT.onClean = function(node, state, stepInfo)
	inst = new InstDone
	inst.result = false
	return inst
end function


// LitNumeral: ?
LitNumeral = new Literal
LitNumeral._name = "LitNumeral"
LitNumeral._propertyFullNames = ["int =", "fract =", "eSign =", "exp =", "val ="]
LitNumeral.steps = {}
LitNumeral.steps._INIT = {}


LitNumeral.steps._INIT.onClean = function(node, state, stepInfo)
	inst = new InstDone
	inst.result = node.val
	return inst
end function


// LitString: ?
LitString = new Literal
LitString._name = "LitString"
LitString._propertyFullNames = ["text ="]
LitString.steps = {}
LitString.steps._INIT = {}


LitString.steps._INIT.onClean = function(node, state, stepInfo)
	inst = new InstDone
	inst.result = node.text
	return inst
end function


// LitList: ?
LitList = new Literal
LitList._name = "LitList"
LitList._propertyFullNames = ["elements."]
LitList._stepComments = {}
LitList._stepComments.listElement = "list element {index} of {nElems}"


_s = {}


_s._INIT = {}


_s._INIT.onClean = function(node, state, stepInfo)
	elementNodes = node.getProperty("elements")
	if elementNodes == null then elementNodes = []
	state.elementNodes = elementNodes
	state.elements = []
	
	stepInfo = {}
	stepInfo.name = "listElement"
	stepInfo.index = 0
	stepInfo.nElems = state.elementNodes.len
	
	inst = new InstNext
	inst.stepInfo = stepInfo
	return inst
end function


_s.listElement = {}


_s.listElement.onClean = function(node, state, stepInfo)
	if stepInfo.index >= state.elementNodes.len then
		inst = new InstDone
		inst.result = state.elements
		return inst
	end if
	
	inst = new InstChild
	inst.child = state.elementNodes[stepInfo.index]
	inst.inject = {"context": state.context}
	return inst
end function


_s.listElement.onResult = function(node, state, stepInfo, result)
	state.elements.push @result
	
	stepInfo += {"index": stepInfo.index + 1}
	
	inst = new InstNext
	inst.stepInfo = stepInfo
	return inst
end function


LitList.steps = _s


// LitMap: ?
LitMap = new Literal
LitMap._name = "LitMap"
LitMap._propertyFullNames = ["keys.", "values."]
LitMap._stepComments = {}
LitMap._stepComments.mapKey = "map key {index} of {nPairs}"
LitMap._stepComments.mapValue = "map value {index} of {nPairs}"


_s = {}


_s._INIT = {}


_s._INIT.onClean = function(node, state, stepInfo)
	keyNodes = node.getProperty("keys")
	if keyNodes == null then keyNodes = []
	valueNodes = node.getProperty("values")
	if valueNodes == null then valueNodes = []
	if keyNodes.len != valueNodes.len then abort "Corrupted map: keyNodes.len=" + keyNodes.len + ", valueNodes.len=" + valueNodes.len
	state.keyNodes = keyNodes
	state.valueNodes = valueNodes
	state.keys = []
	state.values = []
	
	stepInfo = {}
	stepInfo.name = "mapKey"
	stepInfo.index = 0
	stepInfo.nPairs = state.keyNodes.len
	
	inst = new InstNext
	inst.stepInfo = stepInfo
	return inst
end function


_s.mapKey = {}


_s.mapKey.onClean = function(node, state, stepInfo)
	if stepInfo.index >= state.keyNodes.len then
		r = {}
		for i in state.keys.indexes
			r[state.keys[i]] = state.values[i]
		end for
		inst = new InstDone
		inst.result = r
		return inst
	end if
	
	inst = new InstChild
	inst.child = state.keyNodes[stepInfo.index]
	inst.inject = {"context": state.context}
	return inst
end function


_s.mapKey.onResult = function(node, state, stepInfo, result)
	state.keys.push @result
	
	stepInfo += {"name": "mapValue"}
	
	inst = new InstNext
	inst.stepInfo = stepInfo
	return inst
end function


_s.mapValue = {}


_s.mapValue.onClean = function(node, state, stepInfo)
	inst = new InstChild
	inst.child = state.valueNodes[stepInfo.index]
	inst.inject = {"context": state.context}
	return inst
end function


_s.mapValue.onResult = function(node, state, stepInfo, result)
	state.values.push @result
	
	stepInfo += {"name": "mapKey", "index": stepInfo.index + 1}
	
	inst = new InstNext
	inst.stepInfo = stepInfo
	return inst
end function


LitMap.steps = _s


// LitFunction: ?
LitFunction = new Literal
LitFunction._name = "LitFunction"
LitFunction._propertyFullNames = ["args.", "defaults.", "statements."]
LitFunction.isConfusedFunc = true


_s = {}


_s._INIT = {}


_s._INIT.onClean = function(node, state, stepInfo)
	argNodes = node.getProperty("args")
	if argNodes == null then argNodes = []
	defaultNodes = node.getProperty("defaults")
	if defaultNodes == null then defaultNodes = []
	if argNodes.len != defaultNodes.len then abort "Corrupted funtion literal: argNodes.len=" + argNodes.len + ", defaultNodes.len=" + defaultNodes.len
	
	funcContext = state.context.buildFuncContext(node.isConfusedFunc)
	invokable = new ParsedFunction
	invokable.init node, funcContext
	
	inst = new InstDone
	inst.result = invokable
	return inst
end function


LitFunction.steps = _s


// Identifier: ?
Identifier = new Expression
Identifier._name = "Identifier"
Identifier._propertyFullNames = ["name ="]
Identifier._stepComments = {}
Identifier._stepComments.invokeIdentifier = "call parsed function"


_s = {}


_s._INIT = {}


_s._INIT.onClean = function(node, state, stepInfo)
	if state.hasIndex("_smuggleMap") then
		state._smuggleMap.key = node.name
		
		if state._smuggleMap.get("noValue") then
			throw = new SmuggleThrow
			throw.map = state._smuggleMap
			
			inst = new InstThrow
			inst.object = throw
			return inst
		end if
	end if
	
	if node.name == "locals" then
		value = state.context.namespaces.locals
	else if node.name == "outer" then
		value = state.context.namespaces.outer
	else if node.name == "globals" then
		value = state.context.namespaces.globals
	else if node.name == "intrinsics" and state.context.features.introspectIntrinsics then
		value = state.context.namespaces.intrinsics
	else
		for namespace in ["locals", "outer", "globals", "intrinsics"]
			value = safeMapGet(state.context.params.maxIsaDepth, state.context.namespaces[namespace], node.name, _noVal, _noVal)
			if not refEquals(@value, _noVal) then break
		end for
	end if
	
	if refEquals(@value, _noVal) then
		error = new UnknownIdentifierError
		error.init
		error.line = lineColumn(node._subject, node.start).line
		error.name = node.name
		
		inst = new InstThrow
		inst.object = error
		return inst
	end if
	
	if state.get("doNotCall") then
		inst = new InstDone
		inst.result = @value
		return inst
	end if
	
	if not safeIsa(state.context.params.maxIsaDepth, @value, ParsedFunction) then
		inst = new InstDone
		inst.result = value  // no @!
		return inst
	end if
	
	state.value = @value
	
	stepInfo = {}
	stepInfo.name = "invokeIdentifier"
	
	inst = new InstNext
	inst.stepInfo = stepInfo
	return inst
end function


_s.invokeIdentifier = {}


_s.invokeIdentifier.onClean = function(node, state, stepInfo)
	inst = new InstChild
	inst.child = @state.value
	inst.inject = {"context": state.context, "callNode": node}
	return inst
end function


_s.invokeIdentifier.onResult = function(node, state, stepInfo, result)
	inst = new InstDone
	inst.result = @result
	return inst
end function


Identifier.steps = _s


// Operation: ?
Operation = new Expression
Operation._name = "ms.Operation"
Operation._propertyFullNames = ["operands."]


// BinaryOperation: ?
BinaryOperation = new Operation
BinaryOperation._name = "BinaryOperation"
BinaryOperation._stepComments = {}
BinaryOperation._stepComments.binaryLeft = "({operator}) left operand"
BinaryOperation._stepComments.binaryRight = "({operator}) right operand"
BinaryOperation._stepComments.binaryComplete = "result of ({operator})"


_s = {}


_s._INIT = {}


_s._INIT.onClean = function(node, state, stepInfo)
	operands = node.getProperty("operands")
	opStr = binaryOperators.indexOf(node.__isa)
	if operands.len != 2 then abort "Corrupted binary operator (" + opStr + "): operands.len=" + operands.len
	state.opStr = opStr
	state.left = null
	state.right = null
	
	stepInfo = {}
	stepInfo.name = "binaryLeft"
	stepInfo.operator = state.opStr
	
	inst = new InstNext
	inst.stepInfo = stepInfo
	return inst
end function


_s.binaryLeft = {}


_s.binaryLeft.onClean = function(node, state, stepInfo)
	inst = new InstChild
	inst.child = node.getProperty("operands")[0]
	inst.inject = {"context": state.context}
	return inst
end function


_s.binaryLeft.onResult = function(node, state, stepInfo, result)
	state.left = @result
	
	if node.get("shortCircuitP") != null and node.shortCircuitP(@state.left) then
		inst = new InstDone
		inst.result = @node.shortCircuitResult
		return inst
	end if
	
	stepInfo += {"name": "binaryRight"}
	
	inst = new InstNext
	inst.stepInfo = stepInfo
	return inst
end function


_s.binaryRight = {}


_s.binaryRight.onClean = function(node, state, stepInfo)
	inst = new InstChild
	inst.child = node.getProperty("operands")[1]
	inst.inject = {"context": state.context}
	return inst
end function


_s.binaryRight.onResult = function(node, state, stepInfo, result)
	state.right = @result
	
	stepInfo += {"name": "binaryComplete"}
	
	inst = new InstNext
	inst.stepInfo = stepInfo
	return inst
end function


_s.binaryComplete = {}


_s.binaryComplete.onClean = function(node, state, stepInfo)
	xch = {}
	xch.context = state.context
	result = node.performOperation(@state.left, @state.right, xch)
	
	if xch.get("exceeded") then
		error = new IsaDepthExceededError
		error.init
		error.line = lineColumn(node._subject, node.start).line
		
		inst = new InstThrow
		inst.object = error
		return inst
	end if
	
	inst = new InstDone
	inst.result = @result
	return inst
end function


BinaryOperation.steps = _s


// LeftOperation: ?
LeftOperation = new Operation
LeftOperation._name = "LeftOperation"
LeftOperation._stepComments = {}
LeftOperation._stepComments.operand = "({operator}) operand"


_s = {}


_s._INIT = {}


_s._INIT.onClean = function(node, state, stepInfo)
	operands = node.getProperty("operands")
	opStr = binaryOperators.indexOf(node.__isa)
	if operands.len != 1 then abort "Corrupted left operator (" + opStr + "): operands.len=" + operands.len
	state.opStr = opStr
	
	stepInfo = {}
	stepInfo.name = "operand"
	stepInfo.operator = state.opStr
	
	inst = new InstNext
	inst.stepInfo = stepInfo
	return inst
end function


_s.operand = {}


_s.operand.onClean = function(node, state, stepInfo)
	inst = new InstChild
	inst.child = node.getProperty("operands")[0]
	inst.inject = {"context": state.context}
	return inst
end function


_s.operand.onResult = function(node, state, stepInfo, result)
	inst = new InstDone
	inst.result = node.performOperation(@result)
	return inst
end function


LeftOperation.steps = _s


// OpOr: ?
OpOr = new BinaryOperation
OpOr._name = "OpOr"
OpOr.shortCircuitResult = true


OpOr.shortCircuitP = function(left)
	if @left == 1 then return true
	if isFuzzyNumber(@left) then return false
	return isTruthy(@left)
end function


OpOr.performOperation = function(left, right, xch=null)
	return @left or @right
end function


// OpAnd: ?
OpAnd = new BinaryOperation
OpAnd._name = "OpAnd"
OpAnd.shortCircuitResult = false


OpAnd.shortCircuitP = function(left)
	return not isTruthy(@left)
end function


OpAnd.performOperation = function(left, right, xch=null)
	return @left and @right
end function


// OpNot: ?
OpNot = new LeftOperation
OpNot._name = "OpNot"


OpNot.performOperation = function(opValue)
	return not @opValue
end function


// OpIsa: ?
OpIsa = new BinaryOperation
OpIsa._name = "OpIsa"


OpIsa.performOperation = function(left, right, xch)
	isaP = safeIsa(xch.context.params.maxIsaDepth, @left, @right, _exceeded)
	if refEquals(isaP, _exceeded) then xch.exceeded = true
	return isaP
end function


// OpCompare: ?
OpCompare = new Operation
OpCompare._name = "OpCompare"
OpCompare._propertyFullNames = ["operands.", "operators."]
OpCompare._stepComments = {}
OpCompare._stepComments.operand = "({operator}) operand {index} of {nOperands}"


_s = {}


_s._INIT = {}


_s._INIT.onClean = function(node, state, stepInfo)
	operandNodes = node.getProperty("operands")
	operators = node.getProperty("operators")
	opStr = operators.join(" ")
	if operandNodes.len < 2 or operandNodes.len != operators.len + 1 then abort "Corrupted comparison (" + opStr + "): operandNodes.len=" + operandNodes.len + "; operators.len=" + operators.len
	state.operandNodes = operandNodes
	state.operators = operators
	state.opStr = opStr
	state.operands = []
	
	stepInfo = {}
	stepInfo.name = "operand"
	stepInfo.operator = state.opStr
	stepInfo.index = 0
	stepInfo.nOperands = state.operandNodes.len
	
	inst = new InstNext
	inst.stepInfo = stepInfo
	return inst
end function


_s.operand = {}


_s.operand.onClean = function(node, state, stepInfo)
	if stepInfo.index >= state.operandNodes.len then
		inst = new InstDone
		inst.result = node.performComparison(state.operands, state.operators)
		return inst
	end if
	
	inst = new InstChild
	inst.child = state.operandNodes[stepInfo.index]
	inst.inject = {"context": state.context}
	return inst
end function


_s.operand.onResult = function(node, state, stepInfo, result)
	state.operands.push @result
	
	stepInfo = stepInfo + {"index": stepInfo.index + 1}
	
	inst = new InstNext
	inst.stepInfo = stepInfo
	return inst
end function


OpCompare.steps = _s


OpCompare.performComparison = function(operands, operators)
	operandPairs = []
	for i in operators.indexes
		operandPairs.push [operands[i], operands[i + 1]]
	end for
	for i in operandPairs.indexes
		left = operandPairs[i][0]
		right = operandPairs[i][1]
		operator = operators[i]
		if operator == "==" then
			r = @left == @right
		else if operator == "!=" then
			r = @left != @right
		else if operator == ">" then
			r = @left > @right
		else if operator == "<" then
			r = @left < @right
		else if operator == ">=" then
			r = @left >= @right
		else if operator == "<=" then
			r = @left <= @right
		else
			abort "Unfamiliar comparison operator `" + operator + "`"
		end if
		if not r then return r
	end for
	return true
end function


// OpAdd: ?
OpAdd = new BinaryOperation
OpAdd._name = "OpAdd"


OpAdd.performOperation = function(left, right, xch=null)
	return @left + @right
end function


// OpSubtract: ?
OpSubtract = new BinaryOperation
OpSubtract._name = "OpSubtract"


OpSubtract.performOperation = function(left, right, xch=null)
	return @left - @right
end function


// OpMultiply: ?
OpMultiply = new BinaryOperation
OpMultiply._name = "OpMultiply"


OpMultiply.performOperation = function(left, right, xch=null)
	return @left * @right
end function


// OpDivide: ?
OpDivide = new BinaryOperation
OpDivide._name = "OpDivide"


OpDivide.performOperation = function(left, right, xch=null)
	return @left / @right
end function


// OpModulo: ?
OpModulo = new BinaryOperation
OpModulo._name = "OpModulo"


OpModulo.performOperation = function(left, right, xch=null)
	return @left % @right
end function


// OpUMinus: ?
OpUMinus = new LeftOperation
OpUMinus._name = "OpUMinus"


OpUMinus.performOperation = function(opValue)
	return -@opValue
end function


// OpNew: ?
OpNew = new LeftOperation
OpNew._name = "OpNew"


OpNew.performOperation = function(opValue)
	return new @opValue
end function


// OpAddress: ?
OpAddress = new LeftOperation
OpAddress._name = "OpAddress"
OpAddress._stepComments = {}
OpAddress._stepComments.operand = "(@) operand"


_s = {}


_s._INIT = {}


_s._INIT.onClean = function(node, state, stepInfo)
	operandNodes = node.getProperty("operands")
	if operandNodes.len != 1 then abort "Corrupted (@)-operator: operandNodes.len=" + operandNodes.len
	node.operandNode = operandNodes[0]
	
	stepInfo = {}
	stepInfo.name = "operand"
	stepInfo.operator = "@"
	
	inst = new InstNext
	inst.stepInfo = stepInfo
	return inst
end function


_s.operand = {}


_s.operand.onClean = function(node, state, stepInfo)
	inst = new InstChild
	inst.child = node.operandNode
	inst.inject = {"context": state.context, "doNotCall": true}
	return inst
end function


_s.operand.onResult = function(node, state, stepInfo, result)
	inst = new InstDone
	inst.result = @result
	return inst
end function


OpAddress.steps = _s


// OpPower: ?
OpPower = new BinaryOperation
OpPower._name = "OpPower"


OpPower.performOperation = function(left, right, xch=null)
	return @left ^ (@right)
end function


// OpIndex: ?
OpIndex = new Operation
OpIndex._name = "OpIndex"
OpIndex._propertyFullNames = ["operands.", "key:"]
OpIndex._stepComments = {}
OpIndex._stepComments.operand = "indexed object"
OpIndex._stepComments.key = "indexing key"


_s = {}


_s._INIT = {}


_s._INIT.onClean = function(node, state, stepInfo)
	operandNodes = node.getProperty("operands")
	keyNode = node.getProperty("key")
	if operandNodes.len != 1 then abort "Corrupted indexing: operandNodes.len=" + operandNodes.len
	state.operandNode = operandNodes[0]
	state.keyNode = keyNode
	state.object = null
	state.key = null
	
	stepInfo = {}
	stepInfo.name = "operand"
	
	inst = new InstNext
	inst.stepInfo = stepInfo
	return inst
end function


_s.operand = {}


_s.operand.onClean = function(node, state, stepInfo)
	inst = new InstChild
	inst.child = state.operandNode
	inst.inject = {"context": state.context}
	return inst
end function


_s.operand.onResult = function(node, state, stepInfo, result)
	state.object = @result
	
	stepInfo = {}
	stepInfo.name = "key"
	
	inst = new InstNext
	inst.stepInfo = stepInfo
	return inst
end function


_s.key = {}


_s.key.onClean = function(node, state, stepInfo)
	inst = new InstChild
	inst.child = state.keyNode
	inst.inject = {"context": state.context}
	return inst
end function


_s.key.onResult = function(node, state, stepInfo, result)
	state.key = @result
	
	if state.hasIndex("_smuggleMap") then
		state._smuggleMap.object = @state.object
		state._smuggleMap.key = @state.key
		
		if state._smuggleMap.get("noValue") then
			throw = new SmuggleThrow
			throw.map = state._smuggleMap
			
			inst = new InstThrow
			inst.object = throw
			return inst
		end if
	end if
	
	xch = {}
	value = safeObjectGet(state.context.params.maxIsaDepth, @state.object, @state.key, xch)
	
	if xch.get("error") then
		xch.error.line = lineColumn(state.keyNode._subject, state.keyNode.start).line
		
		inst = new InstThrow
		inst.object = xch.error
		return inst
	end if
	
	if refEquals(@value, _noVal) then
		error = new KeyNotFoundError
		error.init
		error.line = lineColumn(state.keyNode._subject, state.keyNode.start).line
		error.index = @state.key
		
		inst = new InstThrow
		inst.object = error
		return inst
	end if
	
	if refEquals(@value, _exceeded) then
		error = new IsaDepthExceededError
		error.init
		error.line = lineColumn(state.keyNode._subject, state.keyNode.start).line
		
		inst = new InstThrow
		inst.object = error
		return inst
	end if
	
	inst = new InstDone
	inst.result = @value
	return inst
end function


OpIndex.steps = _s


// OpSlice: ?
OpSlice = new Operation
OpSlice._name = "OpSlice"
OpSlice._propertyFullNames = ["operands.", "from:", "to:"]
OpSlice._stepComments = {}
OpSlice._stepComments.operand = "sliced object"
OpSlice._stepComments.from = "slicing from"
OpSlice._stepComments.to = "slicing to"
OpSlice._stepComments.complete = "result of slicing"


_s = {}


_s._INIT = {}


_s._INIT.onClean = function(node, state, stepInfo)
	operandNodes = node.getProperty("operands")
	fromNode = node.getProperty("from")
	toNode = node.getProperty("to")
	if operandNodes.len != 1 then abort "Corrupted indexing: operandNodes.len=" + operandNodes.len
	state.operandNode = operandNodes[0]
	state.fromNode = fromNode
	state.toNode = toNode
	state.from = _noVal
	state.to = _noVal
	
	stepInfo = {}
	stepInfo.name = "operand"
	
	inst = new InstNext
	inst.stepInfo = stepInfo
	return inst
end function


_s.operand = {}


_s.operand.onClean = function(node, state, stepInfo)
	inst = new InstChild
	inst.child = state.operandNode
	inst.inject = {"context": state.context}
	return inst
end function


_s.operand.onResult = function(node, state, stepInfo, result)
	state.object = @result
	
	if state.fromNode != null then
		stepInfo = {}
		stepInfo.name = "from"
	else if state.toNode != null then
		stepInfo = {}
		stepInfo.name = "to"
	else
		stepInfo = {}
		stepInfo.name = "complete"
	end if
	
	inst = new InstNext
	inst.stepInfo = stepInfo
	return inst
end function


_s.from = {}


_s.from.onClean = function(node, state, stepInfo)
	inst = new InstChild
	inst.child = state.fromNode
	inst.inject = {"context": state.context}
	return inst
end function


_s.from.onResult = function(node, state, stepInfo, result)
	state.from = @result
	
	if state.toNode != null then
		stepInfo = {}
		stepInfo.name = "to"
	else
		stepInfo = {}
		stepInfo.name = "complete"
	end if
	
	inst = new InstNext
	inst.stepInfo = stepInfo
	return inst
end function


_s.to = {}


_s.to.onClean = function(node, state, stepInfo)
	inst = new InstChild
	inst.child = state.toNode
	inst.inject = {"context": state.context}
	return inst
end function


_s.to.onResult = function(node, state, stepInfo, result)
	state.to = @result
	
	stepInfo = {}
	stepInfo.name = "complete"
	
	inst = new InstNext
	inst.stepInfo = stepInfo
	return inst
end function


_s.complete = {}


_s.complete.onClean = function(node, state, stepInfo)
	if refEquals(@state.from, _noVal) then
		if refEquals(@state.to, _noVal) then
			r = (@state.object)[:]
		else
			r = (@state.object)[:@state.to]
		end if
	else
		if refEquals(@state.to, _noVal) then
			r = (@state.object)[@state.from:]
		else
			r = (@state.object)[@state.from:@state.to]
		end if
	end if
	
	inst = new InstDone
	inst.result = @r
	return inst
end function


OpSlice.steps = _s


// OpDot: ?
OpDot = new Operation
OpDot._name = "OpDot"
OpDot._propertyFullNames = ["operands.", "name ="]
OpDot._stepComments = {}
OpDot._stepComments.operand = "indexed object"
OpDot._stepComments.invokeMember = "call parsed function (member)"


_s = {}


_s._INIT = {}


_s._INIT.onClean = function(node, state, stepInfo)
	operandNodes = node.getProperty("operands")
	if operandNodes.len != 1 then abort "Corrupted dot-operation: operandNodes.len=" + operandNodes.len
	state.operandNode = operandNodes[0]
	state.key = node.getProperty("name")
	
	stepInfo = {}
	stepInfo.name = "operand"
	
	inst = new InstNext
	inst.stepInfo = stepInfo
	return inst
end function


_s.operand = {}


_s.operand.onClean = function(node, state, stepInfo)
	inst = new InstChild
	inst.child = state.operandNode
	inst.inject = {"context": state.context}
	return inst
end function


_s.operand.onResult = function(node, state, stepInfo, result)
	state.object = @result
	
	if state.hasIndex("_smuggleMap") then
		state._smuggleMap.object = @state.object
		state._smuggleMap.key = state.key
		
		if state._smuggleMap.get("noValue") then
			throw = new SmuggleThrow
			throw.map = state._smuggleMap
			
			inst = new InstThrow
			inst.object = throw
			return inst
		end if
	end if
	
	xch = {}
	value = safeObjectGet(state.context.params.maxIsaDepth, @state.object, @state.key, xch)
	
	if xch.get("error") then
		xch.error.line = lineColumn(state.operandNode._subject, state.operandNode.start + state.operandNode.length - 1).line
		
		inst = new InstThrow
		inst.object = xch.error
		return inst
	end if
	
	if refEquals(@value, _noVal) then
		error = new KeyNotFoundError
		error.init
		error.line = lineColumn(state.operandNode._subject, state.operandNode.start + state.operandNode.length - 1).line
		error.index = @state.key
		
		inst = new InstThrow
		inst.object = error
		return inst
	end if
	
	if refEquals(@value, _exceeded) then
		error = new IsaDepthExceededError
		error.init
		error.line = lineColumn(state.operandNode._subject, state.operandNode.start + state.operandNode.length - 1).line
		
		inst = new InstThrow
		inst.object = error
		return inst
	end if
	
	state.value = @value
	
	if hasIndex(@xch, "owner") and hasIndex(@xch.owner, "__isa") then
		state.superObject = @xch.owner.__isa
	else
		state.superObject = null
	end if
	
	if state.hasIndex("_smuggleMap") then
		state._smuggleMap.superObject = @state.superObject
	end if
	
	if state.operandNode isa Identifier and state.operandNode.name == "super" then
		state.object = @state.context.namespaces.locals.get("self")
		
		if state.hasIndex("_smuggleMap") then
			state._smuggleMap.object = @state.object
		end if
	end if
	
	if state.get("doNotCall") then
		inst = new InstDone
		inst.result = @value
		return inst
	end if
	
	if safeIsa(state.context.params.maxIsaDepth, @value, ParsedFunction) then
		stepInfo = {}
		stepInfo.name = "invokeMember"
		
		inst = new InstNext
		inst.stepInfo = stepInfo
		return inst
	end if
	
	if not safeIsa(state.context.params.maxIsaDepth, @value, funcRef) then
		inst = new InstDone
		inst.result = @value
		return inst
	end if
	
	if not state.context.params.cthulhuTrick then
		result = callFunction(@value, [])
	else
		installedTo = installCthulhuMethod(@state.object, @value)
		_callable = safeObjectGet(state.context.params.maxIsaDepth, @state.object, "Ph_nglui_mglw_nafh_Cthulhu_R_lyeh_wgah_nagl_fhtagn", {})
		if refEquals(@_callable, _noVal) or refEquals(@_callable, _exceeded) then
			error = new MethodNotFoundError
			error.init
			error.line = lineColumn(state.operandNode._subject, state.operandNode.start + state.operandNode.length - 1).line
			error.index = @state.key
			
			inst = new InstThrow
			inst.object = error
			return inst
		end if
		result = callCthulhuMethod(@state.object, [])
		if installedTo then installedTo.remove "Ph_nglui_mglw_nafh_Cthulhu_R_lyeh_wgah_nagl_fhtagn"
	end if
	
	inst = new InstDone
	inst.result = @result
	return inst
end function


_s.invokeMember = {}


_s.invokeMember.onClean = function(node, state, stepInfo)
	inst = new InstChild
	inst.child = @state.value
	inst.inject = {"context": state.context, "object": @state.object, "superObject": @state.superObject, "callNode": node}
	return inst
end function


_s.invokeMember.onResult = function(node, state, stepInfo, result)
	inst = new InstDone
	inst.result = @result
	return inst
end function


OpDot.steps = _s


// OpCall: ?
OpCall = new Operation
OpCall._name = "OpCall"
OpCall._propertyFullNames = ["operands.", "args."]
OpCall._stepComments = {}
OpCall._stepComments.operand = "callable"
OpCall._stepComments.arg = "call-argument {index} of {nArgs}"
OpCall._stepComments.complete = "result of call"
OpCall._stepComments.invokeIdentifier = "call parsed function"
OpCall._stepComments.invokeMember = "call parsed function (member)"


_s = {}


_s._INIT = {}


_s._INIT.onClean = function(node, state, stepInfo)
	operandNodes = node.getProperty("operands")
	argNodes = node.getProperty("args")
	if argNodes == null then argNodes = []
	if operandNodes.len != 1 then abort "Corrupted dot-operation: operandNodes.len=" + operandNodes.len
	state.operandNode = operandNodes[0]
	state.argNodes = argNodes
	state.object = null
	state.superObject = null
	state.callable = null
	state.args = []
	state._smuggleMap = {}
	
	stepInfo = {}
	stepInfo.name = "operand"
	
	inst = new InstNext
	inst.stepInfo = stepInfo
	return inst
end function


_s.operand = {}


_s.operand.onClean = function(node, state, stepInfo)
	inst = new InstChild
	inst.child = state.operandNode
	inst.inject = {"context": state.context, "doNotCall": true, "_smuggleMap": state._smuggleMap}
	return inst
end function


_s.operand.onResult = function(node, state, stepInfo, result)
	state.callable = @result
	
	stepInfo = {}
	stepInfo.name = "arg"
	stepInfo.index = 0
	stepInfo.nArgs = state.argNodes.len
	
	inst = new InstNext
	inst.stepInfo = stepInfo
	return inst
end function


_s.arg = {}


_s.arg.onClean = function(node, state, stepInfo)
	if stepInfo.index >= state.argNodes.len then
		stepInfo = {}
		stepInfo.name = "complete"
		
		inst = new InstNext
		inst.stepInfo = stepInfo
		return inst
	end if
	
	inst = new InstChild
	inst.child = state.argNodes[stepInfo.index]
	inst.inject = {"context": state.context}
	return inst
end function


_s.arg.onResult = function(node, state, stepInfo, result)
	state.args.push @result
	
	stepInfo += {"index": stepInfo.index + 1}
	
	inst = new InstNext
	inst.stepInfo = stepInfo
	return inst
end function


_s.complete = {}


_s.complete.onClean = function(node, state, stepInfo)
	state.object = state._smuggleMap.get("object")
	state.superObject = state._smuggleMap.get("superObject")
	state.key = state._smuggleMap.get("key")
	
	if state.args.len == 0 and state.operandNode isa OpAddress and state.get("addressOperandAsResult") then
		inst = new InstDone
		inst.result = @state.callable
		return inst
	end if
	
	if safeIsa(state.context.params.maxIsaDepth, @state.callable, ParsedFunction) then
		if @state.object == null then
			stepInfo = {}
			stepInfo.name = "invokeIdentifier"
		else
			stepInfo = {}
			stepInfo.name = "invokeMember"
		end if
		
		inst = new InstNext
		inst.stepInfo = stepInfo
		return inst
	end if
	
	if not safeIsa(state.context.params.maxIsaDepth, @state.callable, funcRef) then
		if state.get("noncallableAsResult") and state.args.len == 0 then
			inst = new InstDone
			inst.result = @state.callable
			return inst
		end if
		
		error = new NotCallableError
		error.init
		error.line = lineColumn(state.operandNode._subject, state.operandNode.start).line
		error.maxAccept = 0
		error.got = state.args.len
		
		inst = new InstThrow
		inst.object = error
		return inst
	end if
	
	if state.args.len > 33 then
		error = new MaxArgsExceededError
		error.init
		error.line = lineColumn(state.operandNode._subject, state.operandNode.start).line
		error.nArgs = state.args.len
		
		inst = new InstThrow
		inst.object = error
		return inst
	end if
	
	if @state.object == null or not state.context.params.cthulhuTrick then
		result = callFunction(@state.callable, state.args)
	else
		installedTo = installCthulhuMethod(@state.object, @state.callable)
		_callable = safeObjectGet(state.context.params.maxIsaDepth, @state.object, "Ph_nglui_mglw_nafh_Cthulhu_R_lyeh_wgah_nagl_fhtagn", {})
		if refEquals(@_callable, _noVal) or refEquals(@_callable, _exceeded) then
			error = new MethodNotFoundError
			error.init
			error.line = lineColumn(state.operandNode._subject, state.operandNode.start + state.operandNode.length - 1).line
			error.index = @state.key
			
			inst = new InstThrow
			inst.object = error
			return inst
		end if
		result = callCthulhuMethod(@state.object, state.args)
		if installedTo then installedTo.remove "Ph_nglui_mglw_nafh_Cthulhu_R_lyeh_wgah_nagl_fhtagn"
	end if
	
	inst = new InstDone
	inst.result = @result
	return inst
end function


_s.invokeIdentifier = {}


_s.invokeIdentifier.onClean = function(node, state, stepInfo)
	inst = new InstChild
	inst.child = @state.callable
	inst.inject = {"context": state.context, "args": state.args, "callNode": node}
	return inst
end function


_s.invokeIdentifier.onResult = function(node, state, stepInfo, result)
	inst = new InstDone
	inst.result = @result
	return inst
end function


_s.invokeMember = {}


_s.invokeMember.onClean = function(node, state, stepInfo)
	inst = new InstChild
	inst.child = @state.callable
	inst.inject = {"context": state.context, "object": @state.object, "superObject": @state.superObject, "args": state.args, "callNode": node}
	return inst
end function


_s.invokeMember.onResult = function(node, state, stepInfo, result)
	inst = new InstDone
	inst.result = @result
	return inst
end function


OpCall.steps = _s


// Statement: ?
Statement = new SyntaxNode
Statement._name = "ms.Statement"
Statement.isLine = false


// StmtEmpty: ?
StmtEmpty = new Statement
StmtEmpty._name = "StmtEmpty"


_s = {}


_s._INIT = {}


_s._INIT.onClean = function(node, state, stepInfo)
	inst = new InstDone
	inst.result = None
	return inst
end function


StmtEmpty.steps = _s


// StmtCall: ?
StmtCall = new Statement
StmtCall._name = "StmtCall"
StmtCall.isLine = true
StmtCall._propertyFullNames = ["callable:", "args."]
StmtCall._stepComments = {}
StmtCall._stepComments.operand = "callable"
StmtCall._stepComments.arg = "call-argument {index} of {nArgs}"
StmtCall._stepComments.complete = "result of call"
StmtCall._stepComments.invokeIdentifier = "call parsed function"
StmtCall._stepComments.invokeMember = "call parsed function (member)"


_s = {}


_s._INIT = {}


_s._INIT.onClean = function(node, state, stepInfo)
	argNodes = node.getProperty("args")
	if argNodes == null then argNodes = []
	state.operandNode = node.getProperty("callable")
	state.argNodes = argNodes
	state.callable = null
	state.args = []
	state._smuggleMap = {}
	state.noncallableAsResult = true
	state.addressOperandAsResult = state.context.features.faithfulAddress
	
	stepInfo = {}
	stepInfo.name = "operand"
	
	inst = new InstNext
	inst.stepInfo = stepInfo
	return inst
end function


_s.operand = OpCall.steps.operand
_s.arg = OpCall.steps.arg
_s.complete = OpCall.steps.complete
_s.invokeIdentifier = OpCall.steps.invokeIdentifier
_s.invokeMember = OpCall.steps.invokeMember


StmtCall.steps = _s


// StmtAssign: ?
StmtAssign = new Statement
StmtAssign._name = "StmtAssign"
StmtAssign.isLine = true
StmtAssign._propertyFullNames = ["left:", "right:", "math ="]
StmtAssign._stepComments = {}
StmtAssign._stepComments.left = "left-hand side of ({assignStr})"
StmtAssign._stepComments.right = "right-hand side of ({assignStr})"


_s = {}


_s._INIT = {}


_s._INIT.onClean = function(node, state, stepInfo)
	state.leftNode = node.getProperty("left")
	state.rightNode = node.getProperty("right")
	state.mathSymbol = node.getProperty("math")
	
	state.assignStr = "="
	if state.mathSymbol then state.assignStr += state.mathSymbol
	
	state.leftObject = null
	state.leftKey = null
	state.leftEvaluated = null
	state.right = null
	state._smuggleMap = {"noValue": not state.mathSymbol}
	
	_locals = state.context.namespaces.locals
	if state.leftNode isa Identifier and not hasIndex(_locals, state.leftNode.name) and state.rightNode.identSet.get(state.leftNode.name) then
		warning = new LocalFromNonlocalWarning
		warning.init
		warning.line = lineColumn(state.leftNode._subject, state.leftNode.start).line
		warning.identifier = state.leftNode.name
		state.context.reportWarning warning
	end if
	
	stepInfo = {}
	stepInfo.name = "left"
	stepInfo.assignStr = state.assignStr
	
	inst = new InstNext
	inst.stepInfo = stepInfo
	return inst
end function


_s.left = {}


_s.left.onClean = function(node, state, stepInfo)
	inst = new InstChild
	inst.child = state.leftNode
	inst.inject = {"context": state.context, "_smuggleMap": state._smuggleMap}
	inst.catch = SmuggleThrow
	return inst
end function


_s.left.onResult = function(node, state, stepInfo, result)
	if not state.mathSymbol then abort "Unexpected lvalue evaluation (" + str(state.leftNode.__isa) + ")"
	
	state.leftObject = state._smuggleMap.get("object", state.context.namespaces.locals)
	state.leftKey = @state._smuggleMap.key
	state.leftEvaluated = @result
	
	stepInfo = {}
	stepInfo.name = "right"
	stepInfo.assignStr = state.assignStr
	
	inst = new InstNext
	inst.stepInfo = stepInfo
	return inst
end function


_s.left.onCaught = function(node, state, stepInfo, caught, trace)
	state.leftObject = state._smuggleMap.get("object", state.context.namespaces.locals)
	state.leftKey = @state._smuggleMap.key
	
	stepInfo = {}
	stepInfo.name = "right"
	stepInfo.assignStr = state.assignStr
	
	inst = new InstNext
	inst.stepInfo = stepInfo
	return inst
end function


_s.right = {}


_s.right.onClean = function(node, state, stepInfo)
	inst = new InstChild
	inst.child = state.rightNode
	inst.inject = {"context": state.context}
	return inst
end function


_s.right.onResult = function(node, state, stepInfo, result)
	state.right = @result
	
	if state.mathSymbol == "+" then
		result = OpAdd.performOperation(@state.leftEvaluated, @result)
	else if state.mathSymbol == "-" then
		result = OpSubtract.performOperation(@state.leftEvaluated, @result)
	else if state.mathSymbol == "*" then
		result = OpMultiply.performOperation(@state.leftEvaluated, @result)
	else if state.mathSymbol == "/" then
		result = OpDivide.performOperation(@state.leftEvaluated, @result)
	else if state.mathSymbol == "%" then
		result = OpModulo.performOperation(@state.leftEvaluated, @result)
	else if state.mathSymbol == "^" then
		result = OpPower.performOperation(@state.leftEvaluated, @result)
	else if state.mathSymbol then
		abort "Unfamiliar math-assignment `" + state.mathSymbol + "`"
	end if
	
	@state.leftObject[@state.leftKey] = @result
	
	inst = new InstDone
	inst.result = None
	return inst
end function


StmtAssign.steps = _s


// StmtIf: ?
StmtIf = new Statement
StmtIf._name = "StmtIf"
StmtIf._propertyFullNames = ["conditions.", "statements..", "elseStatements."]
StmtIf._stepComments = {}
StmtIf._stepComments.condition = "(if)-condition {conditionIndex} of {nConditions}"
StmtIf._stepComments.statement = "(if)-clause statement {statementIndex} of {nStatements} (clause {clauseIndex} of {nClauses})"


_s = {}


_s._INIT = {}


_s._INIT.onClean = function(node, state, stepInfo)
	state.conditionNodes = node.getProperty("conditions")
	
	stepInfo = {}
	stepInfo.name = "condition"
	stepInfo.conditionIndex = 0
	stepInfo.nConditions = state.conditionNodes.len
	
	inst = new InstNext
	inst.stepInfo = stepInfo
	return inst
end function


_s.condition = {}


_s.condition.onClean = function(node, state, stepInfo)
	if stepInfo.conditionIndex >= state.conditionNodes.len then
		
		state.statementNodes = node.getProperty("elseStatements")
		
		if state.statementNodes then
			stepInfo = {}
			stepInfo.name = "statement"
			stepInfo.statementIndex = 0
			stepInfo.nStatements = state.statementNodes.len
			stepInfo.clauseIndex = "<else>"
			stepInfo.nClauses = state.conditionNodes.len
			
			inst = new InstNext
			inst.stepInfo = stepInfo
			return inst
		else
			inst = new InstDone
			inst.result = None
			return inst
		end if
	end if
	
	inst = new InstChild
	inst.child = state.conditionNodes[stepInfo.conditionIndex]
	inst.inject = {"context": state.context}
	return inst
end function


_s.condition.onResult = function(node, state, stepInfo, result)
	if @result then
		state.statementNodes = node.getProperty("statements", stepInfo.conditionIndex)
		
		if not state.statementNodes then
			inst = new InstDone
			inst.result = None
			return inst
		end if
		
		conditionIndex = stepInfo.conditionIndex
		
		stepInfo = {}
		stepInfo.name = "statement"
		stepInfo.statementIndex = 0
		stepInfo.nStatements = state.statementNodes.len
		stepInfo.clauseIndex = conditionIndex
		stepInfo.nClauses = state.conditionNodes.len
		
		inst = new InstNext
		inst.stepInfo = stepInfo
		return inst
	end if
	
	stepInfo += {"conditionIndex": stepInfo.conditionIndex + 1}
	
	inst = new InstNext
	inst.stepInfo = stepInfo
	return inst
end function


_s.statement = {}


_s.statement.onClean = function(node, state, stepInfo)
	if stepInfo.statementIndex >= state.statementNodes.len then
		inst = new InstDone
		inst.result = None
		return inst
	end if
	
	inst = new InstChild
	inst.child = state.statementNodes[stepInfo.statementIndex]
	inst.inject = {"context": state.context}
	return inst
end function


_s.statement.onResult = function(node, state, stepInfo, result)
	stepInfo += {"statementIndex": stepInfo.statementIndex + 1}
	
	inst = new InstNext
	inst.stepInfo = stepInfo
	return inst
end function


StmtIf.steps = _s


// StmtWhile: ?
StmtWhile = new Statement
StmtWhile._name = "StmtWhile"
StmtWhile._propertyFullNames = ["condition:", "statements."]
StmtWhile._stepComments = {}
StmtWhile._stepComments.condition = "(while)-condition (iteration {iterationIndex})"
StmtWhile._stepComments.statement = "(while)-clause statement {statementIndex} of {nStatements} (iteration {iterationIndex})"


_s = {}


_s._INIT = {}


_s._INIT.onClean = function(node, state, stepInfo)
	condition = node.getProperty("condition")
	statements = node.getProperty("statements")
	if statements == null then statements = []
	state.conditionNode = condition
	state.statementNodes = statements
	
	stepInfo = {}
	stepInfo.name = "condition"
	stepInfo.iterationIndex = 0
	
	inst = new InstNext
	inst.stepInfo = stepInfo
	return inst
end function


_s.condition = {}


_s.condition.onClean = function(node, state, stepInfo)
	inst = new InstChild
	inst.child = state.conditionNode
	inst.inject = {"context": state.context}
	return inst
end function


_s.condition.onResult = function(node, state, stepInfo, result)
	if not @result then
		inst = new InstDone
		inst.result = None
		return inst
	end if
	
	iterationIndex = stepInfo.iterationIndex
	
	stepInfo = {}
	stepInfo.name = "statement"
	stepInfo.statementIndex = 0
	stepInfo.nStatements = state.statementNodes.len
	stepInfo.iterationIndex = iterationIndex
	
	inst = new InstNext
	inst.stepInfo = stepInfo
	return inst
end function


_s.statement = {}


_s.statement.onClean = function(node, state, stepInfo)
	if stepInfo.statementIndex >= state.statementNodes.len then
		iterationIndex = stepInfo.iterationIndex
		
		stepInfo = {}
		stepInfo.name = "condition"
		stepInfo.iterationIndex = iterationIndex + 1
		
		inst = new InstNext
		inst.stepInfo = stepInfo
		return inst
	end if
	
	inst = new InstChild
	inst.child = state.statementNodes[stepInfo.statementIndex]
	inst.inject = {"context": state.context}
	inst.catch = [BreakThrow, ContinueThrow]
	return inst
end function


_s.statement.onResult = function(node, state, stepInfo, result)
	stepInfo += {"statementIndex": stepInfo.statementIndex + 1}
	
	inst = new InstNext
	inst.stepInfo = stepInfo
	return inst
end function


_s.statement.onCaught = function(node, state, stepInfo, caught, trace)
	if caught isa BreakThrow then
		inst = new InstDone
		inst.result = None
		return inst
	else if caught isa ContinueThrow then
		iterationIndex = stepInfo.iterationIndex
		
		stepInfo = {}
		stepInfo.name = "condition"
		stepInfo.iterationIndex = iterationIndex + 1
		
		inst = new InstNext
		inst.stepInfo = stepInfo
		return inst
	else
		abort "Unfamiliar throw: `" + str(caught) + "`:" + _NL + state.context.formatTrace(trace)
	end if
end function


StmtWhile.steps = _s


// StmtFor: ?
StmtFor = new Statement
StmtFor._name = "StmtFor"
StmtFor._propertyFullNames = ["var =", "expression:", "statements."]
StmtFor._stepComments = {}
StmtFor._stepComments.forExpression = "(for)-expression"
StmtFor._stepComments.next = "(for)-var reassignment (iteration {iterationIndex})"
StmtFor._stepComments.statement = "(for)-clause statement {statementIndex} of {nStatements} (iteration {iterationIndex})"


_s = {}


_s._INIT = {}


_s._INIT.onClean = function(node, state, stepInfo)
	expressionNode = node.getProperty("expression")
	statementNodes = node.getProperty("statements")
	if statementNodes == null then statementNodes = []
	state.expressionNode = expressionNode
	state.statementNodes = statementNodes
	state.var = node.getProperty("var")
	state.sequence = null
	
	stepInfo = {}
	stepInfo.name = "forExpression"
	
	inst = new InstNext
	inst.stepInfo = stepInfo
	return inst
end function


_s.forExpression = {}


_s.forExpression.onClean = function(node, state, stepInfo)
	inst = new InstChild
	inst.child = state.expressionNode
	inst.inject = {"context": state.context}
	return inst
end function


_s.forExpression.onResult = function(node, state, stepInfo, result)
	if @result == null then
		error = new NullForExpressionError
		error.init
		error.line = lineColumn(state.expressionNode._subject, state.expressionNode.start).line
		
		inst = new InstThrow
		inst.object = error
		return inst
	else if safeIsa(state.context.params.maxIsaDepth, @result, list) or @result isa map then
		state.sequence = []
		for x in result
			state.sequence.push x
		end for
	else if state.context.features.raiseNonsequenceFor then
		error = new NonsequenceForError
		error.init
		error.line = lineColumn(state.expressionNode._subject, state.expressionNode.start).line
		error.objectType = state.expressionNode._name
		
		inst = new InstThrow
		inst.object = error
		return inst
	else
		inst = new InstDone
		inst.result = None
		return inst
	end if
	
	stepInfo = {}
	stepInfo.name = "next"
	stepInfo.iterationIndex = 0
	
	inst = new InstNext
	inst.stepInfo = stepInfo
	return inst
end function


_s.next = {}


_s.next.onClean = function(node, state, stepInfo)
	if stepInfo.iterationIndex >= state.sequence.len then
		inst = new InstDone
		inst.result = None
		return inst
	end if
	
	state.context.namespaces.locals[state.var] = state.sequence[stepInfo.iterationIndex]
	
	iterationIndex = stepInfo.iterationIndex
	
	stepInfo = {}
	stepInfo.name = "statement"
	stepInfo.statementIndex = 0
	stepInfo.nStatements = state.statementNodes.len
	stepInfo.iterationIndex = iterationIndex
	
	inst = new InstNext
	inst.stepInfo = stepInfo
	return inst
end function


_s.statement = {}


_s.statement.onClean = function(node, state, stepInfo)
	if stepInfo.statementIndex >= state.statementNodes.len then
		iterationIndex = stepInfo.iterationIndex
		
		stepInfo = {}
		stepInfo.name = "next"
		stepInfo.iterationIndex = iterationIndex + 1
		
		inst = new InstNext
		inst.stepInfo = stepInfo
		return inst
	end if
	
	inst = new InstChild
	inst.child = state.statementNodes[stepInfo.statementIndex]
	inst.inject = {"context": state.context}
	inst.catch = [BreakThrow, ContinueThrow]
	return inst
end function


_s.statement.onResult = function(node, state, stepInfo, result)
	stepInfo += {"statementIndex": stepInfo.statementIndex + 1}
	
	inst = new InstNext
	inst.stepInfo = stepInfo
	return inst
end function


_s.statement.onCaught = function(node, state, stepInfo, caught, trace)
	if caught isa BreakThrow then
		inst = new InstDone
		inst.result = None
		return inst
	else if caught isa ContinueThrow then
		iterationIndex = stepInfo.iterationIndex
		
		stepInfo = {}
		stepInfo.name = "next"
		stepInfo.iterationIndex = iterationIndex + 1
		
		inst = new InstNext
		inst.stepInfo = stepInfo
		return inst
	else
		abort "Unfamiliar throw: `" + str(caught) + "`:" + _NL + state.context.formatTrace(trace)
	end if
end function


StmtFor.steps = _s


// StmtReturn: ?
StmtReturn = new Statement
StmtReturn._name = "StmtReturn"
StmtReturn.isLine = true
StmtReturn._propertyFullNames = ["expression:"]


_s = {}


_s._INIT = {}


_s._INIT.onClean = function(node, state, stepInfo)
	expressionNode = node.getProperty("expression")
	
	if expressionNode == null then
		throw = new ReturnThrow
		throw.object = null
		
		inst = new InstThrow
		inst.object = throw
		return inst
	end if
	
	inst = new InstChild
	inst.child = expressionNode
	inst.inject = {"context": state.context}
	return inst
end function


_s._INIT.onResult = function(node, state, stepInfo, result)
	throw = new ReturnThrow
	throw.object = @result
	
	inst = new InstThrow
	inst.object = throw
	return inst
end function


StmtReturn.steps = _s


// StmtBreak: ?
StmtBreak = new Statement
StmtBreak._name = "StmtBreak"
StmtBreak.isLine = true


_s = {}


_s._INIT = {}


_s._INIT.onClean = function(node, state, stepInfo)
	throw = new BreakThrow
	inst = new InstThrow
	inst.object = throw
	return inst
end function


StmtBreak.steps = _s


// StmtContinue: ?
StmtContinue = new Statement
StmtContinue._name = "StmtContinue"
StmtContinue.isLine = true


_s = {}


_s._INIT = {}


_s._INIT.onClean = function(node, state, stepInfo)
	throw = new ContinueThrow
	inst = new InstThrow
	inst.object = throw
	return inst
end function


StmtContinue.steps = _s


// Program: ?
Program = new SyntaxNode
Program._name = "Program"
Program._propertyFullNames = ["file:", "shebang:", "statements."]
Program._stepComments = {}
Program._stepComments.statement = "top-level statement {statementIndex} of {nStatements}"


_s = {}


_s._INIT = {}


_s._INIT.onClean = function(node, state, stepInfo)
	statementNodes = node.getProperty("statements")
	if statementNodes == null then statementNodes = []
	state.statementNodes = statementNodes
	state.recentResult = None
	
	stepInfo = {}
	stepInfo.name = "statement"
	stepInfo.statementIndex = 0
	stepInfo.nStatements = state.statementNodes.len
	
	inst = new InstNext
	inst.stepInfo = stepInfo
	return inst
end function


_s.statement = {}


_s.statement.onClean = function(node, state, stepInfo)
	if stepInfo.statementIndex >= state.statementNodes.len then
		inst = new InstDone
		inst.result = state.recentResult
		return inst
	end if
	
	inst = new InstChild
	inst.child = state.statementNodes[stepInfo.statementIndex]
	inst.inject = {"context": state.context}
	return inst
end function


_s.statement.onResult = function(node, state, stepInfo, result)
	state.recentResult = @result
	
	stepInfo += {"statementIndex": stepInfo.statementIndex + 1}
	
	inst = new InstNext
	inst.stepInfo = stepInfo
	return inst
end function


Program.steps = _s


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


// ParsedFunction: ?
ParsedFunction = {}
ParsedFunction._name = "ParsedFunction"
ParsedFunction._inited = false
ParsedFunction.funcNode = null
ParsedFunction.context = null
ParsedFunction.isSelfFunc = null
ParsedFunction._stepComments = {}
ParsedFunction._stepComments.bindArg = "bind arg {argIndex} of {nArgs}"
ParsedFunction._stepComments.statement = "function body statement {statementIndex} of {nStatements}"


_s = {}


_s._INIT = {}


_s._INIT.onClean = function(invFunc, state, stepInfo)
	argNames = invFunc.funcNode.getProperty("args")
	defaultNodes = invFunc.funcNode.getProperty("defaults")
	statementNodes = invFunc.funcNode.getProperty("statements")
	
	if argNames == null then argNames = []
	if defaultNodes == null then defaultNodes = []
	if statementNodes == null then statementNodes = []
	
	state.argNames = argNames
	state.defaultNodes = defaultNodes
	state.statementNodes = statementNodes
	
	if not state.hasIndex("args") then state.args = []
	if not state.hasIndex("object") then state.object = None
	if not state.hasIndex("superObject") then state.superObject = None
	if not state.hasIndex("callNode") then state.callNode = null
	
	if not refEquals(@state.object, None) and invFunc.isSelfFunc then
		state.argNames.pull
		state.defaultNodes.pull
	end if
	
	if state.args.len > state.argNames.len then
		error = new TooManyArgsError
		error.init
		error.line = 1
		if state.callNode != null then error.line = lineColumn(state.callNode._subject, state.callNode.start).line
		error.maxAccept = state.argNames.len
		error.got = state.args.len
		
		inst = new InstThrow
		inst.object = error
		return inst
	end if
	
	stepInfo = {}
	stepInfo.name = "bindArg"
	stepInfo.argIndex = 0
	stepInfo.nArgs = state.argNames.len
	
	inst = new InstNext
	inst.stepInfo = stepInfo
	return inst
end function


_s.bindArg = {}


_s.bindArg.onClean = function(invFunc, state, stepInfo)
	if stepInfo.argIndex >= state.argNames.len then
		if not refEquals(@state.object, None) then
			invFunc.context.namespaces.locals.self = @state.object
			invFunc.context.namespaces.locals.super = @state.superObject
		end if
		
		stepInfo = {}
		stepInfo.name = "statement"
		stepInfo.statementIndex = 0
		stepInfo.nStatements = state.statementNodes.len
		
		inst = new InstNext
		inst.stepInfo = stepInfo
		return inst
	end if
	
	argName = state.argNames[stepInfo.argIndex]
	
	if stepInfo.argIndex < state.args.len then
		invFunc.context.namespaces.locals[argName] = state.args[stepInfo.argIndex]
		
		stepInfo += {"argIndex": stepInfo.argIndex + 1}
		
		inst = new InstNext
		inst.stepInfo = stepInfo
		return inst
	end if
	
	if stepInfo.argIndex >= state.defaultNodes.len then
		invFunc.context.namespaces.locals[argName] = null
		
		stepInfo += {"argIndex": stepInfo.argIndex + 1}
		
		inst = new InstNext
		inst.stepInfo = stepInfo
		return inst
	end if
	
	defaultNode = state.defaultNodes[stepInfo.argIndex]
	
	if defaultNode == null then
		invFunc.context.namespaces.locals[argName] = null
		
		stepInfo += {"argIndex": stepInfo.argIndex + 1}
		
		inst = new InstNext
		inst.stepInfo = stepInfo
		return inst
	end if
	
	inst = new InstChild
	inst.child = defaultNode
	inst.inject = {"context": state.context}
	return inst
end function


_s.bindArg.onResult = function(invFunc, state, stepInfo, result)
	argName = state.argNames[stepInfo.argIndex]
	invFunc.context.namespaces.locals[argName] = @result
	
	stepInfo += {"argIndex": stepInfo.argIndex + 1}
	
	inst = new InstNext
	inst.stepInfo = stepInfo
	return inst
end function


_s.statement = {}


_s.statement.onClean = function(invFunc, state, stepInfo)
	if stepInfo.statementIndex >= state.statementNodes.len then
		inst = new InstDone
		inst.result = null
		return inst
	end if
	
	inst = new InstChild
	inst.child = state.statementNodes[stepInfo.statementIndex]
	inst.inject = {"context": invFunc.context}
	inst.catch = ReturnThrow
	return inst
end function


_s.statement.onResult = function(invFunc, state, stepInfo, result)
	stepInfo += {"statementIndex": stepInfo.statementIndex + 1}
	
	inst = new InstNext
	inst.stepInfo = stepInfo
	return inst
end function


_s.statement.onCaught = function(invFunc, state, stepInfo, caught, trace)
	inst = new InstDone
	inst.result = @caught.object
	return inst
end function


ParsedFunction.steps = _s


ParsedFunction.init = function(funcNode, context)
	self._inited = true
	self.funcNode = funcNode
	self.context = context
	self.argNames = funcNode.getProperty("args")
	if self.argNames == null then self.argNames = []
	self.isSelfFunc = self.argNames and self.argNames[0] == "self"
end function


ParsedFunction._str = function(depth, seen)
	aParts = []
	for name in self.argNames
		aParts.push name + "=…"
	end for
	return "ParsedFunction(" + aParts.join(", ") + ")"
end function


// toFuncRef: ?
ParsedFunction.toFuncRef = function
	if self.isSelfFunc then
		generator = @nArgsSelfFunction
		nArgs = self.argNames.len - 1
	else
		generator = @nArgsFunction
		nArgs = self.argNames.len
	end if
	
	invFunc = self
	
	_f = function(selfObject, args)
		if selfObject == null then
			return invFunc.evalWithoutSelf(args)
		else
			return invFunc.evalWithSelf(selfObject, args)
		end if
	end function
	
	return generator(@_f, nArgs)
end function


// evalWithSelf: ?
ParsedFunction.evalWithSelf = function(selfObject, args, context=null)
	if context == null then context = {}
	
	ctx = new Context
	ctx.init
	ctx.updateFrom self.context
	ctx.updateFrom context
	updateInPlace context, ctx
	
	frame = new Frame
	frame.init self, {"context": context, "args": args, "object": selfObject}
	
	return eval(frame, context)
end function


// evalWithoutSelf: ?
ParsedFunction.evalWithoutSelf = function(args, context=null)
	if context == null then context = {}
	
	ctx = new Context
	ctx.init
	ctx.updateFrom self.context
	ctx.updateFrom context
	updateInPlace context, ctx
	
	frame = new Frame
	frame.init self, {"context": context, "args": args}
	
	return eval(frame, context)
end function










//  _|_|_|  _|  _|_|    _|_|_|  _|_|_|  _|_|    _|_|_|  _|_|      _|_|_|  _|  _|_|  
//_|    _|  _|_|      _|    _|  _|    _|    _|  _|    _|    _|  _|    _|  _|_|      
//_|    _|  _|        _|    _|  _|    _|    _|  _|    _|    _|  _|    _|  _|        
//  _|_|_|  _|          _|_|_|  _|    _|    _|  _|    _|    _|    _|_|_|  _|        
//      _|                                                                          
//  _|_|                                                                            


// definitions: ?
definitions = "" +
"                                                                   " + _NL +
"                                                                   " + _NL +
"  PhysicalNL       <-  '\r\n'  /  [\r\n]                           " + _NL +
"  Comment          <-  '//'  ( ! PhysicalNL  . ) * {comment}       " + _NL +
"  LogicalNL        <-  Comment ?  PhysicalNL                       " + _NL +
"                                                                   " + _NL +
"                                                                   " + _NL +
"  LxSep            <-  [ \t] *                                         " + _NL +
"  LxCont           <-  [ \t] *                                         " + _NL +
"                       %if features.multilineContinuations then %      " + _NL +
"                           ( LogicalNL  [ \t] * ) *                    " + _NL +
"                       %else%                                          " + _NL +
"                           ( LogicalNL  [ \t] * ) ?                    " + _NL +
"                       %end if%                                        " + _NL +
"                       ( ! . ) <reportContLine> ?                      " + _NL +
"                                                                   " + _NL +
"                                                                   " + _NL +
"  StSep            <-  ( ';'  /  LogicalNL )  [ \t] *              " + _NL +
"                                                                   " + _NL +
"                                                                   " + _NL +
"  AlwaysFail       <-  '' <alwaysFail>                             " + _NL +
"                                                                   " + _NL +
"                                                                   " + _NL +
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
"                                                                                           " + _NL +
"                                                                                           " + _NL +
"  LitNull          <-  KeyNull {litNull}  LxSep                                            " + _NL +
"  LitTrue          <-  KeyTrue {litTrue}  LxSep                                            " + _NL +
"  LitFalse         <-  KeyFalse {litFalse}  LxSep                                          " + _NL +
"                                                                                           " + _NL +
"                                                                                           " + _NL +
"  Identifier       <-  ! Keyword  ( [a-zA-Z_]  [a-zA-Z0-9_] * ) {identifier}  LxSep        " + _NL +
"                                                                                           " + _NL +
"                                                                                           " + _NL +
"  NumInt           <-  [0-9] + {int:}                                                      " + _NL +
"  NumFract         <-  [0-9] + {fract:}                                                    " + _NL +
"  NumExpSign       <-  [+-] ? {eSign:}                                                     " + _NL +
"  NumExpDigits     <-  [0-9] + {exp:}                                                      " + _NL +
"  NumSignifDigit   <-  NumInt  ( '.'  NumFract ? ) ?                                       " + _NL +
"  NumSignifDot     <-  '.'  NumFract                                                       " + _NL +
"  NumSignif        <-  NumSignifDigit  /  NumSignifDot                                     " + _NL +
"  NumExp           <-  [Ee]  NumExpSign  NumExpDigits <expectedNumeralExponent!>             " + _NL +
"  LitNumeral       <-  ( NumSignif  NumExp ? ) {litNumeral}  LxSep                         " + _NL +
"                                                                                           " + _NL +
"                                                                                           " + _NL +
"  StrChar          <-  %if features.multilineStrings then%                                 " + _NL +
"                           ( ! . ) <reportContString> ?  ! '""'  .                         " + _NL +
"                       %else%                                                              " + _NL +
"                           ! ( '""'  /  PhysicalNL )  .                                    " + _NL +
"                       %end if%                                                            " + _NL +
"  StrContent       <-  ( '""""'  /  StrChar ) * {}                                         " + _NL +
"  StrClose         <-  '""' <expectedStringClose!>                                           " + _NL +
"  LitString        <-  ( '""'  StrContent  StrClose ) {litString}  LxSep                   " + _NL +
"                                                                                           " + _NL +
"                                                                                           " + _NL +
"  ExpParens        <-  ( '('  LxCont  Expression <expectedExpression!>  ')' <expectedClosingParen!> ) {expParens}  LxSep     " + _NL +
"                                                                                           " + _NL +
"                                                                                           " + _NL +
"  LitList          <-  ( '['  LxCont  ( Expression  ( ','  LxCont  Expression ) *  ( ','  LxCont ) ? ) ?  ']' <expectedClosingBracket!> ) {litList}  LxSep  " + _NL +
"                                                                                           " + _NL +
"                                                                                           " + _NL +
"  MapPair          <-  Expression  ':'  LxCont  Expression <expectedValue!>  " + _NL +
"  LitMap           <-  ( '{'  LxCont  ( MapPair  ( ','  LxCont  MapPair ) *  ( ','  LxCont ) ? ) ?  '}' <expectedClosingBrace!> ) {litMap}  LxSep  " + _NL +
"                                                                                           " + _NL +
"                                                                                           " + _NL +
"  ExpSimple        <-  LitNull  /  LitTrue  /  LitFalse  /  LitNumeral  /  LitString  /  LitList  /  LitMap  /  Identifier  /  ExpParens  /  " + _NL +
"                       %if features.beheadedFunctions then%                        " + _NL +
"                           (                                                       " + _NL +
"                           %if befBegin then%                                      " + _NL +
"                               KeyFunction <cannotStartTwoFunctions>               " + _NL +
"                           %else%                                                  " + _NL +
"                               KeyFunction                                         " + _NL +
"                           %end if%                                                " + _NL +
"                           LxSep  FuncArgList ) {befHead}  (+befBegin)  LxSep      " + _NL +
"                       %else%                                                      " + _NL +
"                           AlwaysFail                                              " + _NL +
"                       %end if%                                                    " + _NL +
"                                                                                   " + _NL +
"                                                                                   " + _NL +
"  OpMulDivMod      <-  '*'  /  '/'  ! '/'  /  '%'                                  " + _NL +
"  OpAddSub         <-  '+'  /  '-'                                                 " + _NL +
"  OpCompare        <-  '=='  /  '!='  /  '>'  /  '<'  /  '>='  /  '<='             " + _NL +
"  OpAssign         <-  '='  /  '+='  /  '-='  /  '*='  /  '/='  /  '%='  /  '^='   " + _NL +
"                                                                                   " + _NL +
"                                                                                   " + _NL +
"  _OpIndex         <-  ( '['  LxCont  Expression <expectedKey!>  ']' <expectedClosingBracket!> ) {_opIndex}  LxSep  " + _NL +
"  _OpSlice         <-  ( '['  LxCont  Expression {from:0} ?  ':'  LxCont  Expression {to:0} ?  ']' <expectedClosingBracket!> ) {_opSlice}  LxSep  " + _NL +
"  _OpDot           <-  ( '.'  LxCont  Identifier <expectedIdentifier!> ) {_opDot}  LxSep                               " + _NL +
"  _OpCall          <-  ( '('  LxCont  ( Expression  ( ','  LxCont  Expression <expectedCallArg!> ) * ) ?  ')' <expectedClosingParen!> ) {_opCall}  LxSep  " + _NL +
"  ExpAccess        <-  ( ExpSimple  ( _OpIndex <noPrecedingSpaces>  /  _OpSlice  /  _OpDot  /  _OpCall ) * ) {expAccess}                   " + _NL +
"                                                                                   " + _NL +
"                                                                                   " + _NL +
"  ExpAddress       <-  ( ( '@'    {op:}  LxCont ) ?  ExpAccess )    {expLeftOp}                                           " + _NL +
"  ExpPower         <-  ( ExpAddress     ( '^' {}          LxCont  ExpAddress     <expectedOperand!> ) * ) {expBinOp}    " + _NL +
"  ExpNew           <-  ( ( KeyNew {op:}  LxCont ) ?  ExpPower )  {expLeftOp}                                           " + _NL +
"  ExpUminus        <-  ( ( '-'    {op:}  LxCont ) ?  ExpNew )      {expLeftOp}                                           " + _NL +
"  ExpMulDivMod     <-  ( ExpUminus     ( OpMulDivMod {}  LxCont  ExpUminus     <expectedOperand!> ) * ) {expBinOp}    " + _NL +
"  ExpAddSub        <-  ( ExpMulDivMod  ( OpAddSub {}     LxCont  ExpMulDivMod  <expectedOperand!> ) * ) {expBinOp}    " + _NL +
"  ExpCompare       <-  ( ExpAddSub     ( OpCompare {}    LxCont  ExpAddSub     <expectedOperand!> ) * ) {expCompare}  " + _NL +
"  ExpIsa           <-  ( ExpCompare    ( KeyIsa {}       LxCont  ExpCompare    <expectedType!>    ) * ) {expBinOp}    " + _NL +
"  ExpNot           <-  ( ( KeyNot {op:}  LxCont ) ?  ExpIsa    )   {expLeftOp}                                           " + _NL +
"  ExpAnd           <-  ( ExpNot        ( KeyAnd {}       LxCont  ExpNot        <expectedOperand!> ) * ) {expBinOp}    " + _NL +
"  ExpOr            <-  ( ExpAnd        ( KeyOr {}        LxCont  ExpAnd        <expectedOperand!> ) * ) {expBinOp}    " + _NL +
"  Expression       <-  ExpOr                                                                                             " + _NL +
"                                                                                   " + _NL +
"                                                                                   " + _NL +
"  FuncCont         <-  LxSep  ( ! . ) <reportContFunction> ?  StSep <expectedStatementSeparator!>  ( ! . ) <reportContFunction> ?  " + _NL +
"  FuncArgDefault   <-  LitNull  /  LitNumeral  /  LitString  " + _NL +
"  FuncArg          <-  ( Identifier  ( '='  LxCont  FuncArgDefault {default:0} ) ? ) {funcArg}  " + _NL +
"  FuncArgList      <-  '('  LxCont  ( FuncArg  ( ','  LxCont  FuncArg ) *  ( ','  LxCont ) ? ) ?  ')'  LxSep  " + _NL +
"  FuncEnd          <-  KeyEnd <expectedEndFunction!>  LxSep  KeyFunction <expectedFunctionAfterEnd!>  " + _NL +
"  FuncDef          <-  ( KeyFunction  LxSep  FuncArgList ?  FuncCont  (-insideLoop)  ( Statement  FuncCont ) *  FuncEnd  (/insideLoop) ) {funcDef}  LxSep  " + _NL +
"                                                                                   " + _NL +
"                                                                                   " + _NL +
"  StmtBreak        <-  KeyBreak <breakInsideLoop> {stmtBreak}  LxSep               " + _NL +
"                                                                                   " + _NL +
"                                                                                   " + _NL +
"  StmtContinue     <-  KeyContinue <continueInsideLoop> {stmtContinue}  LxSep      " + _NL +
"                                                                                   " + _NL +
"                                                                                   " + _NL +
"  StmtReturn       <-  ( KeyReturn  LxSep  ( Expression  /  FuncDef ) ? ) {stmtReturn}  LxSep  " + _NL +
"                                                                                   " + _NL +
"                                                                                   " + _NL +
"  ForCont          <-  LxSep  ( ! . ) <reportContFor> ?  StSep <expectedStatementSeparator!>  ( ! . ) <reportContFor> ?  " + _NL +
"  ForStart         <-  KeyFor  LxSep  Identifier <expectedForVariable!>  KeyIn <expectedIn!>  LxSep  Expression <expectedForExpression!>  ForCont  " + _NL +
"  ForEnd           <-  KeyEnd <expectedEndFor!>  LxSep  KeyFor <expectedForAfterEnd!>  " + _NL +
"  StmtFor          <-  ( ForStart  (+insideLoop)  ( Statement  ForCont ) *  ForEnd  (/insideLoop) ) {stmtFor}  LxSep  " + _NL +
"                                                                                   " + _NL +
"                                                                                   " + _NL +
"  WhileCont        <-  LxSep  ( ! . ) <reportContWhile> ?  StSep <expectedStatementSeparator!>  ( ! . ) <reportContWhile> ?  " + _NL +
"  WhileStart       <-  KeyWhile  LxSep  Expression <expectedCondition!>  WhileCont  " + _NL +
"  WhileEnd         <-  KeyEnd <expectedEndWhile!>  LxSep  KeyWhile <expectedWhileAfterEnd!>  " + _NL +
"  StmtWhile        <-  ( WhileStart  (+insideLoop)  ( Statement  WhileCont ) *  WhileEnd  (/insideLoop) ) {stmtWhile}  LxSep  " + _NL +
"                                                                                   " + _NL +
"                                                                                   " + _NL +
"  IfShortStart     <-  KeyIf  LxSep  Expression <expectedCondition!>  KeyThen <expectedThen!>  LxSep  " + _NL +
"  IfShortInside    <-  Statement <ifShortInside>  " + _NL +
"  IfShortElse      <-  KeyElse  LxSep  IfShortInside  " + _NL +
"  StmtIfShort      <-  ( IfShortStart  IfShortInside  IfShortElse ? ) {stmtIfShort}  LxSep  " + _NL +
"                                                                                   " + _NL +
"                                                                                   " + _NL +
"  IfCont           <-  LxSep  ( ! . ) <reportContIf> ?  StSep <expectedStatementSeparator!>  ( ! . ) <reportContIf> ?  " + _NL +
"  IfStart          <-  KeyIf  LxSep  Expression <expectedCondition!>  KeyThen <expectedThen!>  IfCont  " + _NL +
"  IfInside         <-  ( Statement  IfCont ) *  " + _NL +
"  IfElseIf         <-  KeyElse  LxSep  KeyIf  LxSep  Expression <expectedCondition!>  KeyThen <expectedThen!>  IfCont  IfInside  " + _NL +
"  IfElse           <-  KeyElse {}  IfCont  IfInside  " + _NL +
"  IfEnd            <-  KeyEnd <expectedEndIf!>  LxSep  KeyIf <expectedIfAfterEnd!>  " + _NL +
"  StmtIf           <-  ( IfStart  IfInside  IfElseIf *  IfElse ?  IfEnd ) {stmtIf}  LxSep  " + _NL +
"                                                                                   " + _NL +
"                                                                                   " + _NL +
"  StmtAssign       <-  ( ( Expression  OpAssign {} ) <leftAccess>  LxCont  ( Expression  /  FuncDef ) <expectedExpression!> ) {stmtAssign}  " + _NL +
"                                                                                   " + _NL +
"                                                                                   " + _NL +
"  CallArgList      <-  Expression  ( ','  LxCont  Expression <expectedCallArg!> ) *  (','  LxCont  FuncDef) ?  /  FuncDef  " + _NL +
"  StmtCall         <-  ( Expression <stmtCallFunc>  CallArgList ? ) {stmtCall}     " + _NL +
"                                                                                   " + _NL +
"                                                                                   " + _NL +
"  Statement        <-  %if befBegin then%                                          " + _NL +
"                           ( (/befBegin)  (-insideLoop)  ( Statement  FuncCont ) *  FuncEnd  (/insideLoop) ) {befBody}  LxSep  " + _NL +
"                       %else%                                                          " + _NL +
"                           StmtBreak  /  StmtContinue  /  StmtReturn  /                " + _NL +
"                           StmtFor  /  StmtWhile  /  StmtIfShort  /  StmtIf  /         " + _NL +
"                           StmtAssign  /  StmtCall  /  '' {stmtEmpty}                  " + _NL +
"                       %end if%                                                        " + _NL +
"                                                                                       " + _NL +
"                                                                                       " + _NL +
"  Shebang          <-  %if features.parseShebang then%                                 " + _NL +
"                           ( '#!'  ( ! PhysicalNL  . ) * {shebang:}  PhysicalNL ) ?    " + _NL +
"                       %else%                                                          " + _NL +
"                           ''                                                          " + _NL +
"                       %end if%                                                        " + _NL +
"  Program          :   ( Shebang  [ \t] *  Statement  ( StSep  Statement ) *  Comment ? ) ? {program}  ( ! . ) <couldNotParseEverything!>  " + _NL +
"                                                                                       " + _NL +
"                                                                                       " + _NL +
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
	node.init match.start, match.length, ctx.subject, arg.programName
	return node
end function
grammar.capture "litNull", @capLitNull


// Captures `true` literal.
capLitTrue = function(match, subcaptures, arg, ctx)
	node = new LitTrue
	node.init match.start, match.length, ctx.subject, arg.programName
	return node
end function
grammar.capture "litTrue", @capLitTrue


// Captures `false` literal.
capLitFalse = function(match, subcaptures, arg, ctx)
	node = new LitFalse
	node.init match.start, match.length, ctx.subject, arg.programName
	return node
end function
grammar.capture "litFalse", @capLitFalse


// Captures numerals: 1.23e4.
capLitNumeral = function(match, subcaptures, arg, ctx)
	node = new LitNumeral
	node.init match.start, match.length, ctx.subject, arg.programName
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
	node.init match.start, match.length, ctx.subject, arg.programName
	node.addProperty "text", subcaptures.list[0].replace("""""", """")
	return node
end function
grammar.capture "litString", @capLitString


// Captures list literals: [X, Y, Z].
capLitList = function(match, subcaptures, arg, ctx)
	node = new LitList
	node.init match.start, match.length, ctx.subject, arg.programName
	for cap in subcaptures.list
		node.addProperty "elements", cap
		node.identSet += cap.identSet
	end for
	return node
end function
grammar.capture "litList", @capLitList


// Captures map literals: {X: Y, Z: W}.
capLitMap = function(match, subcaptures, arg, ctx)
	node = new LitMap
	node.init match.start, match.length, ctx.subject, arg.programName
	for i in range(0, subcaptures.list.len - 1, 2)
		key = subcaptures.list[i]
		value = subcaptures.list[i + 1]
		node.addProperty "keys", key
		node.addProperty "values", value
		node.identSet += key.identSet + value.identSet
	end for
	return node
end function
grammar.capture "litMap", @capLitMap


// Captures identifiers: foo.
capIdentifier = function(match, subcaptures, arg, ctx)
	node = new Identifier
	node.init match.start, match.length, ctx.subject, arg.programName
	node.addProperty "name", match.fragment
	node.identSet.push match.fragment
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
	node._callableCandidate = null
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
		_node.init match.start, length, ctx.subject, arg.programName
		_node.addProperty "operands", node
		_node.addProperty "operands", rightOperand
		_node._callableCandidate = node._callableCandidate
		_node.identSet += node.identSet + rightOperand.identSet
		
		if _node._callableCandidate == null and operator == "-" then
			between = ctx.subject[node.start + node.length : rightOperand.start]
			if between.endsWith(" -") then
				_node._callableCandidate = {}
				_node._callableCandidate.node = node
				_node._callableCandidate.length = rightOperand.start - node.start - 1
			end if
		end if
		
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
	_node.init match.start, length, ctx.subject, arg.programName
	_node.addProperty "operands", node
	_node.identSet += node.identSet
	return _node
end function
grammar.capture "expLeftOp", @capExpLeftOp


// Captures comparison chain: X < Y < Z.
capExpCompare = function(match, subcaptures, arg, ctx)
	node = subcaptures.list[0]
	if subcaptures.list.len == 1 then return node
	_node = new OpCompare
	_node.init match.start, match.length, ctx.subject, arg.programName
	_node.addProperty "operands", node
	_node.identSet += node.identSet
	for i in range(1, subcaptures.list.len - 1, 2)
		operator = subcaptures.list[i]
		operand = subcaptures.list[i + 1]
		_node.addProperty "operators", operator
		_node.addProperty "operands", operand
		_node.identSet += operand.identSet
	end for
	_node._callableCandidate = node._callableCandidate
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
			_node.init node.start, length, ctx.subject, arg.programName
			_node.addProperty "operands", node
			_node.addProperty "key", cap.key
			_node._callableCandidate = node._callableCandidate
			_node.identSet += node.identSet + cap.key.identSet
			node = _node
		else if cap.type == "slice" then
			_node = new OpSlice
			_node.init node.start, length, ctx.subject, arg.programName
			_node.addProperty "operands", node
			_node.identSet += node.identSet
			if cap.from != null then
				_node.addProperty "from", cap.from
				_node.identSet += cap.from.identSet
			end if
			if cap.to != null then
				_node.addProperty("to", cap.to)
				_node.identSet += cap.to.identSet
			end if
			_node._callableCandidate = node._callableCandidate
			node = _node
		else if cap.type == "dot" then
			_node = new OpDot
			_node.init node.start, length, ctx.subject, arg.programName
			_node.addProperty "operands", node
			_node.addProperty "name", cap.name
			_node._callableCandidate = node._callableCandidate
			_node.identSet += node.identSet
			node = _node
		else if cap.type == "call" then
			_node = new OpCall
			_node.init node.start, length, ctx.subject, arg.programName
			_node.addProperty "operands", node
			_node.identSet += node.identSet
			for _arg in cap.args
				_node.addProperty "args", _arg
				_node.identSet += _arg.identSet
			end for
			betweenIndex = node.start + node.length
			if ctx.subject[betweenIndex] != "(" then
				_node._callableCandidate = {}
				_node._callableCandidate.node = node
				_node._callableCandidate.length = cap.match.start - node.start
			end if
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
	node.init match.start, 0, ctx.subject, arg.programName
	return node
end function
grammar.capture "stmtEmpty", @capStmtEmpty


// Captures a simple call statement: F X, Y, Z.
capStmtCall = function(match, subcaptures, arg, ctx)
	node = new StmtCall
	node.init match.start, match.length, ctx.subject, arg.programName
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
	node.init match.start, match.length, ctx.subject, arg.programName
	node.addProperty "left", subcaptures.list[0]
	node.addProperty "math", subcaptures.list[1][-2:-1]
	
	//
	right = subcaptures.list[2]
	if right isa LitFunction or right isa _BefHead then
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
	node.init match.start, match.length, ctx.subject, arg.programName
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
	node.init match.start, match.length, ctx.subject, arg.programName
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
	node.init match.start, match.length, ctx.subject, arg.programName
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
	node.init match.start, match.length, ctx.subject, arg.programName
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
	node.init match.start, match.length, ctx.subject, arg.programName
	if subcaptures.list.len > 0 then node.addProperty "expression", subcaptures.list[0]
	return node
end function
grammar.capture "stmtReturn", @capStmtReturn


// Captures a break statement: break.
capStmtBreak = function(match, subcaptures, arg, ctx)
	node = new StmtBreak
	node.init match.start, match.length, ctx.subject, arg.programName
	return node
end function
grammar.capture "stmtBreak", @capStmtBreak


// Captures a continue statement: continue.
capStmtContinue = function(match, subcaptures, arg, ctx)
	node = new StmtContinue
	node.init match.start, match.length, ctx.subject, arg.programName
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
	node.init match.start, match.length, ctx.subject, arg.programName
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
		node[propertyName] = befLiterals[p.id]
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
	node.init match.start, match.length, ctx.subject, arg.programName
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
_BefHead.identSet = {}
_BefHead.isConfusedFunc = true


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
	node.init start, length, ctx.subject, arg.programName
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
	node.isConfusedFunc = head.isConfusedFunc
	arg.befLiterals[head.id] = node
	while subcaptures.list
		subcaptures.list.pop
	end while
	return subcaptures
end function
grammar.capture "befBody", @capBefBody


// Adds a continuation error in the middle of an expression or complex literal.
mtReportContLine = function(match, subcaptures, arg, ctx)
	if match == null then return null
	err = new ContLine
	err.init
	err.line = lineColumn(ctx.subject, match.start).line
	err.tag = "contLine"
	ctx.syntaxErrors.push err
end function
grammar.matchTime "reportContLine", @mtReportContLine


// Adds a continuation error in the middle of a string literal.
mtReportContString = function(match, subcaptures, arg, ctx)
	if match == null then return null
	err = new ContString
	err.init
	err.line = lineColumn(ctx.subject, match.start).line
	err.tag = "contString"
	ctx.syntaxErrors.push err
end function
grammar.matchTime "reportContString", @mtReportContString


// Adds a continuation error in the middle of an if-statement.
mtReportContIf = function(match, subcaptures, arg, ctx)
	if match == null then return null
	err = new ContIf
	err.init
	err.line = lineColumn(ctx.subject, match.start).line
	err.tag = "contIf"
	ctx.syntaxErrors.push err
end function
grammar.matchTime "reportContIf", @mtReportContIf


// Adds a continuation error in the middle of a while-loop.
mtReportContWhile = function(match, subcaptures, arg, ctx)
	if match == null then return null
	err = new ContWhile
	err.init
	err.line = lineColumn(ctx.subject, match.start).line
	err.tag = "contWhile"
	ctx.syntaxErrors.push err
end function
grammar.matchTime "reportContWhile", @mtReportContWhile


// Adds a continuation error in the middle of a for-loop.
mtReportContFor = function(match, subcaptures, arg, ctx)
	if match == null then return null
	err = new ContFor
	err.init
	err.line = lineColumn(ctx.subject, match.start).line
	err.tag = "contFor"
	ctx.syntaxErrors.push err
end function
grammar.matchTime "reportContFor", @mtReportContFor


// Adds a continuation error in the middle of a function definition.
mtReportContFunction = function(match, subcaptures, arg, ctx)
	if match == null then return null
	err = new ContFunction
	err.init
	err.line = lineColumn(ctx.subject, match.start).line
	err.tag = "contFunction"
	ctx.syntaxErrors.push err
end function
grammar.matchTime "reportContFunction", @mtReportContFunction


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
		if _lv isa nodeClass then
			match.capture = function(_,sub,_,_)
				sub.list[0] = _lv
				return sub
			end function
			return match
		end if
	end for
	ctx.addSyntaxError "badLValue", "Bad lvalue: " + str(_lv)
	return null
end function
grammar.matchTime "leftAccess", @mtLeftAccess


// Checks that `X -Y` and `X (Y)` are interpreted as call statements (not operations).
mtStmtCallFunc = function(match, subcaptures, arg, ctx)
	if match == null then return null
	func = subcaptures.list[0]
	
	if func._callableCandidate != null then
		candidateNode = func._callableCandidate.node
		candidateLength = func._callableCandidate.length
		start = candidateNode.start
		length = candidateLength
		fragment = ctx.subject[start : start + length]
		if start != func.start then abort "Impossible candidate for statement's callable: `" + str(candidateNode) + "`"
		m = new peg.Match
		m.init start, length, fragment
		m.capture = function(_,_,_,_)
			return candidateNode
		end function
		return m
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
		ctx.addSyntaxError "breakOutsideLoop", "Break-statement outside of a loop"
		return null
	end if
	return match
end function
grammar.matchTime "breakInsideLoop", @mtBreakInsideLoop


// Checks that a continue statement is inside a loop.
mtContinueInsideLoop = function(match, subcaptures, arg, ctx)
	if match == null then return null
	if not ctx.getFlag(match.start, "insideLoop") then
		ctx.addSyntaxError "continueOutsideLoop", "Continue-statement outside of a loop"
		return null
	end if
	return match
end function
grammar.matchTime "continueInsideLoop", @mtContinueInsideLoop


// Report if more than one beheaded function started in a statement.
mtCannotStartTwoFunctions = function(match, subcaptures, arg, ctx)
	if match == null then return null
	ctx.addSyntaxError "cannotStartTwoFunctions", "Attempted to start a second function on the same line"
	return null
end function
grammar.matchTime "cannotStartTwoFunctions", @mtCannotStartTwoFunctions










//                                _|                        _|                          
//  _|_|    _|      _|    _|_|_|  _|  _|    _|    _|_|_|  _|_|_|_|    _|_|    _|  _|_|  
//_|_|_|_|  _|      _|  _|    _|  _|  _|    _|  _|    _|    _|      _|    _|  _|_|      
//_|          _|  _|    _|    _|  _|  _|    _|  _|    _|    _|      _|    _|  _|        
//  _|_|_|      _|        _|_|_|  _|    _|_|_|    _|_|_|      _|_|    _|_|    _|        


// Frame: ?
Frame = {}
Frame._name = "Frame"
Frame._inited = false
Frame.evaluable = null
Frame.state = null
Frame.parent = null
Frame.recentStepInfo = null
Frame.recentStepResultWrap = null
Frame.catch = null


Frame.init = function(evaluable, state=null, parent=null)
	self._inited = true
	self.evaluable = evaluable
	self.state = state
	self.parent = parent
end function


// setCatch: ?
Frame.setCatch = function(catch)
	if catch isa list then
		self.catch = catch
	else
		self.catch = [catch]
	end if
end function


// catchP: ?
Frame.catchP = function(object)
	if not self.catch then return false
	for type in self.catch
		if @object isa type then return true
	end for
	return false
end function


// formatLines: ?
Frame.formatLines = function(formatterFunc)
	lines = []
	f = self
	while f
		lines.push formatterFunc(f)
		f = f.parent
	end while
	return lines
end function


// _formatForTrace: ?
Frame._formatForTrace = function(frame)
	if frame.evaluable isa ParsedFunction then
		node = frame.evaluable.funcNode
	else
		node = frame.evaluable
	end if
	
	fromLine = node.posFirst.line
	toLine = node.posLast.line
	sourceStr = node._subject[node.start : node.start + node.length].trim.splitLines[0]
	if fromLine != toLine then
		sourceStr += " …"
		where = "lines " + fromLine + "-" + toLine
	else
		where = "line " + fromLine
	end if
	
	programName = node.programName
	if not programName then programName = "(current program)"
	
	comment = null
	if frame.parent and frame.parent.recentStepInfo and frame.parent.evaluable.get("_stepComments") then
		sInfo = frame.parent.recentStepInfo
		sComments = frame.parent.evaluable._stepComments
		if sComments.hasIndex(sInfo.name) then
			humanIndexes = {}
			for kv in sInfo
				value = @kv.value
				if kv.key.lower.indexOf("index") != null then value += 1
				humanIndexes[@kv.key] = @value
			end for
			comment = sComments[sInfo.name].fill(humanIndexes)
		end if
	end if
	
	line_1 = " ↑ " + programName + " " + where
	line_2 = "      " + sourceStr
	if comment then line_2 += "    ←" + comment
	line = line_1.ellideEnd(67) + _NL + line_2.ellideEnd(67)
	return line
end function


// formatTrace: ?
Frame.formatTrace = function
	lines = self.formatLines(@self._formatForTrace)
	return lines.join(_NL)
end function


// FrameEvaluator: ?
FrameEvaluator = {}
FrameEvaluator._name = "FrameEvaluator"
FrameEvaluator._inited = false


FrameEvaluator.init = function
	self._inited = true
end function


FrameEvaluator.evaluateFrameLoop = function(frame)
	if not isInstance(frame, Frame) then abort self._name + ".evaluateFrameLoop expected a Frame, got `" + str(frame) + "`"
	
	while true
		steps = frame.evaluable.steps
		
		if frame.recentStepInfo == null then
			stepName = "_INIT"
		else
			stepName = frame.recentStepInfo.name
		end if
		
		if not steps.hasIndex(stepName) then abort "steps[" + stepName + "] not found"
		
		stepFuncs = steps[stepName]
		wrap = frame.recentStepResultWrap
		if wrap == null then
			instruction = stepFuncs.onClean(frame.evaluable, frame.state, frame.recentStepInfo)
		else if wrap.type == "result" then
			instruction = stepFuncs.onResult(frame.evaluable, frame.state, frame.recentStepInfo, @wrap.result)
		else if wrap.type == "caught" then
			instruction = stepFuncs.onCaught(frame.evaluable, frame.state, frame.recentStepInfo, @wrap.caught, wrap.trace)
		else
			abort "Unfamiliar wrap type `" + wrap.type + "`"
		end if
		if instruction.stepInfo != null then frame.recentStepInfo = instruction.stepInfo
		frame.recentStepResultWrap = null
		
		if instruction isa InstNext then
			
			continue
			
		else if instruction isa InstDone then
			
			if frame.parent == null then
				
				r = {}
				r.type = "result"
				r.result = @instruction.result
				r.frame = frame
				return r
				
			else
				
				parentFrame = frame.parent
				parentFrame.recentStepResultWrap = {}
				parentFrame.recentStepResultWrap.type = "result"
				parentFrame.recentStepResultWrap.result = @instruction.result
				frame = parentFrame
				continue
				
			end if
			
		else if instruction isa InstChild then
			
			frame.setCatch instruction.catch
			
			if instruction.inject then
				state = instruction.inject + {}
			else
				state = null
			end if
			
			childFrame = new Frame
			childFrame.init instruction.child, state, frame
			frame = childFrame
			continue
			
		else if instruction isa InstPause then
			
			r = {}
			r.type = "pause"
			r.frame = frame
			return r
			
		else if instruction isa InstThrow then
			
			caught = false
			f = frame
			while f.parent
				p = f.parent
				
				if p.catchP(@instruction.object) then
					caught = true
					
					p.recentStepResultWrap = {}
					p.recentStepResultWrap.type = "caught"
					p.recentStepResultWrap.caught = @instruction.object
					
					f.parent = null
					p.recentStepResultWrap.trace = frame
					
					break
				end if
				
				f = p
				
			end while
			
			if caught then
				
				frame = p
				continue
				
			else
				
				r = {}
				r.type = "uncaught"
				r.uncaught = @instruction.object
				r.frame = frame
				return r
				
			end if
			
		else
			abort "Unfamiliar instruction object `" + str(instruction) + "`"
		end if
	end while
end function









//                                _|                            _|      
//  _|_|_|    _|_|    _|_|_|    _|_|_|_|    _|_|    _|    _|  _|_|_|_|  
//_|        _|    _|  _|    _|    _|      _|_|_|_|    _|_|      _|      
//_|        _|    _|  _|    _|    _|      _|        _|    _|    _|      
//  _|_|_|    _|_|    _|    _|      _|_|    _|_|_|  _|    _|      _|_|  


// Context: ?
Context = {}
Context._name = "ms.Context"
Context._inited = false
Context.params = null
Context.features = null
Context.namespaces = null
Context.out = null

Context.defaultParams = {}
Context.defaultParams._defaultFeatures = v16
Context.defaultParams.trimSpacesRight = true
Context.defaultParams.programName = null
Context.defaultParams.catchErrors = false
Context.defaultParams.valueOnError = null
Context.defaultParams.valueOnNone = null
Context.defaultParams.valueOnPause = null
Context.defaultParams.cthulhuTrick = true
Context.defaultParams.printWarnings = true
Context.defaultParams.collectWarnings = true
Context.defaultParams.printTrace = true
Context.defaultParams.rawParsedFunctions = false
Context.defaultParams.maxIsaDepth = 20


Context.init = function(m=null)
	self._inited = true
	
	self.params = Context.defaultParams + {}
	
	self.features = self.params._defaultFeatures + {}
	
	self.namespaces = {}
	self.namespaces.intrinsics = intrinsics
	self.namespaces.globals = globals
	self.namespaces.outer = globals
	self.namespaces.locals = {}
	
	self.out = {}
	self.out.parseResult = null
	self.out.type = null
	self.out.error = null
	self.out.needMoreInput = false
	self.out.trace = null
	self.out.result = null
	self.out._return = null
	self.out.frame = null
	self.out.warnings = []
	
	if m then self.updateFrom m
end function


// updateFrom: ?
Context.updateFrom = function(m)
	mParams = m.get("params", {})
	self.params += mParams
	self.features += mParams.get("_defaultFeatures", {}) + m.get("features", {})
	self.namespaces += m.get("namespaces", {})
	catchErrors = self.params.catchErrors
	if refEquals(catchErrors, Error) or catchErrors isa Error then
		catchErrors = [catchErrors]
	end if
	if catchErrors != null and catchErrors != true and catchErrors != false and not catchErrors isa list then
		abort "Unable to set Context.params.catchErrors, strange value: `" + str(catchErrors) + "`"
	end if
	self.params.catchErrors = catchErrors
end function


// assimilateMap: ?
Context.assimilateMap = function(m=null)
	if m == null then m = {}
	if not m isa Context then
		c = new Context
		c.init m
		updateInPlace m, c
	end if
	return m
end function


// ?
Context.catchP = function(error)
	catchErrors = self.params.catchErrors
	if not catchErrors then return false
	if catchErrors == true then return true
	if not catchErrors isa list then abort "Strange context.params.catchErrors = `" + str(catchErrors) + "`"
	for cls in catchErrors
		if refEquals(error, cls) or error isa cls then return true
	end for
	return false
end function


// resolveName: ?
Context.resolveName = function(name, default=null)
	ns = self.namespaces
	for namespace in self.resolveOrder
		value = ns[namespace].get(name, _noVal)
		if not refEquals(@value, _noVal) then
			return @value
		end if
	end for
	return @default
end function


// buildFuncContext: ?
Context.buildFuncContext = function(isConfusedFunc)
	ctx = new Context
	ctx.init self
	ctx.namespaces.locals = {}
	if self.features.confusedFunctions and isConfusedFunc then
		ctx.namespaces.outer = self.namespaces.globals
	else
		ctx.namespaces.outer = self.namespaces.locals
	end if
	return ctx
end function


// reportWarning: ?
Context.reportWarning = function(warning)
	if self.params.printWarnings then print warning.message
	if self.params.collectWarnings then self.out.warnings.push warning
end function










//_|                  _|                                          
//_|_|_|      _|_|    _|  _|_|_|      _|_|    _|  _|_|    _|_|_|  
//_|    _|  _|_|_|_|  _|  _|    _|  _|_|_|_|  _|_|      _|_|      
//_|    _|  _|        _|  _|    _|  _|        _|            _|_|  
//_|    _|    _|_|_|  _|  _|_|_|      _|_|_|  _|        _|_|_|    
//                        _|                                      
//                        _|                                      


// _buildParseError: ?
_buildParseError = function(errors, text)
	messages = []
	for i in errors.indexes
		e = errors[i]
		if e isa Continuation then return e
		if e.get("line") then
			line = e.line
		else
			line = lineColumn(text, e.index).line
		end if
		if e isa peg.SyntaxError then
			if e._message == e.tag then
				msg = _tagToPhrase(e.tag)
			else
				msg = e._message
			end if
			if e.rest then
				rest = "'" + e.rest + "'"
			else
				rest = "EOS"
			end if
			message = msg + ": consumed '" + e.fragment + "', failed before " + rest
		else
			message = e.message
		end if
		messages.push "(" + (i + 1) + ") " + message + " [line " + line + "]"
	end for
	error = new ParseError
	error.init
	error.submessages = messages.join(";  ")
	return error
end function


// _tagToPhrase: ?
_tagToPhrase = function(tag)
	_indexes = [0]
	for i in tag.indexes
		if tag[i].upper == tag[i] then _indexes.push i
	end for
	words = []
	prevIdx = null
	for i in range(_indexes.len - 1, 0, -1)
		idx = _indexes[i]
		if prevIdx != null then
			words.insert 0, tag[idx:prevIdx].lower
		else
			words.insert 0, tag[idx:].lower
		end if
		prevIdx = idx
	end for
	phrase = words.join(" ")
	return phrase[0].upper + phrase[1:]
end function


// _makeParseArg: ?
_makeParseArg = function(features=null, programName=null)
	if features == null then features = {}
	arg = {}
	arg.features = features
	arg.programName = programName
	arg.comments = {}
	arg.befNextId = 1
	arg.befHeadStack = []
	arg.befLiterals = {}
	return arg
end function


// toFuncRef
toFuncRef = function(x, seen=null)
	if seen == null then seen = []
	if refIndexOf(seen, @x) != null then return @x
	if @x == null then return @x
	for t in [number, string, funcRef]
		if safeIsa(0, @x, t) then return @x
	end for
	if safeIsa(0, @x, ParsedFunction) then return x.toFuncRef
	seen.push @x
	if @x isa map then
		for key in indexes(x)
			keyf = toFuncRef(@key, seen)
			valuef = toFuncRef(x[@key], seen)
			if not refEquals(@key, @keyf) then remove x, @key
			x[@keyf] = @valuef
		end for
	else if @x isa list then
		for i in x.indexes
			x[i] = toFuncRef(x[i], seen)
		end for
	end if
	return @x
end function


// safeObjectGet: ?
safeObjectGet = function(maxDepth, object, key, xch)
	value = null
	if @object isa map then
		_xch = {}
		value = safeMapGet(maxDepth, @object, @key, _noVal, _exceeded, _xch)
		
		//
		if not refEquals(_xch.get("strangeIsa", _noVal), _noVal) then
			return safeObjectGet(maxDepth, @_xch.strangeIsa, @key, xch)
		end if
		//
		
		if refEquals(@value, _noVal) then
			_xch = {}
			value = safeMapGet(maxDepth, map, @key, _noVal, _exceeded, _xch)
		end if
		xch.owner = _xch.get("owner")
	else if safeIsa(maxDepth, @key, number) then
		if @object == null then
			xch.error = new UnableToIndexNullError
			xch.error.init
		else if not (@object isa list or @object isa string) then
			xch.error = new UnableToIndexError
			xch.error.init
		else if not(-object.len <= key < object.len) then
			xch.error = new IndexError
			xch.error.init
			xch.error.index = @key
			if @object isa list then
				xch.error.typeName = "list"
			else if @object isa string then
				xch.error.typeName = "string"
			else
				abort "Strange type of `" + str(@object) + "`"
			end if
		else
			value = object[key]
		end if
	else if @object isa number then
		value = safeMapGet(maxDepth, number, @key, _noVal, _exceeded)
	else if @object isa string then
		value = safeMapGet(maxDepth, string, @key, _noVal, _exceeded)
	else if @object isa list then
		value = safeMapGet(maxDepth, list, @key, _noVal, _exceeded)
	else if @object isa funcRef then
		value = safeMapGet(maxDepth, funcRef, @key, _noVal, _exceeded)
	else if @object == null then
		xch.error = new NullLookupError
		xch.error.init
		xch.error.index = str(@key)
	else
		abort "Strange type of `" + str(@object) + "`"
	end if
	return @value
end function










//_|_|_|      _|_|_|  _|  _|_|    _|_|_|    _|_|    
//_|    _|  _|    _|  _|_|      _|_|      _|_|_|_|  
//_|    _|  _|    _|  _|            _|_|  _|        
//_|_|_|      _|_|_|  _|        _|_|_|      _|_|_|  
//_|                                                
//_|                                                


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
	if not text isa string then abort "Unable to parse (not a string): `" + text + "`"
	context = Context.assimilateMap(context)
	arg = _makeParseArg(context.features, context.params.programName)
	if context.params.trimSpacesRight then text = text.trimRight
	pegResult = grammar.parse(text, 0, arg)
	result = new ParseResult
	result.init pegResult, arg
	context.out.parseResult = result
	return result
end function


// parseFile: ?
parseFile = function(fileName, context=null)
	f = file.open(fileName)
	text = f.read()
	f.close
	if context == null then context = {}
	setMissing(context, "params", {})
	setMissing(context.params, "_defaultFeatures", v16File)
	setMissing(context.params, "programName", fileName)
	result = parse(text, context)
	if result.program != null then result.program.addProperty "file", fileName
	return result
end function










//                                _|  
//  _|_|    _|      _|    _|_|_|  _|  
//_|_|_|_|  _|      _|  _|    _|  _|  
//_|          _|  _|    _|    _|  _|  
//  _|_|_|      _|        _|_|_|  _|  


// eval: ?
eval = function(evaluable, context=null)
	context = Context.assimilateMap(context)
	
	if evaluable isa string then
		res = parse(evaluable, context)
		if res.program == null then
			
			error = _buildParseError(res.errors, evaluable)
			if not context.catchP(error) then abort error.message
			context.out.type = "error"
			context.out.error = error
			context.out.needMoreInput = error isa Continuation
			if @context.params.valueOnError isa funcRef then
				return context.params.valueOnError(error, null)
			else
				return context.params.valueOnError
			end if
			
		end if
		evaluable = res.program
	end if
	
	if evaluable isa SyntaxNode then
		frame = new Frame
		frame.init evaluable, {"context": context}
	else
		frame = evaluable
	end if
	
	if not frame isa Frame then abort "Unable to evaluate (not a string, SyntaxNode, or Frame): `" + str(evaluable) + "`"
	
	evaluator = new FrameEvaluator
	res = evaluator.evaluateFrameLoop(frame)
	
	if res.type == "result" then
		
		rv = @res.result
		if not context.params.rawParsedFunctions then rv = toFuncRef(@rv)
		context.out.type = "result"
		context.out.result = @rv
		if refEquals(@res.result, None) then return context.params.valueOnNone
		return @rv
		
	else if res.type == "pause" then
		
		context.out.type = "pause"
		context.out.frame = res.frame
		if @context.params.valueOnPause isa funcRef then
			return context.params.valueOnPause(res.frame)
		else
			return context.params.valueOnPause
		end if
		
	else if res.type == "uncaught" then
		
		if res.uncaught isa ReturnThrow then
			rv = @res.uncaught.object
			if not context.params.rawParsedFunctions then rv = toFuncRef(@rv)
			context.out.type = "return"
			context.out._return = @rv
			return null
		end if
		
		error = res.uncaught
		
		trace = res.frame.formatTrace
		
		if not context.catchP(error) then
			message = error.message
			if context.params.printTrace then message += _NL + trace
			abort message
		end if
		context.out.type = "error"
		context.out.error = error
		context.out.needMoreInput = false
		context.out.trace = res.frame
		if @context.params.valueOnError isa funcRef then
			return context.params.valueOnError(error, context.out.trace)
		else
			return context.params.valueOnError
		end if
		
	else
		abort "Unfamiliar result type `" + str(res.type) + "`"
	end if
	
end function


// evalFile: ?
evalFile = function(fileName, context=null)
	if context == null then context = {}
	setMissing(context, "params", {})
	setMissing(context.params, "_defaultFeatures", v16File)
	setMissing(context.params, "programName", fileName)
	context = Context.assimilateMap(context)
	
	parseResult = parseFile(fileName, context)
	
	if parseResult.program == null then
		
		f = file.open(fileName)
		text = f.read
		f.close
		
		error = _buildParseError(parseResult.errors, text)
		if not context.catchP(error) then abort error.message
		context.out.type = "error"
		context.out.error = error
		context.out.needMoreInput = error isa Continuation
		return null
		
	end if
	
	eval(parseResult.program, context)
	
	if context.out.type == "result" then
		return context.namespaces.locals
	else if context.out.type == "return" then
		return @context.out._return
	else
		return null
	end if
end function
