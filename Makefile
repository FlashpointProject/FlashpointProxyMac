CC = clang
CFLAGS =
CFLAGS_DEBUG = -gdwarf -DDEBUG=1
LDFLAGS = -framework Foundation -framework CFNetwork
DYLIB_LDFLAGS = -dynamiclib -framework Foundation -framework CFNetwork -framework SystemConfiguration

.PHONY: release debug clean test testclean debugtest debugtestclean

release: bin/test bin/FlashpointProxyMac.dylib

debug: dbg/test dbg/FlashpointProxyMac.dylib

bin/test: src/Test.m
	mkdir -p bin
	$(CC) $(CFLAGS) $(LDFLAGS) -o bin/test src/Test.m

bin/FlashpointProxyMac.dylib: src/FlashpointProxyMac.m
	mkdir -p bin
	$(CC) $(CFLAGS) $(DYLIB_LDFLAGS) -o bin/FlashpointProxyMac.dylib src/FlashpointProxyMac.m

dbg/test: src/Test.m
	mkdir -p bin
	$(CC) $(CFLAGS_DEBUG) $(LDFLAGS) -o dbg/test src/Test.m

dbg/FlashpointProxyMac.dylib: src/FlashpointProxyMac.m
	mkdir -p bin
	$(CC) $(CFLAGS_DEBUG) $(DYLIB_LDFLAGS) -o dbg/FlashpointProxyMac.dylib src/FlashpointProxyMac.m

test: release
	DYLD_INSERT_LIBRARIES=./bin/FlashpointProxyMac.dylib ./bin/test

testclean: bin/test
	./bin/test

debugtest: debug
	DYLD_INSERT_LIBRARIES=./dbg/FlashpointProxyMac.dylib ./dbg/test

debugtestclean: dbg/test
	./dbg/test

clean:
	rm -rf bin dbg
	mkdir -p bin dbg
