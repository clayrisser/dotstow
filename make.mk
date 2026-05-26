MAKEFLAGS += --no-print-directory

MAKEDIR := $(ROOTDIR)/.make
MARKERS := $(MAKEDIR)/markers

-include $(MAKEDIR)/env.mk

# Recipes spawn fresh non-interactive shells that don't source ~/.zshrc, so
# the asdf shim dir isn't on PATH unless we add it here.
export PATH := $(or $(ASDF_DATA_DIR),$(HOME)/.asdf)/shims:$(PATH)

# Tool defaults — overridable via env.
GIT ?= git
SHFMT ?= shfmt
GORELEASER ?= goreleaser

# Lazy-eval: shell only runs once, on first reference, then cached.
SUDO ?= $(eval SUDO := $(shell command -v sudo >/dev/null 2>&1 && echo sudo))$(SUDO)
PKG_INSTALL ?= $(eval PKG_INSTALL := $(or \
	$(shell command -v brew >/dev/null 2>&1 && echo 'brew install'), \
	$(shell command -v apt-get >/dev/null 2>&1 && echo '$(SUDO) apt-get update && $(SUDO) apt-get install -y'), \
	$(shell command -v dnf >/dev/null 2>&1 && echo '$(SUDO) dnf install -y'), \
	$(shell command -v pacman >/dev/null 2>&1 && echo '$(SUDO) pacman -S --noconfirm'), \
	echo "no supported package manager" >&2;false))$(PKG_INSTALL)

.PHONY: FORCE
FORCE:
