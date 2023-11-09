import "grfon"


// _toPath: Substitutes `/` in a string for the platform specific path separator.
_toPath = function(p)
	if p.indexOf("/") != null then p = p.split("/").join(file.child)
	return p
end function


// _import: Imports and returns a module.
_import = function(moduleName)
	import moduleName
	return locals[moduleName]
end function


// _extendImports: Makes modules in `dirs` importable.
_extendImports = function(dirs)
	if env.hasIndex("importPaths") then
		env.importPaths += dirs + ["lib"]
	else
		env.MS_IMPORT_PATH += ":" + (dirs + ["lib"]).join(":")
	end if
end function


// parseCmd: Returns cmd line arguments and options.
parseCmd = function
	cl = {}
	cl.program = null
	cl.args = []
	cl.opts = {}
	if env.hasIndex("cmdLineArgs") then
		allArgs = env.cmdLineArgs
	else
		allArgs = shellArgs
	end if
	cl.program = allArgs.pull
	skipNext = false
	for i in allArgs.indexes
		if skipNext then
			skipNext = false
			continue
		end if
		argKey = allArgs[i]
		argValue = allArgs[i + 1 : i + 2]
		if argKey[0] != "-" then
			cl.args.push argKey
		else if argValue.len == 0 or argValue[0][0] == "-" then
			cl.opts[argKey[1:]] = true
		else
			cl.opts[argKey[1:]] = argValue[0]
			skipNext = true
		end if
	end for
	return cl
end function


// loadDirs: Reads a list of directories with modules/tests from `dirs.txt` (if present).
loadDirs = function
	if file.exists("dirs.txt") then
		dirs = file.readLines("dirs.txt")
	else
		dirs = ["tests/"]
	end if
	for i in range(dirs.len - 1, 0, -1)
		if dirs[i] == "" then dirs.remove i
	end for
	return dirs
end function


// collectTestFuncs: Imports a file `f` and returns the list of `test*` functions.
collectTestFuncs = function(f, testNames)
	module = _import(file.name(f) - ".ms")
	funcs = []
	for kv in module
		if kv.key[:4] != "test" then continue
		if testNames.len != 0 and testNames.indexOf(kv.key) == null then continue
		funcs.push @kv.value
	end for
	return funcs
end function


// runTestsInFile: Finds all test functions inside module `f` and executes them.
runTestsInFile = function(f, testNames)
	funcs = collectTestFuncs(f, testNames)
	if funcs.len == 0 then return 0
	print "  " + f + " ", ""
	nTests = 0
	for func in funcs
		func
		nTests += 1
		print ".", ""
		
		//
		yield
		//
		
	end for
	print nTests
	return nTests
end function


// runTestsInDir: Executes tests in the directory `d`.
runTestsInDir = function(d, testNames)
	if not file.exists(d) then
		print "no such dir `" + d + "`"
		return 0
	end if
	print d
	nTests = 0
	for f in file.children(d)
		if f[-3:] != ".ms" then continue
		nTests += runTestsInFile(file.child(d, f), testNames)
	end for
	print
	return nTests
end function


// runTests: Runs all tests with names `testNames` inside directories `dirs`.
runTests = function(testNames=null, dirs=null)
	if testNames == null then testNames = []
	if dirs == null then dirs = loadDirs
	if testNames.len != 0 then
		print "test names:"
		for n in testNames
			print " " + n
		end for
		print
	end if
	print "dirs:"
	for d in dirs
		print " " + d
	end for
	print
	_extendImports dirs
	nTests = 0
	for d in dirs
		nTests += runTestsInDir(_toPath(d), testNames)
	end for
	print nTests + " OK"
end function


// main: Reads test names (if any) from command-line args and executes them (or all tests).
main = function
	cl = parseCmd
	if cl.opts.hasIndex("n") then
		print "-n (successfully did nothing)"
		exit
	end if
	testNames = cl.args
	runTests testNames, loadDirs
end function


if refEquals(locals, globals) then main

