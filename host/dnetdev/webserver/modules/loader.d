﻿/**
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
module dnetdev.webserver.modules.loader;
public import dnetdev.webserver.common.modules.loader : ModLoader;
import dnetdev.webserver.common.modules.loader;
export:

size_t load(T)(ModLoader!T ctx, string[] name...) {
	auto v = new LoaderSharedLibrary!T(name, cast(string[])ctx.searchLocations);
	v.load();
	v.onModuleLoad();

	return addModuleLoader(ctx, v);
}

void unload(T)(ModLoader!T ctx, size_t id) {
	auto v = removeModuleLoader(ctx, id);
	if (v !is null) {
		v.onModuleUnload();			
		v.unload;
	}
}