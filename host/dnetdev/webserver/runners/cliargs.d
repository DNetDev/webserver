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
module dnetdev.webserver.runners.cliargs;
import dnetdev.webserver.runners.config;
import colorize : fg, cwriteln, color, style, mode;
import dlogg.strict;

bool cliArgs(string[] cliArgs) {
	import vibe.core.args;
	
	
	/// Run Mode
	
	
	// IRK does null terminator work on all platforms?
	try {
	    version(OSX) {
	        readOption("mode", &runMode, "The mode to run this process in. \0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0 " ~ 
                "0 = Independent runner \0\0\0\0\0\0\0\0\0\0\0\0\0\0 " ~
                "3 = FastCGI client ");
	    } else {
            readOption("mode", &runMode, "The mode to run this process in. \0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0 " ~ 
                "0 = Independent runner \0\0\0\0\0\0\0\0\0\0\0\0\0\0 " ~
                "1 = Daemon \0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0 " ~
                "2 = Daemon send signal \0\0\0\0\0\0\0\0\0\0\0\0\0\0 " ~
                "3 = FastCGI client ");
		}
	} catch(Exception e) {
	    version(OSX) {
		    cwriteln("Mode must be 0 or 3, inclusive.".color(fg.red).style(mode.bold) ~ "\n");
		} else {
		    cwriteln("Mode must be between 0 and 3, inclusive.".color(fg.red).style(mode.bold) ~ "\n");
		}
		return false;
	}
	
	bool runModeSecondCheck;
	version(OSX) {
	    runModeSecondCheck = runMode == 1 || runMode == 2;
	}
	
	if (runMode > 3 || runModeSecondCheck) {
	    version(OSX) {
		    cwriteln("Mode must be 0 or 3.".color(fg.red).style(mode.bold) ~ "\n");
		} else {
		    cwriteln("Mode must be between 0 and 3, inclusive.".color(fg.red).style(mode.bold) ~ "\n");
		}
		return false;
	}
	
	
	/// Daemon User/Group
	version(OSX) {
	} else {
        readOption("daemon-user", &asUser, "The user the daemon will drop to");
        readOption("daemon-group", &asGroup, "The user id the daemon will drop to");

        version(Windows) {
            enum DaemonActionAddition = "uninstall = Uninstalls windows daemon ";
        } else {
            enum DaemonActionAddition = "";
        }

        if (readOption("daemon-action", &daemonDo, "Sends a signal to a daemon. \0\0\0\0\0\0\0\0 " ~ 
                DaemonActionAddition ~
                "stop \0 \0 \0 \0 \0 = Stops the daemon \0 \0 " ~ 
                "reload \0 \0 \0 = Reload configuration " ~
				"gcreset \0 \0 = Forces GC to cleanup"
                ) || runMode == RunMode.DaemonDo) {
            import std.string : toLower;
            daemonDo = daemonDo.toLower;
        
            version(Windows) {
            } else {
                if (daemonDo == "uninstall") {
                    daemonDo = "_uninstall";
                }
            }
        
            if (daemonDo == "stop" || daemonDo == "reload" || daemonDo == "uninstall") {
            } else {
                if (runMode == RunMode.DaemonDo && daemonDo == "")
                    cwriteln("--daemon-action is only available and required when --mode=2 is specified.".color(fg.red).style(mode.bold) ~ "\n");
                else {
                    version(Windows) {
                        cwriteln("--daemon-action supports only stop, reload and uninstall.".color(fg.red).style(mode.bold));
                    } else {
                        cwriteln("--daemon-action supports only stop and reload.".color(fg.red).style(mode.bold));
                    }
                }
                return false;
            }
        }
	}
	
	
	/// Config + lock file
	
	
	if (readOption("config|c", &configFile, "Configuration file to configure by")) {
		version(Posix) {
			try {
				lockFile = readRequiredOption!string("lock-file", "The lock file for the process. Required when --config is provided");
			} catch(Exception e) {
				cwriteln(e.msg.color(fg.red).style(mode.bold));
				return false;
			}
		}
	} else {
		version(Posix) {
			readOption("lock-file", &lockFile, "The lock file for the process. Required when --config is provided");
		}
	}
	
	
	/// Init log file
	
	
	readOption("log-file", &logFile, "The log file, during init to use");
	
	
	/// Print help if no args are given
	
	
	if (cliArgs.length == 1) {
		printCommandLineHelp;
		return false;
	}
	
	
	/// Print help if arguments were not handled
	
	
	string[]* notHandledArgs;
	if (!finalizeCommandLineOptions(notHandledArgs) || notHandledArgs !is null) {
		if (notHandledArgs)
			printCommandLineHelp();
		return false;
	}
	
	
	return true;
}