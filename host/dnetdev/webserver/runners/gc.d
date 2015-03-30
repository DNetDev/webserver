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
module dnetdev.webserver.runners.gc;

/**
 * Forces a cleanup reguarding the GC
 * 
 * Make sure the GC was already disabled in e.g. main.
 */
export void forceGCCleanup() {
	import dnetdev.webserver.configs.defs;
	import core.memory : GC;

	auto modules = getSystemConfig().modules;

	foreach(mod; modules.range) {
		mod.preGCCleanup();
	}

	GC.collect; // forces a collection
	GC.minimize; // gives the OS any memory it can
	
	// reserve 32mb of space from the OS
	// just in case GC does get to be used, allocation will be free.
	GC.reserve(1024 * 1024 * 32);

	foreach(mod; modules.range) {
		mod.postGCCleanup();
	}
}