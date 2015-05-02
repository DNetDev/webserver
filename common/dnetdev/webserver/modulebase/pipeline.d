/**
 * Override this module (in the shared library)
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
module dnetdev.webserver.modulebase.pipeline;
import dnetdev.webserver.common.configs.defs;
import vibe.http.server : HTTPServerRequest, HTTPServerResponse;

extern:
export:

bool translate_name(ref ServerConfigs serverConfig, VirtualHost* theVirtualHost, HTTPServerRequest theRequest);
void map_to_storage(ref ServerConfigs serverConfig, VirtualHost* theVirtualHost, ref VirtualDirectory protection, HTTPServerRequest theRequest);
bool havePriviledges(ref ServerConfigs serverConfig, VirtualHost* theVirtualHost, ref VirtualDirectory protection, HTTPServerRequest theRequest);
bool decideMime(ref ServerConfigs serverConfig, VirtualHost* theVirtualHost, ref VirtualDirectory protection, HTTPServerRequest theRequest, ref string mimeType);
bool processRequest(ref ServerConfigs serverConfig, VirtualHost* theVirtualHost, ref VirtualDirectory protection, ref string mimeType, HTTPServerRequest theRequest, HTTPServerResponse theResponse);