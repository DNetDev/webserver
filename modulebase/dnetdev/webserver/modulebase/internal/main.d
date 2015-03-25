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
module dnetdev.webserver.modulebase.internal.main;

void fixStandardIO() {
	import std.stdio: stdin, stdout, stderr, File;
	// Loads up new instances of stdin/stdout/stderr if they have not been properly created

	if (stdin.error || stdout.error || stderr.error) {
		version(Windows) {
			import core.sys.windows.windows: GetStdHandle, STD_INPUT_HANDLE, STD_OUTPUT_HANDLE, STD_ERROR_HANDLE;

			File nstdin;
			nstdin.windowsHandleOpen(GetStdHandle(STD_INPUT_HANDLE), ['r']);
			stdin = nstdin;
			
			File nstdout;
			nstdout.windowsHandleOpen(GetStdHandle(STD_OUTPUT_HANDLE), ['w']);
			stdout = nstdout;
			
			File nstderr;
			nstderr.windowsHandleOpen(GetStdHandle(STD_ERROR_HANDLE), ['w']);
			stderr = nstderr;
		}
	}
}

shared static this() {
	fixStandardIO();
}

version(Windows) {
	import core.sys.windows.dll;
	mixin SimpleDllMain;
} else {
	void main(){} // is this even needed?
}