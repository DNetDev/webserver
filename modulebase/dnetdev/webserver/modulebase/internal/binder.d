/**
 * Do not override this module
 * 
 * License:
 *     The MIT License (MIT)
 *
 *     Copyright (c) 2015 Richard Andrew Cattermole
 *
 *     Permission is hereby granted, free of charge, to any person obtaining a copy
 *     of this software and associated documentation files (the "Software"), to deal
 *     in the Software without restriction, including without limitation the rights
 *     to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 *     copies of the Software, and to permit persons to whom the Software is
 *     furnished to do so, subject to the following conditions:
 *
 *     The above copyright notice and this permission notice shall be included in all
 *     copies or substantial portions of the Software.
 *
 *     THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *     IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *     FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *     AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *     LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *     OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 *     SOFTWARE.
 */
module dnetdev.webserver.modulebase.internal.binder;

private {
	import std.traits : ReturnType;
	string getMangledName(string func, string mod)() {
		mixin("static import " ~ mod ~ "; alias SYM = " ~ func ~ "; return SYM.mangleof;");
	}
	
	auto getFunctionsReturnType(string func, string mod)() {
		mixin("static import " ~ mod ~ "; alias RETT = ReturnType!(" ~ func ~ "); static if (is(RETT == void)) return; else return ReturnType!(" ~ func ~ ").init;");
	}
}

version(none) {
	/**
	 * Auto calls a global function in the host application.
	 * 
	 * Params:
	 * 		name		=	Name of function to call
	 * 		theModule	=	Name of module function is in
	 * 		RETTYPE		=	The return type for the function
	 * 		T			=	Argument types to call with
	 * 
	 * 		args		=	The arguments to call with
	 * 
	 * Returns:
	 * 		If RETTYPE != void then what ever the value from the function is.
	 */
	RETTYPE callViaHostBind(string name = __FUNCTION__, string theModule = __MODULE__, RETTYPE = typeof(getFunctionsReturnType!(name, theModule)()), T...)(T args) {}
}

version(Windows) {
	import core.sys.windows.windows;
	
	RETTYPE callViaHostBind(string name = __FUNCTION__, string theModule = __MODULE__, RETTYPE = typeof(getFunctionsReturnType!(name, theModule)()), T...)(T args) {
		auto mod = GetModuleHandleA(null);
		string mangled = getMangledName!(name, theModule);
		char* mangledPtr = cast(char*)(mangled ~ "\0").ptr;
		assert(mangledPtr !is null);
		auto addr = GetProcAddress(mod, mangledPtr);
		assert(addr !is null);
		
		RETTYPE function(T) toCall = cast(RETTYPE function(T)) addr;
	
		static if (is(RETTYPE == void)) {
			toCall(args);
		} else {
			return toCall(args);
		}
	}
} else version(Posix) {
	import core.sys.posix.dlfcn;
	
	RETTYPE callViaHostBind(string name = __FUNCTION__, string theModule = __MODULE__, RETTYPE = typeof(getFunctionsReturnType!(name, theModule)()), T...)(T args) {
		auto mod = dlopen(null, 0);
		string mangled = getMangledName!(name, theModule);
		char* mangledPtr = cast(char*)(mangled ~ "\0").ptr;
		assert(mangledPtr !is null);
		auto addr = dlsym(mod, mangledPtr);
		assert(addr !is null);
		
		RETTYPE function(T) toCall = cast(RETTYPE function(T)) addr;
	
		static if (is(RETTYPE == void)) {
			toCall(args);
		} else {
			return toCall(args);
		}
	}
}