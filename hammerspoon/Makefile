# Détection automatique du binaire Lua (Homebrew installe "lua", Debian "lua5.4")
LUA  ?= $(shell command -v lua5.4  2>/dev/null || command -v lua)
LUAC ?= $(shell command -v luac5.4 2>/dev/null || command -v luac)

.PHONY: check test help

help:
	@echo "make check  - verification syntaxique (luac -p, bash -n)"
	@echo "make test   - execute la suite de tests contre un stub de l'API hs"

check:
	@test -n "$(LUAC)" || { echo "luac introuvable : brew install lua" >&2; exit 1; }
	@$(LUAC) -p init.lua modules/*.lua && echo "syntaxe Lua OK"
	@bash -n install.sh && echo "install.sh OK"

test: check
	@test -n "$(LUA)" || { echo "lua introuvable : brew install lua" >&2; exit 1; }
	@$(LUA) test/stub_test.lua
