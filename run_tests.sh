#!/usr/bin/env bash
set -e

echo "======================================================================="
echo "   APRON VERIFICATION HARNESS: Comprehensive Test Suite"
echo "======================================================================="

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${REPO_DIR}"

# 1. Enforce No Em Dashes rule across all text files
echo "[1/5] Verifying zero em dashes across entire repository..."
python3 -c "
import glob, sys
violations = []
for f in glob.glob('**/*', recursive=True):
    if f.startswith(('.git/', 'build/')): continue
    if f.endswith(('.oz', '.c', '.h', '.py', '.json', '.xml', '.md', '.txt', '.sh', 'CMakeLists.txt', 'Makefile')):
        try:
            content = open(f, 'r', encoding='utf-8').read()
            if '\u2014' in content:
                violations.append(f)
        except Exception:
            pass
if violations:
    print('ERROR: Em dash (\\u2014) violations detected in:')
    for v in violations:
        print('  -', v)
    sys.exit(1)
print('  OK: Zero em dashes detected.')
"

# 2. Build C11 engine and tests
echo "[2/5] Building C11 fastpath engine and OzVM..."
mkdir -p build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release > /dev/null
make -j$(sysctl -n hw.ncpu 2>/dev/null || nproc 2>/dev/null || echo 4)
cd ..

# 3. Execute C unit tests via CTest
echo "[3/5] Executing C11 test suite via ctest..."
cd build && ctest --output-on-failure && cd ..

# 4. Execute Python test runners
echo "[4/5] Executing Oz and Python test runners..."
python3 test/python/test_oz_runner.py
python3 test/python/test_integration.py
python3 test/python/test_scenarios.py

# 5. Run Micro-benchmarks
echo "[5/5] Executing micro-benchmark suite..."
python3 tools/run_benchmarks.py

echo "======================================================================="
echo "   ALL TEST SUITES PASSED (100% SUCCESS, 0 REGRESSIONS)"
echo "======================================================================="
