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
	// The new proxy dictionary. It uses the initWithObjectsAndKeys: method to initialize the dict.
	// For some reason, this method's signature is (enjoy my fake regex) "(value, key)+, nil".
	// The keys are CFStringRef's, so we have to cast them (yay toll-free bridging!) to NSString*'s.
	// Previously, I was using Objective-C literals for the values, but that was causing double-free segfaults.
	// Apparently Objective-C literals aren't guaranteed to result in unique pointers? Ridiculous.
	NSDictionary* proxyDict = [[NSDictionary alloc] initWithObjectsAndKeys:
		[NSNumber numberWithBool:1],                  (NSString *)kCFNetworkProxiesHTTPEnable,
		[NSString stringWithUTF8String:"localhost"],  (NSString *)kCFNetworkProxiesHTTPProxy,
		[NSNumber numberWithInt:22500],               (NSString *)kCFNetworkProxiesHTTPPort,
		[NSNumber numberWithBool:1],                  (NSString *)kCFNetworkProxiesHTTPSEnable,
		[NSString stringWithUTF8String:"localhost"],  (NSString *)kCFNetworkProxiesHTTPSProxy,
		[NSNumber numberWithInt:22500],               (NSString *)kCFNetworkProxiesHTTPSPort,
		[NSNumber numberWithBool:1],                  (NSString *)kCFNetworkProxiesFTPEnable,
		[NSString stringWithUTF8String:"localhost"],  (NSString *)kCFNetworkProxiesFTPProxy,
		[NSNumber numberWithInt:22500],               (NSString *)kCFNetworkProxiesFTPPort,
		nil
	];
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

	NSDictionary* proxyDict = [[NSDictionary alloc] initWithObjectsAndKeys:
		[NSNumber numberWithBool:1],                  (NSString *)kCFNetworkProxiesHTTPEnable,
		[NSString stringWithUTF8String:"localhost"],  (NSString *)kCFNetworkProxiesHTTPProxy,
		[NSNumber numberWithInt:22500],               (NSString *)kCFNetworkProxiesHTTPPort,
		[NSNumber numberWithBool:1],                  (NSString *)kCFNetworkProxiesHTTPSEnable,
		[NSString stringWithUTF8String:"localhost"],  (NSString *)kCFNetworkProxiesHTTPSProxy,
		[NSNumber numberWithInt:22500],               (NSString *)kCFNetworkProxiesHTTPSPort,
		[NSNumber numberWithBool:1],                  (NSString *)kCFNetworkProxiesFTPEnable,
		[NSString stringWithUTF8String:"localhost"],  (NSString *)kCFNetworkProxiesFTPProxy,
		[NSNumber numberWithInt:22500],               (NSString *)kCFNetworkProxiesFTPPort,
nil
        ];

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
	NSDictionary* proxyDict = [[NSDictionary alloc] initWithObjectsAndKeys:
		[NSNumber numberWithBool:1],                  (NSString *)kSCPropNetProxiesHTTPEnable,
		[NSString stringWithUTF8String:"localhost"],  (NSString *)kSCPropNetProxiesHTTPProxy,
		[NSNumber numberWithInt:22500],               (NSString *)kSCPropNetProxiesHTTPPort,
		[NSNumber numberWithBool:1],                  (NSString *)kSCPropNetProxiesHTTPSEnable,
		[NSString stringWithUTF8String:"localhost"],  (NSString *)kSCPropNetProxiesHTTPSProxy,
		[NSNumber numberWithInt:22500],               (NSString *)kSCPropNetProxiesHTTPSPort,
		[NSNumber numberWithBool:1],                  (NSString *)kSCPropNetProxiesFTPEnable,
		[NSString stringWithUTF8String:"localhost"],  (NSString *)kSCPropNetProxiesFTPProxy,
		[NSNumber numberWithInt:22500],               (NSString *)kSCPropNetProxiesFTPPort,
		nil
	];

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
