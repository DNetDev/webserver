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
module dnetdev.webserver.configs.defs;
import dnetdev.webserver.modulebase.internal.binder;

ServerConfigs* getSystemConfig() { return callViaHostBind(mode); }

enum ServerLogLevel {
	Debug,
	Info,
	Notice,
	Warn,
	Error,
	Critical,
	Alert,
	Emergency
}

struct ServerConfigs {
	string rootDirectory;
	
	VirtualHost primaryHost;
	// requires a copy of directories/files that are not specific to primary host to each virtual hosts as they are global
	VirtualHost[] virtualHosts;
	
	string[string] modulesToLoad;
	
	string[][string] otherDirectives;

	private { // ensures correct size of struct
		import dnetdev.webserver.modules.defs;
		import dnetdev.webserver.modules.loader;
		
		ModLoader!WebServerModuleInterface testModuleLoader;
		size_t[string] moduleToid;
		bool searchLocationsSetup = false;
	}

	@property {
		ModLoader!WebServerModuleInterface modules();
	}
	
	bool moduleLoadable(string name);
}

struct VirtualHost {
	ushort port;
	string domain;
	
	string admin;
	string name;
	
	string[ushort] errorMessage;
	string[ushort] localErrorRedirects;
	string[ushort] externalErrorRedirects;
	
	string[][string] otherDirectives;
	
	string errorLogFile;
	ServerLogLevel logLevel;
	
	string overrides; // TODO: fix type
	string requires; // TODO: fix type
	
	string[] options; // TODO: fix type
	
	VirtualHost*[string] directories;
	VirtualHost*[string] files;
	
	string directoryIndexFile;
	
	string[string] defineValues;
	string[] definedNames;
}