package llua;

import llua.State;
import llua.Convert;
import llua.Lua;
import llua.LuaL;

@:keep
@:unreflective
#if cpp
@:headerClassCode("inline void __construct(Dynamic lua, Dynamic ref) {}")
#end
class LuaCallback {

    private var l:State;
    public var ref(default,null):Int;

    public function new(lua:State, ref:Int) {
        this.l = lua;
        this.ref = ref;
    }

    public function call(args:Array<Dynamic> = null):Void {

        // stop if the Lua state is invalid
        if (l == null) return;

        // stop if the reference index is invalid to prevent crashes
        if (ref == -1 || ref == 0) return;

        // push the stored function reference onto the stack
        Lua.rawgeti(l, Lua.LUA_REGISTRYINDEX, ref);

        // check if the pushed object is a valid function
        if (!Lua.isfunction(l, -1)) {
            Lua.pop(l, 1);
            return;
        }

        // initialize empty array if arguments are null
        if (args == null) args = [];

        // push all arguments to the Lua stack
        for (arg in args)
            Convert.toLua(l, arg);

        // execute the function
        var status:Int = Lua.pcall(l, args.length, 0, 0);

        // process errors if the execution failed
        if (status != Lua.LUA_OK) {

            var err:String = "";

            // make sure the stack has an element before extracting the error string
            if (Lua.gettop(l) > 0 && Lua.type(l, -1) != Lua.LUA_TNIL) {
                try {
                    err = Lua.tostring(l, -1);
                } catch(e:Dynamic) {
                    err = "Failed to parse error message";
                }
            }

            // remove the error object from the stack
            if (Lua.gettop(l) > 0) {
                Lua.pop(l, 1);
            }

            // fallback to generic message if error string is empty
            if (err == "" || err == null) {
                switch(status) {
                    case Lua.LUA_ERRRUN: err = "Runtime Error";
                    case Lua.LUA_ERRMEM: err = "Memory Allocation Error";
                    case Lua.LUA_ERRERR: err = "Critical Error";
                    default: err = "Unknown Error: " + status;
                }
            }

            // trace logging
            #if android
            var finalMsg:String = "LuaCallback Error: " + (err != null ? err : "Unknown");
            #if hx_trace
            untyped __cpp__("hx_trace({0})", finalMsg);
            #else
            trace(finalMsg);
            #end
            #else
            trace("LuaCallback Error: " + err);
            #end
        }
    }

    public function dispose():Void {
        // unreference and clean up.
        if (l != null && ref != -1 && ref != 0) {
            try {
                LuaL.unref(l, Lua.LUA_REGISTRYINDEX, ref);
            } catch(e:Dynamic) {}
            ref = -1;
        }
    }

}
