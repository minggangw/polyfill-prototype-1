# Patches welcome to actually make this portable

default: tools/pack-asmjs tools/unpack-asmjs jslib/load-wasm-worker.js tools/pack-asmjs-v8

tools/pack-asmjs: src/pack-asmjs.cpp src/unpack.cpp src/unpack.h src/shared.h src/cashew/parser.h src/cashew/parser.cpp src/cashew/istring.h
	mkdir -p tools
	c++ -O3 -g -std=c++11 -DCHECKED_OUTPUT_SIZE -Wall -pedantic \
	    src/pack-asmjs.cpp src/unpack.cpp src/cashew/parser.cpp \
	    -o tools/pack-asmjs

tools/pack-asmjs-v8: src/pack-asmjs.cpp src/polyfill-to-v8.cpp src/unpack.cpp src/unpack.h src/shared.h src/cashew/parser.h src/cashew/parser.cpp src/cashew/istring.h
	mkdir -p tools
	c++ -g -std=c++11 -DCHECKED_OUTPUT_SIZE -DV8_FORMAT -Wall -pedantic \
	    src/pack-asmjs.cpp src/polyfill-to-v8.cpp src/unpack.cpp src/cashew/parser.cpp \
	    -o tools/pack-asmjs-v8

tools/unpack-asmjs: src/unpack-asmjs.cpp src/unpack.cpp src/unpack.h src/shared.h
	mkdir -p tools
	c++ -DNDEBUG -O3 -std=c++11 -Wall -pedantic \
	    src/unpack-asmjs.cpp src/unpack.cpp \
	    -o tools/unpack-asmjs

jslib/load-wasm-worker.js: src/unpack.cpp src/unpack.h src/shared.h src/load-wasm-worker.js
	emcc -DNDEBUG -O3 -std=c++11 -Wall -pedantic \
	     --memory-init-file 0 --llvm-lto 1 -s TOTAL_MEMORY=67108864 \
	     src/unpack.cpp \
	     -o jslib/load-wasm-worker.js
	cat src/load-wasm-worker.js >> jslib/load-wasm-worker.js

.PHONY: test
test: tools/pack-asmjs tools/unpack-asmjs
	mkdir -p /tmp/test
	for tjs in test/*.js; do \
		t=$${tjs%.js}; \
		( tools/pack-asmjs $$t.js /tmp/$$t.wasm || \
		  ( echo "Failure running:  tools/pack-asmjs $$t.js /tmp/$$t.wasm" && false) ) && \
		\
		( tools/unpack-asmjs /tmp/$$t.wasm /tmp/$$t.js || \
		  ( echo "Failure running:  tools/unpack-asmjs /tmp/$$t.wasm /tmp/$$t.js" && false) ) && \
		\
		( diff $$t.js /tmp/$$t.js || \
		  ( echo "Failure running:  diff $$t.js /tmp/$$t.js" && false) ); \
		\
		true; \
	done

.PHONY: clean
clean:
	rm -f tools/pack-asmjs tools/pack-asmjs-v8 tools/unpack-asmjs
	rmdir tools
