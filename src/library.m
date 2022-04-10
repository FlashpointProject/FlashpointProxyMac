#include <stdio.h>
#include <Foundation/Foundation.h>
#include <SystemConfiguration/SystemConfiguration.h>
#include <objc/runtime.h>

// A little macro to interpose the functions. I don't know how or why it works.
#define INTERPOSE(_replacement, _replacee) \
    __attribute__((used)) static struct { \
	const void* replacement; \
	const void* replacee; \
    } _interpose_##_replacee __attribute__ ((section("__DATA, __interpose"))) = { \
	(const void*) (unsigned long) &_replacement, \
	(const void*) (unsigned long) &_replacee \
    };

IMP OldFunc;

NSNumber* enableCF;
NSNumber* portCF;
NSString* targetCF;

NSURLSession* getConfiguredSession(id self, SEL _cmd, NSURLSessionConfiguration* config) {
	NSLog(@"Hooked sessionWithConfiguration!\n");
	CFMutableDictionaryRef mutableDict = CFDictionaryCreateMutable(kCFAllocatorDefault, 12, NULL, NULL);

	CFDictionarySetValue(mutableDict, kCFNetworkProxiesHTTPEnable, enableCF);
	CFDictionarySetValue(mutableDict, kCFNetworkProxiesHTTPPort, portCF);
	CFDictionarySetValue(mutableDict, kCFNetworkProxiesHTTPProxy, targetCF);
	CFDictionarySetValue(mutableDict, kSCPropNetProxiesHTTPEnable, enableCF);
	CFDictionarySetValue(mutableDict, kSCPropNetProxiesHTTPPort, portCF);
	CFDictionarySetValue(mutableDict, kSCPropNetProxiesHTTPProxy, targetCF);

	CFDictionarySetValue(mutableDict, kCFNetworkProxiesHTTPSEnable, enableCF);
	CFDictionarySetValue(mutableDict, kCFNetworkProxiesHTTPSPort, portCF);
	CFDictionarySetValue(mutableDict, kCFNetworkProxiesHTTPSProxy, targetCF);
	CFDictionarySetValue(mutableDict, kSCPropNetProxiesHTTPSEnable, enableCF);
	CFDictionarySetValue(mutableDict, kSCPropNetProxiesHTTPSPort, portCF);
	CFDictionarySetValue(mutableDict, kSCPropNetProxiesHTTPSProxy, targetCF);
	NSLog(@"%@", (NSDictionary *)mutableDict);
	config.connectionProxyDictionary = (NSDictionary*) mutableDict;
	return OldFunc(self, _cmd, config);
}

CFDictionaryRef proxyhook(SCDynamicStoreRef store) {
	NSLog(@"Hooked SCDynamicStoreCopyProxies!\n");
	CFMutableDictionaryRef mutableDict = CFDictionaryCreateMutable(kCFAllocatorDefault, 12, NULL, NULL);

	CFDictionarySetValue(mutableDict, kCFNetworkProxiesHTTPEnable, enableCF);
	CFDictionarySetValue(mutableDict, kCFNetworkProxiesHTTPPort, portCF);
	CFDictionarySetValue(mutableDict, kCFNetworkProxiesHTTPProxy, targetCF);
	CFDictionarySetValue(mutableDict, kSCPropNetProxiesHTTPEnable, enableCF);
	CFDictionarySetValue(mutableDict, kSCPropNetProxiesHTTPPort, portCF);
	CFDictionarySetValue(mutableDict, kSCPropNetProxiesHTTPProxy, targetCF);

	CFDictionarySetValue(mutableDict, kCFNetworkProxiesHTTPSEnable, enableCF);
	CFDictionarySetValue(mutableDict, kCFNetworkProxiesHTTPSPort, portCF);
	CFDictionarySetValue(mutableDict, kCFNetworkProxiesHTTPSProxy, targetCF);
	CFDictionarySetValue(mutableDict, kSCPropNetProxiesHTTPSEnable, enableCF);
	CFDictionarySetValue(mutableDict, kSCPropNetProxiesHTTPSPort, portCF);
	CFDictionarySetValue(mutableDict, kSCPropNetProxiesHTTPSProxy, targetCF);
	return (CFDictionaryRef) mutableDict;
}

const void * dictValueGetter(CFDictionaryRef theDict, const void *key) {
	if (key == kSCPropNetProxiesHTTPEnable) {
		CFShow(key);
		CFShow(enableCF);
		return (const void *)enableCF;
	}
	if (key == kSCPropNetProxiesHTTPPort) {
		CFShow(key);
		CFShow(portCF);
		return (const void *)portCF;
	}
	if (key == kSCPropNetProxiesHTTPProxy) {
		CFShow(key);
		CFShow(targetCF);
		return (const void *)targetCF;
	}
	if (key == kSCPropNetProxiesHTTPSEnable) {
		CFShow(key);
		CFShow(enableCF);
		return (const void *)enableCF;
	}
	if (key == kSCPropNetProxiesHTTPSPort) {
		CFShow(key);
		CFShow(targetCF);
		return (const void *)portCF;
	}
	if (key == kSCPropNetProxiesHTTPSProxy) {
		CFShow(key);
		CFShow(targetCF);
		return (const void *)targetCF;
	}
	if (key == kCFNetworkProxiesHTTPEnable) {
		CFShow(key);
		CFShow(enableCF);
		return (const void *)enableCF;
	}
	if (key == kCFNetworkProxiesHTTPPort) {
		CFShow(key);
		CFShow(portCF);
		return (const void *)portCF;
	}
	if (key == kCFNetworkProxiesHTTPProxy) {
		CFShow(key);
		CFShow(targetCF);
		return (const void *)targetCF;
	}
	if (key == kCFNetworkProxiesHTTPSEnable) {
		CFShow(key);
		CFShow(enableCF);
		return (const void *)enableCF;
	}
	if (key == kCFNetworkProxiesHTTPSPort) {
		CFShow(key);
		CFShow(targetCF);
		return (const void *)portCF;
	}
	if (key == kCFNetworkProxiesHTTPSProxy) {
		CFShow(key);
		CFShow(targetCF);
		return (const void *)targetCF;
	}
	if (key == kCFHTTPVersion1_0
	|| key == kCFStreamPropertyHTTPAttemptPersistentConnection
	|| key == kCFStreamPropertyHTTPFinalURL
	|| key == kCFStreamPropertyHTTPProxy
	|| key == kCFStreamPropertyHTTPRequestBytesWrittenCount
	|| key == kCFStreamPropertyHTTPResponseHeader
	|| key == kCFStreamPropertyHTTPShouldAutoredirect
	|| key == kSCEntNetIPv4
	|| key == kSCEntNetIPv6
	|| key == kSCPropNetIPv4Addresses
	|| key == kCFStreamPropertySOCKSProxyHost
	|| key == kCFStreamPropertySOCKSProxyPort) {
		CFShow(key);
		const void* retval = CFDictionaryGetValue(theDict, key);
		if (retval != NULL) {
			CFShow(retval);
		}
		return retval;
	}
	return CFDictionaryGetValue(theDict, key);
}

__attribute__((constructor))
static void init() {
	OldFunc = method_setImplementation(class_getClassMethod([NSURLSession class], @selector(sessionWithConfiguration:)), (IMP)getConfiguredSession);

	enableCF = @1;
	portCF = @22500;
	targetCF = @"127.0.0.1";

	NSLog(@"Loaded!\n");
}

__attribute__((destructor))
static void destroy() {
	CFRelease(enableCF);
	CFRelease(portCF);
	CFRelease(targetCF);
}

INTERPOSE(proxyhook,SCDynamicStoreCopyProxies);
INTERPOSE(dictValueGetter,CFDictionaryGetValue);
