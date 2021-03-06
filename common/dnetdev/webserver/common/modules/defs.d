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
module dnetdev.webserver.common.modules.defs;
import dnetdev.webserver.common.configs.defs;
import dnetdev.apache_httpd_format;
import vibe.http.server : HTTPServerRequest, HTTPServerResponse;

struct WebServerModuleInterface {
	@("dnetdev.webserver.modulebase.init") {
		void function() onModuleLoad;
		void function() onModuleUnload;
		void function() preEventLoop;
	}

	@("dnetdev.webserver.modulebase.ui") {
		bool function(string[] args, out int code) onUIRequest;
	}

	@("dnetdev.webserver.modulebase.gc") {
		void function() preGCCleanup;
		void function() postGCCleanup;
	}

	@("dnetdev.webserver.modulebase.configdirectives") {
		void function(Directive entry, Directive[] exParents, ref ServerConfigs ret, VirtualHost* currentHost, bool isPrimary, VirtualDirectory* currentFileSelector, bool isRootDirectory) handleConfigDirectiveLoading;
		void function(ref ServerConfigs ret) preConfigLoading;
		void function(ref ServerConfigs ret) postConfigLoading;
		bool function(ref ServerConfigs ret) validConfig;
	}

	@("dnetdev.webserver.modulebase.pipeline") {
		bool function(ref ServerConfigs serverConfig, VirtualHost* theVirtualHost, HTTPServerRequest theRequest) translate_name;
		void function(ref ServerConfigs serverConfig, VirtualHost* theVirtualHost, ref VirtualDirectory protection, HTTPServerRequest theRequest) map_to_storage;
		bool function(ref ServerConfigs serverConfig, VirtualHost* theVirtualHost, ref VirtualDirectory protection, HTTPServerRequest theRequest) havePriviledges;
		bool function(ref ServerConfigs serverConfig, VirtualHost* theVirtualHost, ref VirtualDirectory protection, HTTPServerRequest theRequest, string* mimeType) decideMime;
		bool function(ref ServerConfigs serverConfig, VirtualHost* theVirtualHost, ref VirtualDirectory protection, string* mimeType, HTTPServerRequest theRequest, HTTPServerResponse theResponse) processRequest;
	}
}