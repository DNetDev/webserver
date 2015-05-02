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
module dnetdev.webserver.runners.independent;

export void initializeByVibeIndepenent() {
	import dnetdev.webserver.configs;
	import dnetdev.webserver.runners.gc;
	import vibe.core.core : runEventLoop;
	import vibe.http.server : HTTPServerSettings, listenHTTP, HTTPServerRequest, HTTPServerResponse;
	import std.algorithm : canFind;

	// FIXME: close precreated sockets

	// load config
	flattenConfig;
	ServerConfigs* config = getSystemConfig();

	// get the ports + ip's we are hosting on

	string[][ushort] portIps;
	portIps = getSystemConfig().primaryHost.listenOn.dup;

	foreach(host; getSystemConfig().virtualHosts) {
		foreach(k, v; host.listenOn) {
			foreach(v2; v) {
				if (!portIps[k].canFind(v2))
					portIps[k] ~= v2;
			}
		}
	}

	foreach(port, ips; portIps) {
		auto settings = new HTTPServerSettings;
		settings.port = port;
		settings.bindAddresses = ips;
		// TODO: ssl
		// TODO: other settings
		listenHTTP(settings, (scope HTTPServerRequest req, scope HTTPServerResponse res) {
			handleRequest(*config, req, res);
		}); // FIXME: UGH how to close once created?
	}

	// module system preEventLoop call
	foreach(mod; config.modules.range()) {
		mod.preEventLoop();
	}

	forceGCCleanup;
	runEventLoop;
}