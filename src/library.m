#include <stdio.h>
#include <Foundation/Foundation.h>
#include <SystemConfiguration/SystemConfiguration.h>
#include <objc/runtime.h>

// A compiler flag will define this to be 1 (true) if we want debug messages.
#ifndef DEBUG
// If not, it should be 0 (false).
#define DEBUG 0
#endif

// A little macro to interpose the functions. I don't know how or why it works.
#define INTERPOSE(_replacement, _replacee) \
    __attribute__((used)) static struct { \
	const void* replacement; \
	const void* replacee; \
    } _interpose_##_replacee __attribute__ ((section("__DATA, __interpose"))) = { \
	(const void*) (unsigned long) &_replacement, \
	(const void*) (unsigned long) &_replacee \
    };


// The old sessionWithConfiguration: implementation. It will be initialized in init().
IMP OldFunc;
// The old sessionWithConfiguration:delegate:delegateQueue implementation. It will be initialized in init().
IMP OldFunc_delegates;


/* This will be the new implementation for sessionWithConfiguration:.
 * It modifies the proxy dictionary of the config argument, and then calls the old implementation.
 */
NSURLSession* getConfiguredSession(id self, SEL _cmd, NSURLSessionConfiguration* config) {
#if DEBUG
	NSLog(@"Hooked sessionWithConfiguration:!\n");
#endif
	// The new proxy dictionary. This is an Objective-C dictionary literal.
	// The keys are CFStringRef's, so we have to cast them (yay toll-free bridging!) to NSString*'s.
	// Previously, I was using Objective-C literals for the values, but that was causing double-free segfaults.
	// Apparently Objective-C literals aren't guaranteed to result in unique pointers? Ridiculous.
	NSDictionary* proxyDict = @{
		(NSString *)kCFNetworkProxiesHTTPEnable  : [NSNumber numberWithBool:1],
		(NSString *)kCFNetworkProxiesHTTPProxy   : [NSString stringWithUTF8String:"localhost"],
		(NSString *)kCFNetworkProxiesHTTPPort    : [NSNumber numberWithInt:22500],
		(NSString *)kCFNetworkProxiesHTTPSEnable : [NSNumber numberWithBool:1],
		(NSString *)kCFNetworkProxiesHTTPSProxy  : [NSString stringWithUTF8String:"localhost"],
		(NSString *)kCFNetworkProxiesHTTPSPort   : [NSNumber numberWithInt:22500],
		(NSString *)kCFNetworkProxiesFTPEnable   : [NSNumber numberWithBool:1],
		(NSString *)kCFNetworkProxiesFTPProxy    : [NSString stringWithUTF8String:"localhost"],
		(NSString *)kCFNetworkProxiesFTPPort     : [NSNumber numberWithInt:22500]
	};
#if DEBUG
	NSLog(@"%@", proxyDict);
#endif
	// Set the config's proxy dictionary to our custom one.
	config.connectionProxyDictionary = proxyDict;
	return OldFunc(self, _cmd, config);
}


/* Same idea as the previous function. Not gonna bother commenting this one, it's the same.
 */
NSURLSession* getConfiguredSession_delegates(id self, SEL _cmd, NSURLSessionConfiguration* config, id<NSURLSessionDelegate> delegate, NSOperationQueue* queue) {
#if DEBUG
	NSLog(@"Hooked sessionWithConfiguration:delegate:delegateQueue:!\n");
#endif

	NSDictionary* proxyDict = @{
		(NSString *)kCFNetworkProxiesHTTPEnable  : [NSNumber numberWithBool:1],
		(NSString *)kCFNetworkProxiesHTTPProxy   : [NSString stringWithUTF8String:"localhost"],
		(NSString *)kCFNetworkProxiesHTTPPort    : [NSNumber numberWithInt:22500],
		(NSString *)kCFNetworkProxiesHTTPSEnable : [NSNumber numberWithBool:1],
		(NSString *)kCFNetworkProxiesHTTPSProxy  : [NSString stringWithUTF8String:"localhost"],
		(NSString *)kCFNetworkProxiesHTTPSPort   : [NSNumber numberWithInt:22500],
		(NSString *)kCFNetworkProxiesFTPEnable   : [NSNumber numberWithBool:1],
		(NSString *)kCFNetworkProxiesFTPProxy    : [NSString stringWithUTF8String:"localhost"],
		(NSString *)kCFNetworkProxiesFTPPort     : [NSNumber numberWithInt:22500]
	};

#if DEBUG
	NSLog(@"%@", proxyDict);
#endif

	config.connectionProxyDictionary = proxyDict;
	return OldFunc_delegates(self, _cmd, config, delegate, queue);
}


/* This will be called instead of SCDynamicStoreCopyProxies, which is supposed to return a copy of the system proxies dictionary.
 * Clearly, we're faking it here, to force the application through our proxy. Same ideas as earlier apply.
 */
CFDictionaryRef proxyhook(SCDynamicStoreRef store) {
#if DEBUG
	NSLog(@"Hooked SCDynamicStoreCopyProxies!\n");
#endif

	// Yet another dictionary literal, this time with keys that could someday be different, but probably won't be.
	NSDictionary* proxyDict = @{
		(NSString *)kSCPropNetProxiesHTTPEnable  : [NSNumber numberWithBool:1],
		(NSString *)kSCPropNetProxiesHTTPProxy   : [NSString stringWithUTF8String:"localhost"],
		(NSString *)kSCPropNetProxiesHTTPPort    : [NSNumber numberWithInt:22500],
		(NSString *)kSCPropNetProxiesHTTPSEnable : [NSNumber numberWithBool:1],
		(NSString *)kSCPropNetProxiesHTTPSProxy  : [NSString stringWithUTF8String:"localhost"],
		(NSString *)kSCPropNetProxiesHTTPSPort   : [NSNumber numberWithInt:22500],
		(NSString *)kSCPropNetProxiesFTPEnable   : [NSNumber numberWithBool:1],
		(NSString *)kSCPropNetProxiesFTPProxy    : [NSString stringWithUTF8String:"localhost"],
		(NSString *)kSCPropNetProxiesFTPPort     : [NSNumber numberWithInt:22500]
	};

#if DEBUG
	NSLog(@"%@", proxyDict);
#endif

	return (CFDictionaryRef) proxyDict;
}


__attribute__((constructor))
static void init() {
	// The Objective-C runtime allows us to change which implementation is used for a method.
	// We select the "sessionWithConfiguration:" method on the NSURLSession class, and tell the runtime to use 
	// getConfiguredSession() as the implementation for that method. It returns the old implementation, which
	// we store in OldFunc so that it can be called by getConfiguredSession.
	OldFunc = method_setImplementation(class_getClassMethod(NSURLSession.class, @selector(sessionWithConfiguration:)), (IMP)getConfiguredSession);
	// Ditto, but with the delegate version.
	OldFunc_delegates = method_setImplementation(class_getClassMethod(NSURLSession.class, @selector(sessionWithConfiguration:delegate:delegateQueue:)), (IMP)getConfiguredSession_delegates);

#if DEBUG
	NSLog(@"FlashpointProxyMac Loaded!\n");
#endif
}

// Use the lovely interposing macro to hook 
INTERPOSE(proxyhook,SCDynamicStoreCopyProxies);
