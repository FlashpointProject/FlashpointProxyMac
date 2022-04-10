CC = clang
CFLAGS = -gdwarf
LDFLAGS = -framework Foundation -framework CFNetwork
DYLIB_LDFLAGS = -dynamiclib -framework Foundation -framework CFNetwork -framework SystemConfiguration

all: bin/caller bin/library.dylib

bin/caller: src/caller.m
	mkdir -p bin
	$(CC) $(CFLAGS) $(LDFLAGS) -o bin/caller src/caller.m

bin/library.dylib: src/library.m
	mkdir -p bin
	$(CC) $(CFLAGS) $(DYLIB_LDFLAGS) -o bin/library.dylib src/library.m

run: all
	DYLD_INSERT_LIBRARIES=./bin/library.dylib ./bin/caller

runclean: all
	./bin/caller

clean:
	rm -rf bin
	mkdir -p bin
