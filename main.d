module main;
import dnetdev.webserver.runners.config;
import dnetdev.webserver.runners.cliargs;
import colorize : fg, cwriteln, color, style, mode;
import dlogg.strict;

int main(string[] args) {
	import dnetdev.webserver.modules.loader;
	import dnetdev.webserver.modules.defs;

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
			import dnetdev.webserver.runners.daemon : initializeAsDaemon;
			initializeAsDaemon;
			return 0;
		} else if (runMode == RunMode.DaemonDo) {
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
			} catch(Exception e) {
				cwriteln("Could not send signal to service: ".color(fg.red).style(mode.bold), e.msg);
				return -2;
			}
			
			return 0;
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