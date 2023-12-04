# ms.ms

**ms.ms** is a [MiniScript](https://miniscript.org/) parser and evaluator written in MiniScript.

The library depends on [peg.ms](https://github.com/marcgurevitx/peg-ms).

```
// Make sure 'peg.ms' and 'ms.ms' are in the import path

import "ms"             // <- takes long time, sorry

ms.eval "print 42"      // prints '42'


p = ms.parse("print 42")
print ms.str(p.program)
// prints:
// [Program 1:1 1:8]
//  file:
//  shebang:
//  statements.0
//   [StmtCall 1:1 1:8]
//    callable:
//     [Identifier 1:1 1:5] name = "print"
//    args.0
//     [LitNumeral 1:7 1:8] int = "42", fract = null, eSign = null, exp = null, val = 42


x = ms.eval("42 + 1")
print x                 // prints '43'


ms.eval "f = function(x) ; return x + 1 ; end function ; print f(42)"   // prints '43'


f = ms.eval("f = function(x) ; return x + 1 ; end function ;  @f")
print f(42)             // prints '43'


// Pass variables into 'eval'
ctx = {}
ctx.namespaces = {}
ctx.namespaces.locals = {}
ctx.namespaces.locals.x = 100
ms.eval "print x + 1", ctx      // prints '101'


// Catch errors in 'eval'
ctx = {}
ctx.params = {}
ctx.params.catchErrors = true
ms.eval "print xxx", ctx
print ctx.out.type              // prints 'error'
print ctx.out.error.message
// prints 'Runtime Error: Undefined Identifier: 'xxx' is unknown in this context [line 1]'


// Detect if more input is needed (for REPLs)
ctx = {}
ctx.params = {}
ctx.params.catchErrors = ms.Continuation
ms.eval "print 42 +", ctx
print ctx.out.type              // prints 'error'
print ctx.out.error isa ms.Continuation     // prints '1'
print ctx.out.error.message
// prints 'Continuation Error: Need more input to complete an expression or literal [line 1]'

```
