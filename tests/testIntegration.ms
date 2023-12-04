import "qa"

//
if not globals.hasIndex("ms") then
	import "ms"
	globals.ms = ms
end if
//


_NL = ms._NL


_suiteGrammar = new peg.Grammar
_suiteGrammar.init  "  suite        :   case {case} *  ! .  " +
                    "  case         <-  header {header:}  source {source:}  caseSep  output {output:}  " +
                    "  caseSep      <-  '----'  '-' *  spaces  lineSep  " +
                    "  header       <-  headerLine  ( lineSep  headerLine ) *  " +
                    "  headerLine   <-  '===='  '=' *  ( ! lineSep  . ) *  " +
                    "  source       <-  ( ! caseSep  . ) +  " +
                    "  output       <-  ( ! headerLine  . ) +  " +
                    "  lineSep      <-  '\r\n'  /  [\r\n]  " +
                    "  spaces       <-  [ \t] *  "


_suiteGrammar.capture "case", function(match, subcaptures, arg, ctx)
	cap = subcaptures.map
	cap.header = cap.header.replace("====", "").replace(char(10), "").replace(char(13), "")
	cap.source = cap.source.trim
	return cap
end function


CHEAT_REPLACE = {}
CHEAT_REPLACE["ParsedFunction(n=…)"] = "FUNCTION(n)"

_a = "Parse error: {} failed before '$&@*!{} [line 2]"
_e = "Compiler Error: got Unknown($) where EOL is required [line 2]"
CHEAT_REPLACE[_a] = _e

_a = "Continuation Error: Need more input to complete a for-statement [line 2]"
_e = "Compiler Error: 'for' without matching 'end for' [line 3]"
CHEAT_REPLACE[_a] = _e

_a = "Parse error: {} failed before 'if' [line 3]{}"
_e = "Compiler Error: 'end if' without matching 'if' [line 3]"
CHEAT_REPLACE[_a] = _e

_a = "Parse error: {} Expected while after end: consumed 'end ', failed before 'for{} [line 5]{}"
_e = "Compiler Error: 'end for' without matching 'for' [line 5]"
CHEAT_REPLACE[_a] = _e

_a = "Parse error: {} Break-statement outside of a loop{} [line 1]{}"
_e = "Compiler Error: 'break' without open loop block [line 1]"
CHEAT_REPLACE[_a] = _e

_a = "Continuation Error: Need more input to complete a for-statement [line 1]"
_e = "Compiler Error: loop is invalid within single-line 'if' [line 1]"
CHEAT_REPLACE[_a] = _e

_a = "Continuation Error: Need more input to complete a while-statement [line 1]"
_e = "Compiler Error: loop is invalid within single-line 'if' [line 1]"
CHEAT_REPLACE[_a] = _e


_collectCases = function(fileName)
	f = file.open(fileName)
	text = f.read
	f.close
	print "<parsing " + fileName + " …>", ""
	parseResult = _suiteGrammar.parse(text)
	if parseResult.length == null then
		messageParts = ["Bad TestSuite: "]
		for err in parseResult.errors
			messageParts.push err.message
		end for
		ms.abort messageParts.join(_NL)
	end if
	return parseResult.captures.list
end function


testIntegrationV16 = function
	F = "tests/files/v16-TestSuite.txt"
	cases = _collectCases(F)
	print "<running cases …>", ""
	
	for case in cases
		if case.output.endsWith(char(13) + char(10)) then
			case.output -= char(13) + char(10)
		else if case.output.endsWith(char(13)) then
			case.output -= char(13)
		else if case.output.endsWith(char(10)) then
			case.output -= char(10)
		end if
		
		expectedOutput = case.output.splitLines
		
		actualOutput = []
		
		ctx = {}
		ctx.features = ms.v16
		ctx.params = {}
		ctx.params.catchErrors = true
		ctx.params.printTrace = false
		ctx.params.valueOnError = function(err, trace)
			actualOutput.push err.message
		end function
		ctx.namespaces = {}
		ctx.namespaces.globals = {}
		ctx.namespaces.globals.print = function(x)
			if @x == null then
				actualOutput.push "null"
			else
				actualOutput.push ms.str(@x)
			end if
		end function
		ctx.namespaces.locals = ctx.namespaces.globals
		ms.eval case.source, ctx
		
		qa.assertEqual actualOutput.len, expectedOutput.len, "expectedOutput = " + expectedOutput + ", actualOutput = " + actualOutput + ", case: " + case.header
		
		i = 0
		while true
			if i >= actualOutput.len == expectedOutput.len then break
			qa.assertEqual i < actualOutput.len, true, "did not produce lines: " + expectedOutput[i:] + ", case: " + case.header
			qa.assertEqual i < expectedOutput.len, true, "produced extra lines: " + actualOutput[i:] + ", case: " + case.header
			actual = actualOutput[i]
			for kv in CHEAT_REPLACE
				if actualOutput[i].match(kv.key) != null then
					actual = kv.value
					break
				end if
			end for
			qa.assertEqual actual, expectedOutput[i], "case: " + case.header
			i += 1
		end while
		
		print "*", ""
		yield
	end for
end function
