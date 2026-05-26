.POSIX:
export ROOTDIR ?= $(eval ROOTDIR := $(shell git rev-parse --show-toplevel))$(ROOTDIR)
include $(ROOTDIR)/make.mk

.DEFAULT_GOAL := build

PREFIX ?= /usr/local
DESTDIR ?=

BUILD_BIN := $(ROOTDIR)/build/usr/bin

.PHONY: sudo
sudo:
	@$(SUDO) true

.PHONY: prepare prepare/asdf
prepare:
	@command -v asdf >/dev/null 2>&1 || $(MAKE) prepare/asdf
	@awk '!/^#/ && NF {print $$1}' .tool-versions | \
		while read t; do asdf plugin add "$$t" 2>/dev/null || true; done
	@asdf install
prepare/asdf:
	@command -v brew >/dev/null 2>&1 && brew install asdf || { \
		o=$$(uname | tr A-Z a-z); a=$$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/'); \
		curl -fsSL "https://github.com/asdf-vm/asdf/releases/download/v0.18.0/asdf-v0.18.0-$$o-$$a.tar.gz" \
			| $(SUDO) tar -xz -C /usr/local/bin asdf; \
	}

.PHONY: configure
configure:
	@for cmd in $(GORELEASER); do \
		command -v $$cmd >/dev/null 2>&1 || { echo "$$cmd is missing, run 'make prepare'"; exit 1; }; \
	done

# Stage dotstow.sh → build/usr/bin/dotstow (no extension, mode 0755).
.PHONY: build
build: configure
	@rm -rf $(BUILD_BIN)
	@mkdir -p $(BUILD_BIN)
	@install -m 0755 dotstow.sh $(BUILD_BIN)/dotstow

.PHONY: package
package: configure
	@$(GORELEASER) release --snapshot --clean --skip=announce,publish,validate

.PHONY: format
format:
	@command -v $(SHFMT) >/dev/null 2>&1 || { echo "shfmt missing, run 'make prepare'"; exit 1; }
	@$(SHFMT) -w dotstow.sh

.PHONY: lint
lint:
	@command -v $(SHFMT) >/dev/null 2>&1 || { echo "shfmt missing, run 'make prepare'"; exit 1; }
	@$(SHFMT) -d dotstow.sh
	@sh -n dotstow.sh

.PHONY: clean
clean:
	@rm -rf $(ROOTDIR)/build $(ROOTDIR)/dist $(MAKEDIR)

.PHONY: purge
purge: clean
	@$(GIT) clean -fxd

# ---------- legacy user-facing install (kept for source installs) ----------

.PHONY: install
install: $(DESTDIR)$(PREFIX)/bin/dotstow

$(DESTDIR)$(PREFIX)/bin/dotstow: dotstow.sh
	@$(SUDO) mkdir -p $(@D)
	@$(SUDO) cp $< $@
	@$(SUDO) chmod +x $@

.PHONY: uninstall
uninstall:
	@$(SUDO) rm -f $(DESTDIR)$(PREFIX)/bin/dotstow
