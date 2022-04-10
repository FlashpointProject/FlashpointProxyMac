#include <stdio.h>
@import Foundation;
@import ObjectiveC.runtime;
@import MachO.dyld;

IMP OldFunc;

NSURLSession* getConfiguredSession(id self, SEL _cmd, NSURLSessionConfiguration* config) {
	NSLog(@"Hooked!\n");
	return OldFunc(self, _cmd, config);
}

__attribute__((constructor)) void dylib_main() {
	OldFunc = method_setImplementation(class_getClassMethod([NSURLSession class], @selector(sessionWithConfiguration)), (IMP)getConfiguredSession);
	printf("Loaded!\n");
}
