# =============================================================================
# Apron Top-Level Build and Test Makefile
# =============================================================================

BUILD_DIR ?= build
CMAKE ?= cmake

.PHONY: all build test clean bench check-dashes help

all: build

build:
	@mkdir -p $(BUILD_DIR)
	@cd $(BUILD_DIR) && $(CMAKE) .. -DCMAKE_BUILD_TYPE=Release
	@$(MAKE) -C $(BUILD_DIR)

test: build
	@bash ./run_tests.sh

check-dashes:
	@python3 -c "import glob, sys; violations = [f for f in glob.glob('**/*', recursive=True) if not f.startswith(('.git/', 'build/')) and f.endswith(('.oz', '.c', '.h', '.py', '.json', '.xml', '.md', '.txt', '.sh', 'CMakeLists.txt', 'Makefile')) and '\u2014' in open(f, 'r', encoding='utf-8').read()]; sys.exit(1) if violations else print('All files verified clean of em dashes.')"

bench: build
	@python3 tools/run_benchmarks.py

clean:
	@rm -rf $(BUILD_DIR)

help:
	@echo "Apron Build Targets:"
	@echo "  make build         Compile C11 fastpath engine and OzVM"
	@echo "  make test          Execute full CTest, Oz, and Python test suites"
	@echo "  make bench         Execute micro-benchmarks"
	@echo "  make check-dashes  Verify strict absence of em dashes across codebase"
	@echo "  make clean         Remove build artifacts"
