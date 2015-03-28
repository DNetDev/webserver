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
module dnetdev.webserver.runners.daemon;
version(OSX) {
    pragma(msg, "daemonize does not support OSX");
} else:

import dnetdev.webserver.runners.independent : initializeByVibeIndepenent;
import dnetdev.webserver.runners.config;
import daemonize.d;
public import daemonize.daemon : Signal;

enum ReloadConfigs = "ReloadConfig".customSignal;

alias daemon = Daemon!(
	"Webserver-D",

	KeyValueList!(
		Composition!(Signal.Terminate, Signal.Quit, Signal.Shutdown, Signal.Stop), (logger) {
			import vibe.core.core : exitEventLoop;
			exitEventLoop;

			logger.logInfo("Exiting...");
			return false; // returning false will terminate daemon
		},
		Signal.HangUp, (logger) {
			return true;
		},
		ReloadConfigs, (logger) {
			// force reloading of the configurations!
			import vibe.core.core : exitEventLoop;

			exitEventLoop(true);
			logger.logInfo("Reloading configurations");

			// reinitialize from scratch
			initializeByVibeIndepenent;
			return true;
		}
	),

	(logger, shouldExit) {
		logger.logInfo("Exiting main function!");

		// initialize from scratch
		initializeByVibeIndepenent;
		return 0;
	}
);

alias daemonClientType = DaemonClient!(
	"Webserver-D",
	Signal.Terminate,
	Signal.Quit,
	Signal.Shutdown,
	Signal.Stop,
	Signal.HangUp,
	ReloadConfigs
);

alias daemonClient = buildDaemon!daemonClientType;
alias clientSend = daemonClient.sendSignal;

export int initializeAsDaemon() {
	return buildDaemon!daemon.run(logger); 
}