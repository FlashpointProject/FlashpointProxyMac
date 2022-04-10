#include <Foundation/Foundation.h>
void printProxyInfo(NSURLSessionConfiguration* config);

int main(int argc, const char* argv[]) {
	NSURLSessionConfiguration* config = NSURLSessionConfiguration.defaultSessionConfiguration;
	printProxyInfo(config);
	NSURLSession* session = [NSURLSession sessionWithConfiguration:config];
	printProxyInfo([session configuration]);
	return 0;
}

void printProxyInfo(NSURLSessionConfiguration* config) {
	NSDictionary* proxyDict = [config connectionProxyDictionary];
	if (proxyDict) {
		printf("proxyDict non-null/nil\n");
		NSLog(@"%@", proxyDict);
	} else {
		printf("proxyDict null/nil\n");
	}
}
