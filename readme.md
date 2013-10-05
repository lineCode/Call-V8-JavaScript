# Call V8 JavaScript from Luajit

All conributions are welcome.

## Build V8 on OSX

All modern OSX systems are 64 bit. Build can be done also as 32 bit or PowerPC and use lipo to combine universal binary if somebody needs it.

Linux build should be very similar.

#### Download and build

Run following commands in terminal:

* git clone https://github.com/v8/v8.git
* mkdir v8_build
* cd v8
* make dependencies
* time make native -j2 OUTDIR=../v8_build
  * -j2 means "build with 2 cores", you can omit or change it

Make dependencies takes maybe 5 minutes and build takes about 10 minutes. Now you have some time to read [V8 Getting Started](https://developers.google.com/v8/get_started "https://developers.google.com/v8/get_started") guide.


### Test V8 build

* cd ../v8_build
* edit hello_world.cpp
  * works if you have TextWrangelr and command line tools installed
* paste this code and save file

```
#include <v8.h>
using namespace v8;

int main(int argc, char* argv[]) {
  // Get the default Isolate created at startup.
  Isolate* isolate = Isolate::GetCurrent();

  // Create a stack-allocated handle scope.
  HandleScope handle_scope(isolate);

  // Create a new context.
  Handle<Context> context = Context::New(isolate);

  // Here's how you could create a Persistent handle to the context, if needed.
  Persistent<Context> persistent_context(isolate, context);

  // Enter the created context for compiling and
  // running the hello world script.
  Context::Scope context_scope(context);

  // Create a string containing the JavaScript source code.
  Handle<String> source = String::New("'Hello' + ', World!'");

  // Compile the source code.
  Handle<Script> script = Script::Compile(source);

  // Run the script to get the result.
  Handle<Value> result = script->Run();

  // The persistent handle needs to be eventually disposed.
  persistent_context.Dispose();

  // Convert the result to an ASCII string and print it.
  String::AsciiValue ascii(result);
  printf("%s\n", *ascii);
  return 0;
}
``` 

* g++ -m64 -lpthread -Iinclude native/libv8_{base.x64,snapshot}.a  native/libicu{uc,i18n,data}.a hello_world.cpp -o hello_world
* if everyting goes well you get 21,3 Mt hello_world prgram
* ./hello_world
  * this should print "Hello, World!"
  
### Create a dynamic library

* Create libV8.cpp:

```
// libV8.cpp
#include <stdlib.h>
#include <string.h>

#include <v8.h>
using namespace v8;

#ifdef _WIN32 // note the underscore: without it, it's not msdn official!
	// Windows (x64 and x86)
	#define DLL  __declspec(dllexport)
#else
	#define DLL
#endif

int main(int argc, char**argv) {
    printf("jsRun main!");
    return 0;
}

extern "C" {
DLL int32_t runScript( uint8_t *inTxt, uint32_t inTxtSize, uint8_t *outTxt, uint32_t outTxtSize ) {
	Isolate* isolate = Isolate::GetCurrent(); // Get the default Isolate created at startup.
  HandleScope handle_scope(isolate);  			// Create a stack-allocated handle scope.
  Handle<Context> context = Context::New(isolate); // Create a new context.
  // Here's how you could create a Persistent handle to the context, if needed.
  Persistent<Context> persistent_context(isolate, context);
  // Enter the created context for compiling and running the script.
  Context::Scope context_scope(context);
  // Create a string containing the JavaScript source code.
  Handle<String> source = String::New((char *)inTxt, inTxtSize); // "'Hello' + ', World!'"
  Handle<Script> script = Script::Compile(source);  // Compile the source code.
  Handle<Value> result = script->Run();  						// Run the script to get the result.
  persistent_context.Dispose();  	// The persistent handle needs to be eventually disposed.
  // Convert the result to an Utf8 (or ASCII) string
  String::Utf8Value resultTxt(result); // or String::AsciiValue resultTxt(result);

  // return data to calling progran (like Luajit ffi-call)
  int32_t returnValue = 0;
  int32_t resultSize = strlen(*resultTxt);
  if(outTxtSize < resultSize){
		returnValue = -1;
  } else {
		memcpy(outTxt, *resultTxt, resultSize);
		returnValue = resultSize;
	}
  return returnValue;
}
} // extern "C"

```
* g++ -m64 -lpthread -Iinclude native/libv8_{base.x64,snapshot}.a  native/libicu{uc,i18n,data}.a libV8.cpp -o libV8.dylib -dynamiclib

### Call dynamic library from Lua

* Create v8test.lua:
  
```
-- v8test.lua
print()
print("v8test.lua")

local ffi = require("ffi")
local js = ffi.load("v8") -- local js = require "v8"
ffi.cdef([[
	int32_t runScript( uint8_t *script, int32_t scriptSize, uint8_t *resultBuffer, int32_t resultBufferSize);
]])

local function cstr( str )
	local len = #str+1
  local typeStr = "uint8_t[" .. len .. "]"
  return ffi.new( typeStr, str ) --  #str+1 will be set to zero, null terminated string
end

local script = "'Hello ' + Math.floor((Math.random()*200)+1) + ' World, from Lua!'"
local scriptBuffer = cstr(script)
local scriptBufferSize = #script
local resultSize = scriptBufferSize * 2
local resultBufferSize = ffi.new("int32_t", resultSize) -- must be big enough
local resultBuffer = ffi.new("int8_t[?]", resultBufferSize)

print('js.runScript( "'..script..'", '..scriptBufferSize..', resultBuffer, '..resultSize..')')
local resultSize = js.runScript( scriptBuffer, scriptBufferSize, resultBuffer, resultSize )
local result = ffi.string(resultBuffer, resultSize)
print("JavaScript out: " ..  result.. ", length: " .. resultSize)
print()
```
* run: luajit v8test.lua
* you should get this kind of result:

```
v8test.lua
js.runScript( "'Hello ' + Math.floor((Math.random()*200)+1) + ' World, from Lua!'", 66, resultBuffer, 132)
JavaScript out: Hello 51 World, from Lua!, length: 25
```

## Build V8 on Windows 32 and 64 bit

* install python and git bash
* create folders c:/cpp/js (or what you like)
* open mingw bash shell
* cd c:/cpp/js
* git clone https://github.com/v8/v8.git
* cd v8

Use TortoiseSVN:

* _url:_ http://gyp.googlecode.com/svn/trunk
* _checkout directory:_ C:\cpp\js\v8\build\gyp
* http://src.chromium.org/svn/trunk/deps/third_party/cygwin
* C:\cpp\js\v8\third_party\cygwin
* https://src.chromium.org/chrome/trunk/deps/third_party/icu46
* C:\cpp\js\v8\third_party\icu

Back to bash command line:

* python build/gyp_v8 
  * x64: build/gyp_v8 -Dtarget_arch=x64
* goto build -folder and open lss.sln with VisualStudio 10
  * x64: go to Project Properties->General and set Platform Toolset to Windows7.1SDK
  * select all projects -> right mouse -> Properties -> General -> set Platform Toolset to Windows7.1SDK
* select release and build
* wait for a _long_ time, maybe 20-30 minutes in VirtualBox Win7.
* extract VisualStudio 10 project to build dll: libV8_win_VS10.7z
* copy v8\build\Release\lib folder to libV8_vs10\lib
  * v8_nosnapshot.ia32.lib is not needed
  * x64: copy to libV8_vs10\lib_x64
* copy v8\include to libV8_vs10\include
* open libV8_vs10\libV8.sln and build release
* copy libV8.dll from libV8_vs10\release
  * x64: copy libV8.dll from libV8_vs10\x64\release

## Future development

Somebody should get familiar with V8 and create new functions:

* create V8 environment
* compile js
* run compiled js
* delete V8 environment

This way same js methods will be much faster to call.

Basic Lua C-bindings should be easy to do if somebody has done them before. I don't see any need for them, Luajit sould run everywhere V8 runs and Luajit is __fast__.
