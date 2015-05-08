# Web server written in D

[![Join the chat at https://gitter.im/DNetDev/webserver](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/DNetDev/webserver?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)
Based upon Vibe.d for IO. Uses Apache httpd config format for configuration. Uses shared libraries in large doses.

## TODO list

Required ASAP:

1. version(WebServer_Dumb_FileServing)
2. core module:
	[ ] handleConfigDirectiveLoading
	[ ] preConfigLoading
	[ ] postConfigLoading
	[ ] validConfig
	[ ] translate_name
	[ ] map_to_storage
	[ ] havePriviledges
	[ ] decideMime

Implement later:

1. Fix/Implement TODO's
2. Implement http://httpd.apache.org/docs/2.4/expr.html
3. version(WebServer_Default_MMFiles)
6. FastCGI server
7. FastCGI client

External dependencies:

1. Daemonization (OSX)

Once done:

1. Daemonization util scripts
2. Packaging