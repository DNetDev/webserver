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
	string* mimeType;

	bool handled;

	handled = false;
	foreach(func; config.runtimeMappedConfig.translate_name) {
		if (func(config, host, request)) {
			handled = true;
			break;
		}
	}
	if (!handled) {
		response.writeBody("couldn't translate name", 500);
		return;
	}

	foreach(func; config.runtimeMappedConfig.map_to_storage) {
		func(config, host, protection, request);
	}

	handled = false;
	foreach(func; config.runtimeMappedConfig.havePriviledges) {
		if (func(config, host, protection, request)) {
			handled = true;
			break;
		}
	}
	if (!handled) {
		response.writeBody("file or directory not accessible", 401);
		return;
	}

	handled = false;
	foreach(func; config.runtimeMappedConfig.decideMime) {
		if (func(config, host, protection, request, mimeType)) {
			handled = true;
			break;
		}
	}
	if (!handled) {
		response.writeBody("couldn't find types", 500);
		return;
	}

	handled = false;
	foreach(func; config.runtimeMappedConfig.processRequest) {
		if (func(config, host, protection, mimeType, request, response)) {
			handled = true;
			break;
		}
	}
	if (!handled) {
		response.writeBody("unknown type handler", 404);
		return;
	}
}

export void mapToRuntimeConfig(ServerConfigs* config) {
	foreach(mod; config.modules.range) {
		if (mod.translate_name !is null)
			config.runtimeMappedConfig.translate_name ~= mod.translate_name;
		if (mod.map_to_storage !is null)
			config.runtimeMappedConfig.map_to_storage ~= mod.map_to_storage;
		if (mod.havePriviledges !is null)
			config.runtimeMappedConfig.havePriviledges ~= mod.havePriviledges;
		if (mod.decideMime !is null)
			config.runtimeMappedConfig.decideMime ~= mod.decideMime;
		if (mod.processRequest !is null)
			config.runtimeMappedConfig.processRequest ~= mod.processRequest;
	}
}