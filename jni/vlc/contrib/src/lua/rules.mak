# Lua 5.1

LUA_VERSION := 5.1.4
LUA_URL := http://www.lua.org/ftp/lua-$(LUA_VERSION).tar.gz

# Reverse priority order
LUA_TARGET := generic
ifdef HAVE_BSD
LUA_TARGET := bsd
endif
ifdef HAVE_LINUX
LUA_TARGET := linux
endif
ifdef HAVE_MACOSX
LUA_TARGET := macosx
endif
ifdef HAVE_WIN32
LUA_TARGET := mingw
endif

# Feel free to add autodetection if you need to...
PKGS += lua

$(TARBALLS)/lua-$(LUA_VERSION).tar.gz:
	$(call download,$(LUA_URL))

.sum-lua: lua-$(LUA_VERSION).tar.gz

lua: lua-$(LUA_VERSION).tar.gz .sum-lua
	$(UNPACK)
	(cd $@-$(LUA_VERSION) && patch -p1) < $(SRC)/lua/lua-noreadline.patch
ifdef HAVE_MACOSX
	(cd $@-$(LUA_VERSION) && \
	sed -e 's%gcc%$(CC)%' \
		-e 's%LDFLAGS=%LDFLAGS=$(EXTRA_CFLAGS) $(EXTRA_LDFLAGS)%' \
		-i.orig src/Makefile)
endif
ifdef HAVE_WIN32
	cd $@-$(LUA_VERSION) && sed -i.orig -e 's/lua luac/lua.exe/' Makefile
endif
	cd $@-$(LUA_VERSION)/src && sed -i.orig \
		-e 's/CC=/#CC=/' \
		-e 's/= *strip/=$(STRIP)/' \
		-e 's/= *ranlib/= $(RANLIB)/' \
		Makefile
	mv $@-$(LUA_VERSION) $@
	touch $@

.lua: lua
	cd $< && $(HOSTVARS) $(MAKE) $(LUA_TARGET)
ifdef HAVE_WIN32
	cd $</src && $(HOSTVARS) $(MAKE) liblua.a
endif
	cd $< && $(HOSTVARS) $(MAKE) install INSTALL_TOP="$(PREFIX)"
ifdef HAVE_WIN32
	cd $< && $(RANLIB) "$(PREFIX)/lib/liblua.a"
	mkdir -p -- "$(PREFIX)/lib/pkgconfig"
	cp $</etc/lua.pc "$(PREFIX)/lib/pkgconfig"
endif
	touch $@