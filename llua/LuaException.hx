package llua;

import llua.State;
import haxe.Exception;

class LuaException extends Exception {
	public var error_code:Int = 0;
    
	public function new(message:String, ?previous:Exception, ?code:Int = 0) {
		error_code = code != null ? code : 0;
		super(message, previous);
	}
    
	public static function ifErrorThrow(l:State, status:Int) {
		if(status == 0) return;
        
		var errorMsg:String = switch(status) {
			case Lua.LUA_ERRRUN: 
				var msg:String = "Lua Runtime Error: UNKNOWN ERROR?";
				if (l != null) {
					try {
						// ensure there is actually an item on the stack to read.
						if (Lua.gettop(l) > 0) {
							var str:String = Lua.tostring(l, -1);
							if (str != null && str != "") {
								msg = str;
								Lua.pop(l, 1); // clean up the error message from the stack.
							}
						}
					} catch(e:Dynamic) {
						msg = "Lua Runtime Error: Failed to read error message from stack (" + Std.string(e) + ")";
					}
				}
				msg;
			case Lua.LUA_ERRMEM: "luavm ran out of memory";
			case Lua.LUA_ERRERR: "LUA_ERRERR";
			default: "Lua Error: " + status;
		};
        
		var exception = new LuaException(errorMsg, null, status);
        
		#if android
		// ensure the trace function handles potential null strings.
		var logMessage:String = exception.message != null ? exception.message : "Unknown error message";
		#if hx_trace
		untyped __cpp__("hx_trace({0})", logMessage);
		#else
		trace("LUA EXCEPTION CAUGHT: " + logMessage);
		#end
		#else
		throw exception;
		#end
	}
}
