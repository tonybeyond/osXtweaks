LUA ?= lua5.4
LUAC ?= luac5.4

.PHONY: check test

check:
	@$(LUAC) -p init.lua modules/*.lua && echo "syntaxe OK"
	@bash -n install.sh && echo "install.sh OK"

test: check
	@$(LUA) test/stub_test.lua
