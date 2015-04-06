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
module dnetdev.webserver.common.modules.loader;
import derelict.util.loader;

/**
 * Loads a shared libraries, given a set interface.
 * Stores it in a wrapped given struct.
 * 
 * Given struct should contain function pointers + a UDA on them detailing where they are implemented in.
 * The module where it is implemented in, must contain stubs + export for those functions.
 */
struct ModLoader(T) if (is(T == struct)) {
	private __gshared {
		size_t counter;

		LoaderSharedLibrary!T[size_t] loaders;

		string[] searchLocations_;
	}

	this(string[] locations...) {
		import dnetdev.webserver.modules.dside : getInternalModuleNames;
		searchLocations_ = locations;
		counter = getInternalModuleNames().length;
	}

	~this() {
		foreach(k, loc; loaders) {
			loc.unload;
		}
	}

	@property {
		void searchLocations(string[] locations) {
			searchLocations_ = locations;
		}

		const(string[]) searchLocations() {
			return cast(const)searchLocations_;
		}

		size_t[] validIds() {
			return loaders.keys;
		}

		size_t internalModuleIdCount() {
			import dnetdev.webserver.modules.dside : getInternalModuleNames;
			return getInternalModuleNames().length;
		}

		T* opIndex(size_t id) {
			import dnetdev.webserver.modules.dside : getInterfaceForId;

			if (id in loaders)
				return &loaders[id].me;	
			else
				return getInterfaceForId(id);
		}
	}
	
	void addSearchLocations(string[] locations...) {
		searchLocations_ ~= locations;
	}

	auto range() {
		struct ModLoaderRange {
			private {
				import dnetdev.webserver.modules.dside : getInternalModuleNames;
				size_t offset;
				ModLoader!T me;
			}

			this(ModLoader!T me) {
				this.me = me;
			}

			@property {
				T* front() { return me[offset]; }
				bool empty() { return offset >= counter; }
			}

			void popFront() {
				offset++;

				if (offset < getInternalModuleNames().length) {
				} else
					offset = loaders.keys[offset - getInternalModuleNames().length];
			}

			T* moveFront() {
				auto ret = front;
				popFront;
				return ret;
			}

			int opApply(int delegate(T*) dg) {
				int result = 0;
				
				while(!empty) {
					result = dg(moveFront());
					if (result)
						break;
				}
				return result;
			}

			int opApply(int delegate(size_t, T*) dg) {
				int result = 0;

				while(!empty) {
					result = dg(offset, moveFront());
					if (result)
						break;
				}
				return result;
			}
		}

		return ModLoaderRange(this);
	}
}

package(dnetdev.webserver) {
	class LoaderSharedLibrary(T) : SharedLibLoader {
		T me;
		alias me this;

		protected {
			override void loadSymbols() {
				import std.traits : isFunctionPointer;
				void* value;

				foreach(member; __traits(allMembers, T)) {
					mixin("alias MTYPE = typeof(T." ~ member ~ ");");

					static if (isFunctionPointer!MTYPE) {
						enum attributes = __traits(getAttributes, mixin("T." ~ member));

						static if (attributes.length == 1) {// FIXME: should be check if it is a string!
							mixin("import theModule = " ~ attributes[0] ~ ";");
							mixin("enum mangled = theModule." ~ member ~ ".mangleof;");
							mixin("alias MMTYPE = typeof(theModule." ~ member ~ ");");
							
							static assert(__traits(compiles, member ~ " = &theModule." ~ member ~ ";"), "Struct declaration does not match the stub version.");

							bindFunc(&value, mangled, false);

							version(Windows) {
								version(X86) {
									if (value is null)
										bindFunc(&value, mangled[1 .. $]);
								} else {
									if (value is null)
										assert(0);
								}
							} else {
								if (value is null)
									assert(0);
							}

							mixin(member ~ " = cast(MTYPE)value;");
						}
					}
				}
			}
		}

		this(string[] binaries, string[] searchLocations) {
			import std.path : buildPath;
			string modifiedPaths;

			if (searchLocations.length > 0 && binaries.length > 0) {
				foreach(loc; searchLocations) {
					foreach(bin; binaries) {
						modifiedPaths ~= buildPath(loc, bin) ~ ",";
					}
				}
			} else if (binaries.length > 0) {
				foreach(bin; binaries) {
					modifiedPaths ~= bin ~ ",";
				}
			}

			if (binaries.length > 0)
				modifiedPaths.length--;

			super(modifiedPaths);
		}
	}

	size_t addModuleLoader(T)(ModLoader!T ctx, LoaderSharedLibrary!T md) {
		with (ctx) {
			size_t id = counter;
			
			loaders[id] = md;
			
			counter++;
			return id;
		}
	}
	
	auto removeModuleLoader(T)(ModLoader!T ctx, size_t id) {
		with (ctx) {
			if (id in loaders) {
				auto ret = loaders[id];
				loaders.remove(id);
				return ret;
			} else {
				return null;
			}
		}
	}
}