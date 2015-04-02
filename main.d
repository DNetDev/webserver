/**
 * Example main entry point
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
module main;
import dnetdev.webserver.runners.config;
import dnetdev.webserver.runners.cliargs;
import colorize : fg, cwriteln, color, style, mode;
import dlogg.strict;

int main(string[] args) {
	import dnetdev.webserver.modules.loader;
	import dnetdev.webserver.modules.defs;

	import core.memory : GC;
	GC.disable; // make sure we do not do any hidden collections

	bool doDefaultSetup;
	if (args.length > 1 && args[1].length > 1 && args[1][0] != '-') {
		try {
			ModLoader!WebServerModuleInterface loader;
			size_t id = loader.load("webserverd_" ~ args[1] ~ "_ui.dll");

			int errorCode;
			doDefaultSetup = loader[id].onUIRequest(args.length > 2 ? args[2 .. $] : null, errorCode);
			if (errorCode != 0)
				return errorCode;

			loader.unload(id);
		} catch(Exception e) {
		}
	}
	
	if (cliArgs(args) || doDefaultSetup) {
		
		
		/// logging
		
		
		if (logFile == "") {
			import std.conv : text;
			import std.process : thisProcessID;
			
			version(Windows) logFile = "C:\\webserver_PID_" ~ text(thisProcessID()) ~ ".log";
			else logFile = "webserver_PID_" ~ text(thisProcessID()) ~ ".log";
		}
		
		logger = new shared StrictLogger(logFile);
		
		
		/// actual init stuff
		

		if (runMode == RunMode.Independent) {
			import dnetdev.webserver.runners.independent : initializeByVibeIndepenent;
			initializeByVibeIndepenent;
			
			return 0; // ran correctly
		} else if (runMode == RunMode.Daemon) {
		    version(OSX) {
		        assert(0); // should NEVER be hit
		    } else {
                import dnetdev.webserver.runners.daemon : initializeAsDaemon;
                initializeAsDaemon;
                return 0;
			}
		} else if (runMode == RunMode.DaemonDo) {
		    version(OSX) {
		        assert(0); // should NEVER be hit
		    } else {
                import dnetdev.webserver.runners.daemon;
            
                try {
                    if (daemonDo == "reload")
                        clientSend(logger, ReloadConfigs);
                    else if (daemonDo == "stop")
                        clientSend(logger, Signal.Stop);
                    else if (daemonDo == "uninstall") {
                        version(Windows) {
                            daemonClient.uninstall(logger);
                        } else {
                            assert(0); // should NEVER be hit
                        }
                    } else
                        assert(0); // should NEVER be hit
                        
                    return 0;
		    	} catch(Exception e) {
				    cwriteln("Could not send signal to service: ".color(fg.red).style(mode.bold), e.msg);
				    return -2;
			    }
		    }
		} else if (runMode == RunMode.FastCGI) {
			import dnetdev.webserver.runners.fastcgi : initializeAsFastCGIClient;
			initializeAsFastCGIClient;
			return 0; // ran correctly
		} else {
			assert(0); // should NEVER be hit
		}
	} else {
		return -1; // invalid args
	}
}