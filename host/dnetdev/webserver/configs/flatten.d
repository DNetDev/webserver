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
module dnetdev.webserver.configs.flatten;
import dnetdev.webserver.configs.defs;

void flattenConfig() {
	import dnetdev.webserver.runners.config;
	import dnetdev.apache_httpd_format;

	ConfigFile getConfigFile(string name) {
		import std.file : readText, exists;

		if (exists(name))
			return parseConfigFileText(readText(name));
		else
			return null;
	}

	ServerConfigs ret;
	VirtualHost currentHost;
	bool isPrimary = false;
	bool[] hadIfsStatus;
	size_t[] parentOffsets;

	void execute(ConfigFile entry, Directive[] exParents) {
		if (entry is null) return;

		entry.apply((ref Directive d, Directive[] parents) {
			if (parentOffsets.length > 0 && parentOffsets[$-1] == parents.length) {
				parentOffsets.length--;
				hadIfsStatus.length--;
			}

			if (d.isInternal) {
				if (d.name == "include" && d.arguments.length == 1) {
					execute(getConfigFile(d.arguments[0]), parents);
				} else if (d.name == "ifmodule" && d.arguments.length == 2) {
					ret.modulesToLoad[d.arguments[0]] = d.arguments[1];

					if (ret.moduleLoadable(d.arguments[0])) {
						execute(cast(ConfigFile)d.childValues, parents ~ d);
					} else {
						// ignore
						ret.modulesToLoad.remove(d.arguments[0]);
					}
				} else if (d.name == "ifversion" && d.arguments.length == 1) {
					import dnetdev.webserver.VERSION : NUMBER;
					import semver;

					// Does not support the regex version that Apache httpd does. Instead uses SemVer range format.
					// Unlike Apache httpd it does not need multiple arguments.

					string actual = d.arguments[0];
					bool notIt;
					if (actual[0] == '!') {
						notIt = true;
						actual = actual[1 .. $];
					}
					
					isIfVersion ~= true;
					hadIfsStatus ~= notIt ? !SemVer(NUMBER).satisfies(SemVerRange(actual)) : SemVer(NUMBER).satisfies(SemVerRange(actual));
					parentOffsets ~= parents.length;

					if (hadIfsStatus[$-1])
						execute(cast(ConfigFile)d.childValues, parents ~ d);
				} else if (d.name == "if" && d.arguments.length == 1) {
					// TODO: execute argument
					hadIfsStatus ~= true;//...
					isIfVersion ~= false;
					parentOffsets ~= parents.length;
					execute(cast(ConfigFile)d.childValues, parents ~ d);
				} else if (d.name == "elseif" && d.arguments.length == 1 && isIfVersion[$-1]) {
					import dnetdev.webserver.VERSION : NUMBER;
					import semver;
					assert(parentOffsets.length > 0);	
					assert(parents.length == parentOffsets[$-1]);
					
					// Does not support the regex version that Apache httpd does. Instead uses SemVer range format.
					// Unlike Apache httpd it does not need multiple arguments.

					string actual = d.arguments[0];
					bool notIt;
					if (actual[0] == '!') {
						notIt = true;
						actual = actual[1 .. $];
					}
					
					isIfVersion ~= true;
					hadIfsStatus ~= notIt ? !SemVer(NUMBER).satisfies(SemVerRange(actual)) : SemVer(NUMBER).satisfies(SemVerRange(actual));
					parentOffsets ~= parents.length;
					
					if (hadIfsStatus[$-1])
						execute(cast(ConfigFile)d.childValues, parents ~ d);
				} else if (d.name == "elseif" && d.arguments.length == 1 && !isIfVersion[$-1]) {
					assert(parentOffsets.length > 0);	
					assert(parents.length == parentOffsets[$-1]);
					
					// TODO: execute argument
					hadIfsStatus[$-1] = true;//...
					execute(cast(ConfigFile)d.childValues, parents ~ d);
				} else if (d.name == "else" && d.arguments.length == 0) {
					assert(parentOffsets.length > 0);
					assert(parents.length == parentOffsets[$-1]);

					if (!hadIfsStatus[$-1]) {
						execute(cast(ConfigFile)d.childValues, parents ~ d);
					}
				} else if (d.name == "ifdefine" && d.arguments.length == 1) {
					import std.algorithm : canFind;
					assert(d.arguments[0].length > 1);

					bool isNotted = d.arguments[0][0] == '!';
					string actual = isNotted ? d.arguments[0][1 .. $] : d.arguments[0];

					if ((isNotted && (actual !in currentHost.defineValues || !currentHost.definedNames.canFind(actual))) ||
						(!isNotted && (actual in currentHost.defineValues || currentHost.definedNames.canFind(actual)))) {
						execute(cast(ConfigFile)d.childValues, parents ~ d);
					}
				}
			} else {
				// yes this should really be handled by the module system!

				if (d.name == "define" && d.arguments.length == 2) {
					currentHost.defineValues[d.arguments[0]] = d.arguments[1];
				} else if (d.name == "define" && d.arguments.length == 1) {
					import std.algorithm : canFind;
					
					if (!currentHost.definedNames.canFind(d.arguments[0]))
						currentHost.definedNames ~= d.arguments[0];
				} else {
					// TODO: call into the module system to do something with this directive under the current scope
				}
			}
		}, exParents, false);
	}

	execute(getConfigFile(configFile), null);
	systemConfig = ret;
}