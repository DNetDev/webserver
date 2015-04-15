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
module dnetdev.webserver.configs.defs;
public import dnetdev.webserver.common.configs.defs : ServerLogLevel, VirtualHost, ServerConfigs, VirtualDirectory;

package {
	ServerConfigs systemConfig;
}

export:

ServerConfigs* getSystemConfig() {
	return &systemConfig;
}

bool moduleLoadable(ServerConfigs ctx, string name) {
	import dnetdev.webserver.runners.config : configFile;
	import dnetdev.webserver.modules.dside : getInternalModuleNames;
	import dnetdev.webserver.modules.loader : load;
	import std.path : buildPath, dirName;
	import std.algorithm : canFind;

	with(ctx) {
		assert(name in modulesToLoad);
		
		if (getInternalModuleNames().canFind(name))
			return true;
		
		if (!searchLocationsSetup) {
			string globalPath = dirName(configFile);
			testModuleLoader.searchLocations = [rootDirectory, buildPath(rootDirectory, "config"), buildPath(rootDirectory, "configs"), globalPath, buildPath(globalPath, "config"), buildPath(globalPath, "configs")];
			searchLocationsSetup = true;
		}
		
		try {
			size_t id = testModuleLoader.load(modulesToLoad[name]);
			moduleToid[name] = id;
			
			return true;
		} catch (Exception e) {
			return false;
		}
	}
}