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
module dnetdev.webserver.runners.config;
import dnetdev.webserver.modulebase.internal.binder;
import dlogg.strict;

enum RunMode : ubyte {
	Independent,
	Daemon,
	DaemonDo,
	FastCGI
}

@property {
	void setRunMode(RunMode mode) { callViaHostBind(mode); }
	void setAsUser(string user) { callViaHostBind(user); }
	void setAsGroup(string group) { callViaHostBind(group); }
	void setDaemonDo(string value) { callViaHostBind(value); }
	void setLockFile(string file) { callViaHostBind(file); }
	void setConfigFile(string file) { callViaHostBind(file); }
	void setLogFile(string file) { callViaHostBind(file); }
	void setLogger(shared(StrictLogger) value) { callViaHostBind(value); }
	
	RunMode getRunMode() { return callViaHostBind; }
	string getAsUser() { return callViaHostBind; }
	string getAsGroup() { return callViaHostBind; }
	string getDaemonDo() { return callViaHostBind; }
	string getLockFile() { return callViaHostBind; }
	string getConfigFile() { return callViaHostBind; }
	string getLogFile() { return callViaHostBind; }
	shared(StrictLogger) getLogger() { return callViaHostBind; }
}