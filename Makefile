.POSIX:
export ROOTDIR ?= $(eval ROOTDIR := $(shell git rev-parse --show-toplevel))$(ROOTDIR)
include $(ROOTDIR)/make.mk

.DEFAULT_GOAL := lint

ASDF_VERSION ?= v0.18.0
.PHONY: prepare prepare/asdf prepare/cloc prepare/stow
prepare: sudo
	@command -v asdf >/dev/null 2>&1 || $(MAKE) prepare/asdf
	@command -v cloc >/dev/null 2>&1 || $(MAKE) prepare/cloc
	@command -v stow >/dev/null 2>&1 || $(MAKE) prepare/stow
	@awk '!/^#/ && NF {print $$1}' .tool-versions | \
		while read t; do asdf plugin add "$$t" 2>/dev/null || true; done
	@rcfile=$$(mktemp); \
		{ asdf install 2>&1; echo $$? >$$rcfile; } | grep --line-buffered -v 'is already installed' || true; \
		rc=$$(cat $$rcfile); rm -f $$rcfile; exit $$rc
prepare/asdf:
	@command -v brew >/dev/null 2>&1 && brew install asdf || { \
		o=$$(uname | tr A-Z a-z); a=$$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/'); \
		curl -fsSL "https://github.com/asdf-vm/asdf/releases/download/$(ASDF_VERSION)/asdf-$(ASDF_VERSION)-$$o-$$a.tar.gz" \
			| $(SUDO) tar -xz -C /usr/local/bin asdf; \
	}
prepare/cloc:
	@$(PKG_INSTALL) cloc
prepare/stow:
	@$(PKG_INSTALL) stow

.PHONY: configure
configure:
	@for cmd in $(GIT) stow $(SHFMT) $(BATS) $(GORELEASER) $(CLOC); do \
		command -v $$cmd >/dev/null 2>&1 || { echo "$$cmd is missing, run 'make prepare'"; exit 1; }; \
	done

.PHONY: format
format: configure
	@$(SHFMT) -w .

.PHONY: lint
lint: configure
	@$(SHFMT) -d .
	@sh -n dotstow.sh
	@sh -n install.sh

.PHONY: test
test: configure
	@$(BATS) tests

.PHONY: count
count: configure
	@$(CLOC) $$($(GIT) ls-files)

.PHONY: package
package: configure
	@$(GORELEASER) release --snapshot --clean --skip=announce,publish,validate

PREFIX ?= /usr/local
DESTDIR ?=
bindir := $(DESTDIR)$(PREFIX)/bin

.PHONY: install
install:
	@$(SUDO) install -d $(bindir)
	@$(SUDO) install -m 755 dotstow.sh $(bindir)/dotstow

.PHONY: uninstall
uninstall:
	@$(SUDO) rm -f $(bindir)/dotstow

.PHONY: clean
clean:
	@rm -rf dist $(MAKEDIR)

.PHONY: purge
purge: clean
	@$(GIT) clean -fxd
