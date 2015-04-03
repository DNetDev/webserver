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
module dnetdev.webserver.runners.config;
public import dnetdev.webserver.common.runners.config : RunMode;
import dlogg.strict;

package(dnetdev.webserver) {
	ubyte runMode;

	string asUser;
	string asGroup;
	string daemonDo;

	string lockFile;
	string configFile;
	string logFile;

	shared(StrictLogger) logger;
}

@property export {
	void setRunMode(RunMode mode) { runMode = cast(ubyte)mode; }
	void setAsUser(string user) { asUser = user; }
	void setAsGroup(string group) { asGroup = group; }
	void setDaemonDo(string value) { daemonDo = value; }
	void setLockFile(string file) { lockFile = file; }
	void setConfigFile(string file) { configFile = file; }
	void setLogFile(string file) { logFile = file; }
	void setLogger(shared(StrictLogger) value) { logger = value; }

	RunMode getRunMode() { return cast(RunMode)runMode; }
	string getAsUser() { return asUser; }
	string getAsGroup() { return asGroup; }
	string getDaemonDo() { return daemonDo; }
	string getLockFile() { return lockFile; }
	string getConfigFile() { return configFile; }
	string getLogFile() { return logFile; }
	shared(StrictLogger) getLogger() { return logger; }
}