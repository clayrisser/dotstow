# File: /Makefile
# Project: dotstow
# File Created: 22-05-2022 06:43:47
# Author: Clay Risser
# -----
# Last Modified: 22-05-2022 07:03:20
# Modified By: Clay Risser
# -----
# Risser Labs LLC (c) Copyright 2022
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

.DEFAULT_GOAL := help

DOTFILES_PATH ?= $(HOME)/.dotfiles

XDG_STATE_HOME ?= $(HOME)/.local/state
STATE_PATH ?= $(XDG_STATE_HOME)/dotstow
REPO_PATH ?= $(_STATE_PATH)/repo

ifeq ($(CURDIR),$(REPO_PATH))
	DEBUG := 0
else
	DEBUG := 1
endif

APT ?= apt-get
SUDO ?= sudo
STOW ?= $(shell $(WHICH) stow || echo /bin/stow)

NULL := /dev/null
NOFAIL := 2>$(NULL) || true
NOOUT := >$(NULL) 2>$(NULL)
WHICH := command -v
ARCH := unknown
FLAVOR := unknown
PKG_MANAGER := unknown
PLATFORM := unknown
ifeq ($(OS),Windows_NT)
	HOME := $(HOMEDRIVE)$(HOMEPATH)
	PLATFORM = win32
	FLAVOR = win64
	ARCH = $(PROCESSOR_ARCHITECTURE)
	PKG_MANAGER = choco
	ifeq ($(ARCH),AMD64)
		ARCH = amd64
	endif
	ifeq ($(ARCH),ARM64)
		ARCH = arm64
	endif
	ifeq ($(PROCESSOR_ARCHITECTURE),x86)
		ARCH = amd64
		ifeq (,$(PROCESSOR_ARCHITEW6432))
			ARCH = x86
			FLAVOR := win32
		endif
	endif
else
	PLATFORM = $(shell uname 2>$(NULL) | tr '[:upper:]' '[:lower:]' 2>$(NULL))
	ARCH = $(shell (dpkg --print-architecture 2>$(NULL) || uname -m 2>$(NULL) || arch 2>$(NULL) || echo unknown) | tr '[:upper:]' '[:lower:]' 2>$(NULL))
	ifeq ($(ARCH),i386)
		ARCH = 386
	endif
	ifeq ($(ARCH),i686)
		ARCH = 386
	endif
	ifeq ($(ARCH),x86_64)
		ARCH = amd64
	endif
	ifeq ($(PLATFORM),linux) # LINUX
		ifneq (,$(wildcard /system/bin/adb))
			ifneq ($(shell getprop --help >$(NULL) 2>$(NULL) && echo 1 || echo 0),1)
				PLATFORM = android
			endif
		endif
		ifeq ($(PLATFORM),linux)
			FLAVOR = $(shell lsb_release -si 2>$(NULL) | tr '[:upper:]' '[:lower:]' 2>$(NULL))
			ifeq (,$(FLAVOR))
				FLAVOR = unknown
				ifneq (,$(wildcard /etc/redhat-release))
					FLAVOR = rhel
				endif
				ifneq (,$(wildcard /etc/SuSE-release))
					FLAVOR = suse
				endif
				ifneq (,$(wildcard /etc/debian_version))
					FLAVOR = debian
				endif
				ifeq ($(shell cat /etc/os-release 2>$(NULL) | grep -qE "^ID=alpine$$"),ID=alpine)
					FLAVOR = alpine
				endif
			endif
			ifeq ($(FLAVOR),rhel)
				PKG_MANAGER = yum
			endif
			ifeq ($(FLAVOR),suse)
				PKG_MANAGER = zypper
			endif
			ifeq ($(FLAVOR),debian)
				PKG_MANAGER = apt-get
			endif
			ifeq ($(FLAVOR),ubuntu)
				PKG_MANAGER = apt-get
			endif
			ifeq ($(FLAVOR),alpine)
				PKG_MANAGER = apk
			endif
		endif
	else
		ifneq (,$(findstring CYGWIN,$(PLATFORM))) # CYGWIN
			PLATFORM = win32
			FLAVOR = cygwin
		endif
		ifneq (,$(findstring MINGW,$(PLATFORM))) # MINGW
			PLATFORM = win32
			FLAVOR = msys
			PKG_MANAGER = mingw-get
		endif
		ifneq (,$(findstring MSYS,$(PLATFORM))) # MSYS
			PLATFORM = win32
			FLAVOR = msys
			PKG_MANAGER = pacman
		endif
	endif
	ifeq ($(PLATFORM),darwin)
		PKG_MANAGER = brew
	endif
endif

define not_supported
	echo $1 installer for $(FLAVOR) $(PLATFORM) is not not supported && exit 1
endef


.PHONY: sudo
sudo:
	@$(SUDO) true

define not_supported
echo $1 installer for $(FLAVOR) $(PLATFORM) is not not supported && exit 1
endef
.PHONY: not-supported
not-supported:
	@$(call not_supported,$(NAME))

$(STOW):
ifeq ($(PKG_MANAGER),apt-get)
	@$(SUDO) $(APT) install -y stow
else
	@$(call not_supported,$(NAME))
endif

DOTFILES := $(shell ls $(DOTFILES_PATH)/$(PLATFORM) $(NOFAIL)) \
	$(shell ls $(DOTFILES_PATH)/$(FLAVOR) $(NOFAIL)) \
	$(shell ls $(DOTFILES_PATH)/global $(NOFAIL))

.PHONY: $(DOTFILES)
$(DOTFILES): $(STOW) $(DOTFILES_PATH)/.git/HEAD
	@PACKAGE_DIR='$(call get_package_dir,$@)' && \
		[ "$$PACKAGE_DIR" = "" ] && true || \
		stow -t $(HOME) -d $$PACKAGE_DIR $(ARGS) $@

.PHONY: stow
stow:
	@$(MAKE) -s $(PACKAGE)

.PHONY: unstow
unstow:
	@$(MAKE) -s $(PACKAGE) ARGS="-D"

.PHONY: restow
restow:
	@$(MAKE) -s $(PACKAGE) ARGS="-R"

define get_package_dir
$(shell cd $(DOTFILES_PATH) && \
	PACKAGE_DIR=$$( (((ls $(FLAVOR) $(NOFAIL)) | grep -qE "^$1$$") && echo $(FLAVOR)) || \
	(((ls $(PLATFORM) $(NOFAIL)) | grep -qE "^$1$$") && echo $(PLATFORM)) || \
	(((ls global $(NOFAIL)) | grep -qE "^$1$$") && echo global) || true) && \
	([ "$$PACKAGE_DIR" = "" ] && true || (cd $$PACKAGE_DIR && pwd)))
endef

.PHONY: help
help: ;

$(DOTFILES_PATH)/.git/HEAD:
	@cp -r $(CURDIR) $(DOTFILES_PATH)
