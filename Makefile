
PREFIX = $(shell pwd -P)/DIST
CMD_NAME = soundoutput

install:
	mkdir -p "$(PREFIX)/bin"
	
	cp "bin/$(CMD_NAME)" "$(PREFIX)/bin/$(CMD_NAME)"
	sed -i "" -e "s/#{PREFIX}/$(subst /,\/,$(PREFIX))/" "$(PREFIX)/bin/$(CMD_NAME)"
	
	xcodebuild -project soundoutput.xcodeproj \
		-scheme soundoutputcore \
		-configuration Release \
		SYMROOT=build \
		DSTROOT="$(PREFIX)" \
		INSTALL_PATH=/lib \
		-verbose \
		install

