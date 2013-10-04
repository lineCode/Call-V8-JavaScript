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
  String::Utf8Value resultTxt(result); // String::AsciiValue ascii(result);

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
