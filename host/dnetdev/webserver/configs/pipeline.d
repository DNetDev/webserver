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
module dnetdev.webserver.configs.pipeline;
import dnetdev.webserver.common.configs.defs;
import vibe.http.server : HTTPServerRequest, HTTPServerResponse;

export void handleRequest(ServerConfigs config, scope HTTPServerRequest request, scope HTTPServerResponse response) {
	VirtualHost* host;
	VirtualDirectory protection;
	string mimeType;

	bool handled;

	handled = false;
	foreach(mod; config.modules.range) {
		if (mod.translate_name !is null && mod.translate_name(config, host, request)) {
			handled = true;
			break;
		}
	}
	if (!handled) {
		response.writeBody("couldn't translate name", 500);
		return;
	}

	foreach(mod; config.modules.range) {
		if (mod.map_to_storage !is null)
			mod.map_to_storage(config, host, protection, request);
	}

	handled = false;
	foreach(mod; config.modules.range) {
		if (mod.havePriviledges !is null && mod.havePriviledges(config, host, protection, request)) {
			handled = true;
			break;
		}
	}
	if (!handled) {
		response.writeBody("file or directory not accessible", 401);
		return;
	}

	handled = false;
	foreach(mod; config.modules.range) {
		if (mod.decideMime !is null && mod.decideMime(config, host, protection, request, mimeType)) {
			handled = true;
			break;
		}
	}
	if (!handled) {
		response.writeBody("couldn't find types", 500);
		return;
	}

	handled = false;
	foreach(mod; config.modules.range) {
		if (mod.processRequest !is null && mod.processRequest(config, host, protection, mimeType, request, response)) {
			handled = true;
			break;
		}
	}
	if (!handled) {
		response.writeBody("unknown type handler", 404);
		return;
	}
}