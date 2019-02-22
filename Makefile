CC ?= gcc
CFLAGS ?= -Wall -Wextra -Wpedantic -O3 -g -Iinclude -D_GNU_SOURCE
LDFLAGS ?= -lm

BUILD_DIR = build
BIN_DIR = $(BUILD_DIR)/bin

.PHONY: all build test test-c test-oz test-e2e clean bench help

all: build

build:
	@mkdir -p $(BUILD_DIR)
	@cd $(BUILD_DIR) && cmake .. && $(MAKE) --no-print-directory

test: test-c test-oz test-e2e

test-c: build
	@echo "=== Running C11 VM and Fastpath Unit Tests ==="
	@cd $(BUILD_DIR) && ctest --output-on-failure

test-oz: build
	@echo "=== Running Oz Kernel and Subsystem Test Suites ==="
	@python3 test/python/test_oz_runner.py

test-e2e: build
	@echo "=== Running Multi-Airport End-to-End Simulation Tests ==="
	@python3 test/python/test_integration.py

bench: build
	@echo "=== Running Apron Performance Benchmarks ==="
	@python3 tools/run_benchmarks.py

clean:
	@rm -rf $(BUILD_DIR) bin *.o

help:
	@echo "Apron Build Targets:"
	@echo "  make build     : Build C11 Oz VM and apron CLI"
	@echo "  make test      : Execute all test suites (C, Oz, Python)"
	@echo "  make test-c    : Run C11 unit tests via ctest"
	@echo "  make test-oz   : Run Oz subsystem unit tests"
	@echo "  make test-e2e  : Run end-to-end multi-airport scenarios"
	@echo "  make bench     : Run performance benchmarks"
	@echo "  make clean     : Remove build artifacts"
