import "qa"

//
if not globals.hasIndex("ms") then
	import "ms"
	globals.ms = ms
end if
//


_NL = ms._NL


testIdentSet = function
	exp = ms.parse("A").program.statements[0].callable
	qa.assertEqual exp isa ms.Identifier, true
	qa.assertEqual exp.identSet, {"A": true}
	
	exp = ms.parse("[A, B, C]").program.statements[0].callable
	qa.assertEqual exp isa ms.LitList, true
	qa.assertEqual exp.identSet, {"A": true, "B": true, "C": true}
	
	exp = ms.parse("{A: B, C: D}").program.statements[0].callable
	qa.assertEqual exp isa ms.LitMap, true
	qa.assertEqual exp.identSet, {"A": true, "B": true, "C": true, "D": true}
	
	exp = ms.parse("A and B").program.statements[0].callable
	qa.assertEqual exp isa ms.OpAnd, true
	qa.assertEqual exp.identSet, {"A": true, "B": true}
	
	exp = ms.parse("new A").program.statements[0].callable
	qa.assertEqual exp isa ms.OpNew, true
	qa.assertEqual exp.identSet, {"A": true}
	
	exp = ms.parse("A > B >= C").program.statements[0].callable
	qa.assertEqual exp isa ms.OpCompare, true
	qa.assertEqual exp.identSet, {"A": true, "B": true, "C": true}
	
	exp = ms.parse("A[ B ]").program.statements[0].callable
	qa.assertEqual exp isa ms.OpIndex, true
	qa.assertEqual exp.identSet, {"A": true, "B": true}
	
	exp = ms.parse("A[ B : C ]").program.statements[0].callable
	qa.assertEqual exp isa ms.OpSlice, true
	qa.assertEqual exp.identSet, {"A": true, "B": true, "C": true}
	
	exp = ms.parse("A.B").program.statements[0].callable
	qa.assertEqual exp isa ms.OpDot, true
	qa.assertEqual exp.identSet, {"A": true}
	
	exp = ms.parse("A(B, C)").program.statements[0].callable
	qa.assertEqual exp isa ms.OpCall, true
	qa.assertEqual exp.identSet, {"A": true, "B": true, "C": true}
end function
