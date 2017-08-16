SHELL := /bin/bash
CWD := $(shell pwd)

all: env

start:
	@python ./dot/ --help

env:
	@virtualenv env
	@env/bin/pip install -r ./requirements.txt
	@echo created virtualenv

.PHONY: freeze
freeze:
	@env/bin/pip freeze > ./requirements.txt
	@echo froze requirements

.PHONY: clean
clean:
	-@rm -rf ./env ./*/*.pyc ./*/*/*.pyc &>/dev/null || true
	@echo cleaned
