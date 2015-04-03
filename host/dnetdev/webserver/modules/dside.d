/**
 * The MIT License (MIT)
 *
 * Copyright (c) 2015 DNetDev (Richard Andrew Cattermole)
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */
module dnetdev.webserver.modules.dside;
import dnetdev.webserver.modules.defs;

package __gshared {
	string[size_t] indexsForDfuncs;
	WebServerModuleInterface[string] dfuncs;
	string[size_t] dfuncNames;
}

/**
 * Registers a module for usage with the Module loading system.
 */
void registerInternalModule(string mod = __MODULE__)(string name) {
	import std.traits : isFunctionPointer;
	mixin("import theMod = " ~ mod ~ ";");

	dfuncs[mod] = WebServerModuleInterface.init;

	foreach(member; __traits(allMembers, WebServerModuleInterface)) {
		mixin("alias MTYPE = typeof(WebServerModuleInterface." ~ member ~ ");");
		static if (isFunctionPointer!MTYPE) {
			static if (__traits(compiles, {mixin("auto v = &theMod." ~ member ~ ";"); })) {
				enum bindFunc = "dfuncs[mod]." ~ member ~ " = &theMod." ~ member ~ ";";

				static if (__traits(compiles, { mixin(bindFunc); }))
					mixin(bindFunc);
			}
		}
	}

	auto id = indexsForDfuncs.keys.length;
	indexsForDfuncs[id] = mod;
	dfuncNames[id] = name;
}

string[] getInternalModuleNames() { return dfuncNames.values; }

WebServerModuleInterface* getInterfaceForId(size_t id) {
	if (id in indexsForDfuncs)
		return &dfuncs[indexsForDfuncs[id]];
	else
		return null;
}