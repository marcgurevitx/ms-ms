import "qa"

//
if not globals.hasIndex("ms") then
	import "ms"
	globals.ms = ms
end if
//


_NL = ms._NL


testPropertyNames = function
	qa.assertEqual ms.LitNull.propertyNames,        []
	qa.assertEqual ms.LitTrue.propertyNames,        []
	qa.assertEqual ms.LitFalse.propertyNames,       []
	qa.assertEqual ms.LitNumeral.propertyNames,     ["int", "fract", "eSign", "exp", "val"]
	qa.assertEqual ms.LitString.propertyNames,      ["text"]
	qa.assertEqual ms.LitList.propertyNames,        ["elements"]
	qa.assertEqual ms.LitMap.propertyNames,         ["keys", "values"]
	qa.assertEqual ms.LitFunction.propertyNames,    ["args", "defaults", "statements"]
	qa.assertEqual ms.Identifier.propertyNames,     ["name"]
	qa.assertEqual ms.OpOr.propertyNames,           ["operands"]
	qa.assertEqual ms.OpAnd.propertyNames,          ["operands"]
	qa.assertEqual ms.OpNot.propertyNames,          ["operands"]
	qa.assertEqual ms.OpIsa.propertyNames,          ["operands"]
	qa.assertEqual ms.OpCompare.propertyNames,      ["operands", "operators"]
	qa.assertEqual ms.OpAdd.propertyNames,          ["operands"]
	qa.assertEqual ms.OpSubtract.propertyNames,     ["operands"]
	qa.assertEqual ms.OpMultiply.propertyNames,     ["operands"]
	qa.assertEqual ms.OpDivide.propertyNames,       ["operands"]
	qa.assertEqual ms.OpModulo.propertyNames,       ["operands"]
	qa.assertEqual ms.OpUMinus.propertyNames,       ["operands"]
	qa.assertEqual ms.OpNew.propertyNames,          ["operands"]
	qa.assertEqual ms.OpAddress.propertyNames,      ["operands"]
	qa.assertEqual ms.OpPower.propertyNames,        ["operands"]
	qa.assertEqual ms.OpIndex.propertyNames,        ["operands", "key"]
	qa.assertEqual ms.OpSlice.propertyNames,        ["operands", "from", "to"]
	qa.assertEqual ms.OpDot.propertyNames,          ["operands", "name"]
	qa.assertEqual ms.OpCall.propertyNames,         ["operands", "args"]
	qa.assertEqual ms.StmtEmpty.propertyNames,      []
	qa.assertEqual ms.StmtCall.propertyNames,       ["callable", "args"]
	qa.assertEqual ms.StmtAssign.propertyNames,     ["left", "right", "math"]
	qa.assertEqual ms.StmtIf.propertyNames,         ["conditions", "statements", "elseStatements"]
	qa.assertEqual ms.StmtWhile.propertyNames,      ["condition", "statements"]
	qa.assertEqual ms.StmtFor.propertyNames,        ["var", "expression", "statements"]
	qa.assertEqual ms.StmtReturn.propertyNames,     ["expression"]
	qa.assertEqual ms.StmtBreak.propertyNames,      []
	qa.assertEqual ms.StmtContinue.propertyNames,   []
	qa.assertEqual ms.Program.propertyNames,        ["file", "shebang", "statements"]
end function

