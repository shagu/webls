all: build

build:
	./webls.lua

debug:
	while inotifywait -e modify . ; do ./webls.lua; sleep 2; done
