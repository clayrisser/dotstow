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

dist: env
	@python setup.py sdist
	@python setup.py bdist_wheel
	@echo ran dist

.PHONY: publish
publish: dist
	@twine upload dist/*
	@echo published

.PHONY: clean
clean:
	-@rm -rf ./env ./dist ./build ./dotcli.egg-info ./*/*.pyc ./*/*/*.pyc &>/dev/null || true
	@echo cleaned
