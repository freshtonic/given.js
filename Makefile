
SRC_COFFEE  = $(shell find src -name \*.coffee)
TARGET_JS 	= $(subst src/, build/, $(addsuffix .js, $(basename $(SRC_COFFEE))))

SPEC_COFFEE = $(shell find spec -name \*.coffee)
SPEC_JS 	= $(subst spec/, build/, $(addsuffix .js, $(basename $(SPEC_COFFEE))))

CHECK_COFFEE = $(shell find check -name \*.coffee)
CHECK_JS 	= $(subst check/, build/, $(addsuffix .js, $(basename $(CHECK_COFFEE))))

DIST = lib/given.js

# RULES

build/%.js: src/%.coffee
	@echo COMPILE: $<
	@node_modules/coffee-script/bin/coffee --nodejs --no-deprecation  -o $(subst src, build, $(dir $@)) -c $<

build/%.js: spec/%.coffee
	@echo COMPILE: $<
	@node_modules/coffee-script/bin/coffee --nodejs --no-deprecation  -o $(subst src, build, $(dir $@)) -c $<

build/%.js: check/%.coffee
	@echo COMPILE: $<
	@node_modules/coffee-script/bin/coffee --nodejs --no-deprecation  -o $(subst src, build, $(dir $@)) -c $<

# TARGETS

$(DIST): $(TARGET_JS)
	@cat $^ > $@

README.md: README.md.raw spec/given.spec.coffee build/given.spec.js
	@bin/make-readme

# TASKS

compile: $(DIST)

spec: $(DIST) $(SPEC_JS)
	@echo SPEC: $(SPEC_JS)
	@node_modules/jasmine-node/bin/jasmine-node $(SPEC_JS)

check: $(DIST) $(CHECK_JS)
	@echo CHECK: $(CHECK_JS)
	@node $(CHECK_JS)

clean:
	@rm -fr build/* README.md

watch-spec:
	-@make spec
	@wach -o src/*.coffee,spec/*.coffee, make compile spec

watch-check:
	-@make check
	@wach -o src/*.coffee,check/*.coffee, make compile check 

all: compile spec README.md 

.PHONY: all compile spec clean watch-spec watch-check check

.DEFAULT: all
