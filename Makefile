# File: /Makefile
# Project: dotstow
# File Created: 22-05-2022 06:43:47
# Author: Clay Risser
# -----
# Last Modified: 27-02-2023 12:08:42
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

export NOCOLOR=\033[0m
export RED=\033[0;31m
export GREEN=\033[0;32m
export ORANGE=\033[0;33m
export BLUE=\033[0;34m
export PURPLE=\033[0;35m
export CYAN=\033[0;36m
export LIGHTGRAY=\033[0;37m
export DARKGRAY=\033[1;30m
export LIGHTRED=\033[1;31m
export LIGHTGREEN=\033[1;32m
export YELLOW=\033[1;33m
export LIGHTBLUE=\033[1;34m
export LIGHTPURPLE=\033[1;35m
export LIGHTCYAN=\033[1;36m
export WHITE=\033[1;37m

export BANG := \!
export NOFAIL := 2>$(NULL) || $(TRUE)
export NOOUT := >$(NULL) 2>$(NULL)
export NULL := /dev/null

export CAT := cat
export CD := cd
export CHMOD := chmod
export CP := cp
export CUT := cut
export DU := du
export ECHO := echo
export EXIT := exit
export EXPORT := export
export FALSE := false
export HEAD := head
export MKDIR := mkdir
export RM := rm
export SORT := sort
export TOUCH := touch
export TR := tr
export TRUE := true
export UNIQ := uniq
export WHICH := command -v

export ARCH := unknown
export FLAVOR := unknown
export PKG_MANAGER := unknown
export PLATFORM := unknown
ifeq ($(OS),Windows_NT)
	export HOME := $(HOMEDRIVE)$(HOMEPATH)
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
	PLATFORM = $(shell uname 2>$(NULL) | $(TR) '[:upper:]' '[:lower:]' 2>$(NULL))
	ARCH = $(shell (dpkg --print-architecture 2>$(NULL) || uname -m 2>$(NULL) || arch 2>$(NULL) || echo unknown) | $(TR) '[:upper:]' '[:lower:]' 2>$(NULL))
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
			FLAVOR = $(shell lsb_release -si 2>$(NULL) | $(TR) '[:upper:]' '[:lower:]' 2>$(NULL))
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
				ifeq ($(shell cat /etc/os-release 2>$(NULL) | grep -E "^ID=alpine$$"),ID=alpine)
					FLAVOR = alpine
				endif
			endif
			ifeq ($(FLAVOR),rhel)
				PKG_MANAGER = $(call ternary,$(WHICH) microdnf,microdnf,$(call ternary,$(WHICH) dnf,dnf,yum))
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

.PHONY: install
install: /usr/local/bin/dotstow \
	/usr/bin/stow
/usr/local/bin/dotstow: dotstow.sh
	@sudo cp $< $@
	@sudo chmod +x $@
/usr/bin/stow:
ifeq ($(PKG_MANAGER),apt-get)
	@sudo apt-get install -y stow
else
	@echo "$(ORANGE)please install the stow command$(NOCOLOR)\n$(CYAN)https://www.gnu.org/software/stow$(NOCOLOR)" >&2
endif

.PHONY: uninstall
uninstall:
	@sudo rm /usr/local/bin/dotstow

.PHONY: help
help: ;
