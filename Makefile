# File: /Makefile
# Project: dotstow
# File Created: 22-05-2022 06:43:47
# Author: Clay Risser
# -----
# Last Modified: 27-02-2023 02:15:50
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

.PHONY: install
install: /usr/local/bin/dotstow
/usr/local/bin/dotstow: dotstow.sh
	@sudo cp $< $@
	@sudo chmod +x $@

.PHONY: uninstall
uninstall:
	@sudo rm /usr/local/bin/dotstow

.PHONY: help
help: ;
