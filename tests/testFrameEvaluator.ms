import "qa"

//
if not globals.hasIndex("ms") then
	import "ms"
	globals.ms = ms
end if
//


_NL = ms._NL


testFrameEvaluatorBasicDone = function
	evaluator = new ms.FrameEvaluator
	evaluator.init
	
	e = {}
	e.steps = {}
	e.steps._INIT = {}
	e.steps._INIT.onClean = function(evaluable, state, stepInfo)
		inst = new ms.InstDone
		inst.result = 42
		return inst
	end function
	
	frame = new ms.Frame
	frame.init e
	
	res = evaluator.evaluateFrameLoop(frame)
	qa.assertEqual res.type, "result"
	qa.assertEqual res.result, 42
	qa.assertEqual refEquals(res.frame, frame), true
end function


testFrameEvaluatorBasicDoneFuncRef = function
	evaluator = new ms.FrameEvaluator
	evaluator.init
	
	i = 0
	f = function ; outer.i += 1 ; return i ; end function
	
	e = {}
	e.steps = {}
	e.steps._INIT = {}
	e.steps._INIT.onClean = function(evaluable, state, stepInfo)
		inst = new ms.InstDone
		inst.result = @f
		return inst
	end function
	
	frame = new ms.Frame
	frame.init e
	
	res = evaluator.evaluateFrameLoop(frame)
	qa.assertEqual res.type, "result"
	qa.assertEqual @res.result == @f, true
	qa.assertEqual refEquals(res.frame, frame), true
end function


testFrameEvaluatorBasicNext = function
	evaluator = new ms.FrameEvaluator
	evaluator.init
	
	e = {}
	e.steps = {}
	e.steps._INIT = {}
	e.steps._INIT.onClean = function(evaluable, state, stepInfo)
		inst = new ms.InstNext
		inst.stepInfo = {}
		inst.stepInfo.name = "theNextStep"
		return inst
	end function
	e.steps.theNextStep = {}
	e.steps.theNextStep.onClean = function(evaluable, state, stepInfo)
		inst = new ms.InstDone
		inst.result = 42
		return inst
	end function
	
	frame = new ms.Frame
	frame.init e
	
	res = evaluator.evaluateFrameLoop(frame)
	qa.assertEqual res.type, "result"
	qa.assertEqual res.result, 42
	qa.assertEqual refEquals(res.frame, frame), true
end function


testFrameEvaluatorBasicPause = function
	evaluator = new ms.FrameEvaluator
	evaluator.init
	
	e = {}
	e.steps = {}
	e.steps._INIT = {}
	e.steps._INIT.onClean = function(evaluable, state, stepInfo)
		inst = new ms.InstPause
		return inst
	end function
	
	frame = new ms.Frame
	frame.init e
	
	res = evaluator.evaluateFrameLoop(frame)
	qa.assertEqual res.type, "pause"
	qa.assertEqual refEquals(res.frame, frame), true
end function


testFrameEvaluatorBasicUncaught = function
	evaluator = new ms.FrameEvaluator
	evaluator.init
	
	e = {}
	e.steps = {}
	e.steps._INIT = {}
	e.steps._INIT.onClean = function(evaluable, state, stepInfo)
		inst = new ms.InstThrow
		inst.object = 42
		return inst
	end function
	
	frame = new ms.Frame
	frame.init e
	
	res = evaluator.evaluateFrameLoop(frame)
	qa.assertEqual res.type, "uncaught"
	qa.assertEqual res.uncaught, 42
	qa.assertEqual refEquals(res.frame, frame), true
end function


testFrameEvaluatorBasicUncaughtFuncRef = function
	evaluator = new ms.FrameEvaluator
	evaluator.init
	
	i = 0
	f = function ; outer.i += 1 ; return i ; end function
	
	e = {}
	e.steps = {}
	e.steps._INIT = {}
	e.steps._INIT.onClean = function(evaluable, state, stepInfo)
		inst = new ms.InstThrow
		inst.object = @f
		return inst
	end function
	
	frame = new ms.Frame
	frame.init e
	
	res = evaluator.evaluateFrameLoop(frame)
	qa.assertEqual res.type, "uncaught"
	qa.assertEqual @res.uncaught == @f, true
	qa.assertEqual refEquals(res.frame, frame), true
end function


testFrameEvaluatorChildDone = function
	evaluator = new ms.FrameEvaluator
	evaluator.init
	
	e = {}
	e.steps = {}
	e.steps._INIT = {}
	e.steps._INIT.onClean = function(evaluable, state, stepInfo)
		inst = new ms.InstChild
		inst.child = e2
		inst.stepInfo = {"name": "invokedChild"}
		return inst
	end function
	e.steps.invokedChild = {}
	e.steps.invokedChild.onResult = function(evaluable, state, stepInfo, result)
		inst = new ms.InstDone
		inst.result = result + 100
		return inst
	end function
	
	e2 = {}
	e2.steps = {}
	e2.steps._INIT = {}
	e2.steps._INIT.onClean = function(evaluable, state, stepInfo)
		inst = new ms.InstDone
		inst.result = 42
		return inst
	end function
	
	frame = new ms.Frame
	frame.init e, {}
	
	res = evaluator.evaluateFrameLoop(frame)
	qa.assertEqual res.type, "result"
	qa.assertEqual res.result, 142
	qa.assertEqual refEquals(res.frame, frame), true
end function


testFrameEvaluatorChildDoneWithInject = function
	evaluator = new ms.FrameEvaluator
	evaluator.init
	
	e = {}
	e.steps = {}
	e.steps._INIT = {}
	e.steps._INIT.onClean = function(evaluable, state, stepInfo)
		inst = new ms.InstChild
		inst.child = e2
		inst.inject = {"foo": 42}
		inst.stepInfo = {"name": "invokedChild"}
		return inst
	end function
	e.steps.invokedChild = {}
	e.steps.invokedChild.onResult = function(evaluable, state, stepInfo, result)
		inst = new ms.InstDone
		inst.result = result + 100
		return inst
	end function
	
	e2 = {}
	e2.steps = {}
	e2.steps._INIT = {}
	e2.steps._INIT.onClean = function(evaluable, state, stepInfo)
		inst = new ms.InstDone
		inst.result = state.foo
		return inst
	end function
	
	frame = new ms.Frame
	frame.init e, {}
	
	res = evaluator.evaluateFrameLoop(frame)
	qa.assertEqual res.type, "result"
	qa.assertEqual res.result, 142
	qa.assertEqual refEquals(res.frame, frame), true
end function


testFrameEvaluatorChildPause = function
	evaluator = new ms.FrameEvaluator
	evaluator.init
	
	//
	fmt = function(f)
		return f.recentStepInfo.name
	end function
	//
	
	e = {}
	e.steps = {}
	e.steps._INIT = {}
	e.steps._INIT.onClean = function(evaluable, state, stepInfo)
		inst = new ms.InstChild
		inst.child = e2
		inst.stepInfo = {"name": "invokedChild"}
		return inst
	end function
	e.steps.invokedChild = {}
	e.steps.invokedChild.onResult = function(evaluable, state, stepInfo, result)
		inst = new ms.InstDone
		inst.result = result + 100
		return inst
	end function
	
	e2 = {}
	e2.steps = {}
	e2.steps._INIT = {}
	e2.steps._INIT.onClean = function(evaluable, state, stepInfo)
		inst = new ms.InstPause
		inst.stepInfo = {"name": "paused"}
		return inst
	end function
	e2.steps.paused = {}
	e2.steps.paused.onClean = function(evaluable, state, stepInfo)
		inst = new ms.InstDone
		inst.result = 42
		return inst
	end function
	
	frame = new ms.Frame
	frame.init e, {}
	
	res = evaluator.evaluateFrameLoop(frame)
	qa.assertEqual res.type, "pause"
	qa.assertEqual refEquals(res.frame.parent, frame), true
	qa.assertEqual res.frame.formatLines(@fmt), ["paused", "invokedChild"]
	
	res = evaluator.evaluateFrameLoop(res.frame)
	qa.assertEqual res.type, "result"
	qa.assertEqual res.result, 142
	qa.assertEqual refEquals(frame, frame), true
end function


testFrameEvaluatorChildThrow = function
	evaluator = new ms.FrameEvaluator
	evaluator.init
	
	//
	fmt = function(f)
		return f.recentStepInfo.name
	end function
	//
	
	e = {}
	e.steps = {}
	e.steps._INIT = {}
	e.steps._INIT.onClean = function(evaluable, state, stepInfo)
		inst = new ms.InstChild
		inst.child = e2
		inst.stepInfo = {"name": "child_1"}
		return inst
	end function
	
	e2 = {}
	e2.steps = {}
	e2.steps._INIT = {}
	e2.steps._INIT.onClean = function(evaluable, state, stepInfo)
		inst = new ms.InstChild
		inst.child = e3
		inst.stepInfo = {"name": "child_2"}
		return inst
	end function
	
	e3 = {}
	e3.steps = {}
	e3.steps._INIT = {}
	e3.steps._INIT.onClean = function(evaluable, state, stepInfo)
		inst = new ms.InstThrow
		inst.object = 42
		inst.stepInfo = {"name": "throw"}
		return inst
	end function
	
	frame = new ms.Frame
	frame.init e
	
	res = evaluator.evaluateFrameLoop(frame)
	qa.assertEqual res.type, "uncaught"
	qa.assertEqual res.uncaught, 42
	qa.assertEqual refEquals(res.frame.parent.parent, frame), true
	qa.assertEqual res.frame.formatLines(@fmt), ["throw", "child_2", "child_1"]
end function


testFrameEvaluatorCatch = function
	evaluator = new ms.FrameEvaluator
	evaluator.init
	
	//
	fmt = function(f)
		return f.recentStepInfo.name
	end function
	//
	
	e = {}
	e.steps = {}
	e.steps._INIT = {}
	e.steps._INIT.onClean = function(evaluable, state, stepInfo)
		inst = new ms.InstChild
		inst.child = e2
		inst.catch = number
		inst.stepInfo = {"name": "child_1"}
		return inst
	end function
	e.steps.child_1 = {}
	e.steps.child_1.onCaught = function(evaluable, state, stepInfo, caught, trace)
		inst = new ms.InstDone
		inst.result = [caught, trace]
		return inst
	end function
	
	e2 = {}
	e2.steps = {}
	e2.steps._INIT = {}
	e2.steps._INIT.onClean = function(evaluable, state, stepInfo)
		inst = new ms.InstChild
		inst.child = e3
		inst.stepInfo = {"name": "child_2"}
		return inst
	end function
	
	e3 = {}
	e3.steps = {}
	e3.steps._INIT = {}
	e3.steps._INIT.onClean = function(evaluable, state, stepInfo)
		inst = new ms.InstThrow
		inst.object = 42
		inst.stepInfo = {"name": "throw"}
		return inst
	end function
	
	frame = new ms.Frame
	frame.init e
	
	res = evaluator.evaluateFrameLoop(frame)
	qa.assertEqual res.type, "result"
	qa.assertEqual res.result[0], 42
	qa.assertEqual res.result[1].formatLines(@fmt), ["throw", "child_2"]
end function
