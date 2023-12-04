import "qa"

//
if not globals.hasIndex("ms") then
	import "ms"
	globals.ms = ms
end if
//


_NL = ms._NL


testCatchP = function
	c = ms.Context.assimilateMap
	qa.assertEqual c.catchP(ms.Error), false
	qa.assertEqual c.catchP(ms.Continuation), false
	qa.assertEqual c.catchP(ms.ContIf), false
	qa.assertEqual c.catchP(ms.ParseError), false
	
	c = ms.Context.assimilateMap({"params": {"catchErrors": false}})
	qa.assertEqual c.catchP(ms.Error), false
	qa.assertEqual c.catchP(ms.Continuation), false
	qa.assertEqual c.catchP(ms.ContIf), false
	qa.assertEqual c.catchP(ms.ParseError), false
	
	c = ms.Context.assimilateMap({"params": {"catchErrors": true}})
	qa.assertEqual c.catchP(ms.Error), true
	qa.assertEqual c.catchP(ms.Continuation), true
	qa.assertEqual c.catchP(ms.ContIf), true
	qa.assertEqual c.catchP(ms.ParseError), true
	
	c = ms.Context.assimilateMap({"params": {"catchErrors": ms.Error}})
	qa.assertEqual c.catchP(ms.Error), true
	qa.assertEqual c.catchP(ms.Continuation), true
	qa.assertEqual c.catchP(ms.ContIf), true
	qa.assertEqual c.catchP(ms.ParseError), true
	
	c = ms.Context.assimilateMap({"params": {"catchErrors": ms.Continuation}})
	qa.assertEqual c.catchP(ms.Error), false
	qa.assertEqual c.catchP(ms.Continuation), true
	qa.assertEqual c.catchP(ms.ContIf), true
	qa.assertEqual c.catchP(ms.ParseError), false
	
	c = ms.Context.assimilateMap({"params": {"catchErrors": ms.ContIf}})
	qa.assertEqual c.catchP(ms.Error), false
	qa.assertEqual c.catchP(ms.Continuation), false
	qa.assertEqual c.catchP(ms.ContIf), true
	qa.assertEqual c.catchP(ms.ParseError), false
	
	c = ms.Context.assimilateMap({"params": {"catchErrors": ms.ParseError}})
	qa.assertEqual c.catchP(ms.Error), false
	qa.assertEqual c.catchP(ms.Continuation), true
	qa.assertEqual c.catchP(ms.ContIf), true
	qa.assertEqual c.catchP(ms.ParseError), true
	
	c = ms.Context.assimilateMap({"params": {"catchErrors": []}})
	qa.assertEqual c.catchP(ms.Error), false
	qa.assertEqual c.catchP(ms.Continuation), false
	qa.assertEqual c.catchP(ms.ContIf), false
	qa.assertEqual c.catchP(ms.ParseError), false
	
	c = ms.Context.assimilateMap({"params": {"catchErrors": [ms.ParseError]}})
	qa.assertEqual c.catchP(ms.Error), false
	qa.assertEqual c.catchP(ms.Continuation), true
	qa.assertEqual c.catchP(ms.ContIf), true
	qa.assertEqual c.catchP(ms.ParseError), true
	
	c = ms.Context.assimilateMap({"params": {"catchErrors": [ms.ParseError, ms.ContIf]}})
	qa.assertEqual c.catchP(ms.Error), false
	qa.assertEqual c.catchP(ms.Continuation), true
	qa.assertEqual c.catchP(ms.ContIf), true
	qa.assertEqual c.catchP(ms.ParseError), true
	
	c = ms.Context.assimilateMap({"params": {"catchErrors": [ms.MaxArgsExceededError]}})
	qa.assertEqual c.catchP(ms.Error), false
	qa.assertEqual c.catchP(ms.Continuation), false
	qa.assertEqual c.catchP(ms.ContIf), false
	qa.assertEqual c.catchP(ms.ParseError), false
end function
