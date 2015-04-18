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

/**
 * 
 * TODO:
 * 		<Limit>
 * 		<LimitExcept>
 */
export void flattenConfig() {
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

	VirtualHost* currentHost;
	bool isPrimary = false;
	VirtualDirectory* currentFileSelector;
	bool isRootDirectory;

	bool[] hadIfsStatus;
	bool[] isIfVersion;
	size_t[] parentOffsets;

	void execute(ConfigFile entry, Directive[] exParents) {
		if (entry is null) return;

		entry.apply((ref Directive d, Directive[] parents) {
			if (parentOffsets.length > 0 && parentOffsets[$-1] == parents.length) {
				parentOffsets.length--;
				hadIfsStatus.length--;
				isIfVersion.length--;
			}

			if (d.isInternal) {
				if (d.name == "include" && d.arguments.length == 1) {
					execute(getConfigFile(d.arguments[0]), parents);
				} else if (d.name == "includeoptional" && d.arguments.length == 1) {
					auto cf = getConfigFile(d.arguments[0]);
					if (cf !is null)
						execute(cf, parents);
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
					// TODO: execute argument http://httpd.apache.org/docs/2.4/expr.html
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
					
					// TODO: execute argument http://httpd.apache.org/docs/2.4/expr.html
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
					
					bool isDefined;
					
					// server config
					isDefined = (isNotted && (actual !in ret.primaryHost.rootDirectory.defineValues || !ret.primaryHost.rootDirectory.definedNames.canFind(actual))) ||
								(!isNotted && (actual in ret.primaryHost.rootDirectory.defineValues || ret.primaryHost.rootDirectory.definedNames.canFind(actual)));
					
					// virtual host
					isDefined = !isRootDirectory && ((isNotted && (actual !in currentHost.rootDirectory.defineValues || !currentHost.rootDirectory.definedNames.canFind(actual))) ||
													(!isNotted && (actual in currentHost.rootDirectory.defineValues || currentHost.rootDirectory.definedNames.canFind(actual))) || isDefined);

					// directory
					isDefined = !isRootDirectory && ((isNotted && (actual !in currentFileSelector.defineValues || !currentFileSelector.definedNames.canFind(actual))) ||
													(!isNotted && (actual in currentFileSelector.defineValues || currentFileSelector.definedNames.canFind(actual))) || isDefined);

					if (isDefined) {
						execute(cast(ConfigFile)d.childValues, parents ~ d);
					}
				} else if (d.name == "virtualhost" && d.arguments.length >= 1) {
					bool prePrim = isPrimary;
					isPrimary = false;
					VirtualHost* preHost = currentHost;

					bool isRoot = isRootDirectory;
					VirtualDirectory* preDir = currentFileSelector;
					
					parentOffsets ~= parents.length;
					ret.virtualHosts.length++;
					currentHost = &ret.virtualHosts[$-1];

					currentFileSelector = new VirtualDirectory;
					currentHost.rootDirectory = currentFileSelector;
					isRootDirectory = true;

					// TODO: get ips/ports!

					execute(cast(ConfigFile)d.childValues, parents ~ d);
					
					isRootDirectory = isRoot;
					currentFileSelector = preDir;
					currentHost = preHost;
					isPrimary = prePrim;
				} else if (d.name == "directory" && d.arguments.length == 1) {
					bool isRoot = isRootDirectory;
					VirtualDirectory* preDir = currentFileSelector;
					
					currentFileSelector = new VirtualDirectory;
					currentHost.directories[d.arguments[0]] = currentFileSelector;
					isRootDirectory = false;
					
					execute(cast(ConfigFile)d.childValues, parents ~ d);

					isRootDirectory = isRoot;
					currentFileSelector = preDir;
				} else if ((d.name == "directory" && d.arguments.length == 2 && d.arguments[0] == "~") || (d.name == "directorymatch" && d.arguments.length == 1)) {
					bool isRoot = isRootDirectory;
					VirtualDirectory* preDir = currentFileSelector;
					
					currentFileSelector = new VirtualDirectory;
					currentHost.directoryMatch[d.arguments[$-1]] = currentFileSelector;
					isRootDirectory = false;
					
					execute(cast(ConfigFile)d.childValues, parents ~ d);
					
					isRootDirectory = isRoot;
					currentFileSelector = preDir;
				} else if (d.name == "file" && d.arguments.length == 1) {
					bool isRoot = isRootDirectory;
					VirtualDirectory* preDir = currentFileSelector;
					
					currentFileSelector = new VirtualDirectory;
					currentHost.files[d.arguments[0]] = currentFileSelector;
					isRootDirectory = false;
					
					execute(cast(ConfigFile)d.childValues, parents ~ d);
					
					isRootDirectory = isRoot;
					currentFileSelector = preDir;
				} else if ((d.name == "file" && d.arguments.length == 2 && d.arguments[0] == "~") || (d.name == "filematch" && d.arguments.length == 1)) {
					bool isRoot = isRootDirectory;
					VirtualDirectory* preDir = currentFileSelector;
					
					currentFileSelector = new VirtualDirectory;
					currentHost.fileMatch[d.arguments[$-1]] = currentFileSelector;
					isRootDirectory = false;
					
					execute(cast(ConfigFile)d.childValues, parents ~ d);
					
					isRootDirectory = isRoot;
					currentFileSelector = preDir;
				} else if (d.name == "location" && d.arguments.length == 1) {
					bool isRoot = isRootDirectory;
					VirtualDirectory* preDir = currentFileSelector;
					
					currentFileSelector = new VirtualDirectory;
					currentHost.location[d.arguments[0]] = currentFileSelector;
					isRootDirectory = false;
					
					execute(cast(ConfigFile)d.childValues, parents ~ d);
					
					isRootDirectory = isRoot;
					currentFileSelector = preDir;
				} else if ((d.name == "location" && d.arguments.length == 2 && d.arguments[0] == "~") || (d.name == "locationmatch" && d.arguments.length == 1)) {
					bool isRoot = isRootDirectory;
					VirtualDirectory* preDir = currentFileSelector;
					
					currentFileSelector = new VirtualDirectory;
					currentHost.locationMatch[d.arguments[$-1]] = currentFileSelector;
					isRootDirectory = false;
					
					execute(cast(ConfigFile)d.childValues, parents ~ d);
					
					isRootDirectory = isRoot;
					currentFileSelector = preDir;
				}
			} else {
				// yes this should really be handled by the module system!

				if (d.name == "define" && d.arguments.length == 2) {
					currentFileSelector.defineValues[d.arguments[0]] = d.arguments[1];
				} else if (d.name == "define" && d.arguments.length == 1) {
					import std.algorithm : canFind;
					
					if (!currentFileSelector.definedNames.canFind(d.arguments[0]))
						currentFileSelector.definedNames ~= d.arguments[0];
				} else {
					foreach(loader; ret.modules.range) {
						if (loader.handleConfigDirectiveLoading !is null) {
							loader.handleConfigDirectiveLoading(d, exParents, ret, currentHost, isPrimary, currentFileSelector, isRootDirectory);
						}
					}
				}
			}
		}, exParents, false);
	}

	isPrimary = true;
	currentHost = new VirtualHost;
	ret.primaryHost = currentHost;
	isRootDirectory = true;
	currentFileSelector = new VirtualDirectory;
	currentHost.rootDirectory = currentFileSelector;

	foreach(loader; ret.modules.range) {
		if (loader.preConfigLoading !is null) {
			loader.preConfigLoading(ret);
		}
	}

	execute(getConfigFile(configFile), null);

	foreach(loader; ret.modules.range) {
		if (loader.postConfigLoading !is null) {
			loader.postConfigLoading(ret);
		}
	}

	foreach(loader; ret.modules.range) {
		if (loader.validConfig !is null) {
			assert(loader.validConfig(ret));
		}
	}

	systemConfig = ret;
}