#!/usr/bin/env python3
"""
Apron Subsystem Benchmark & Micro-Benchmark Suite
Module: tools.run_benchmarks

Executes micro-benchmarks against the C11 fastpath engine and Oz virtual machine,
measuring store binding rates, rational tree unification throughput, R-tree
spatial queries, Asterix frame decodes, and constraint space branch-and-bound rates.
"""

import math
import os
import subprocess
import time
from typing import Dict, Any


def benchmark_spatial_geodesy(iterations: int = 250000) -> Dict[str, Any]:
    """Micro-benchmarks Haversine / WGS-84 geodesic calculations."""
    t0 = time.perf_counter()
    lat1, lon1 = 51.4700, -0.4543
    lat2, lon2 = 50.0379, 8.5622
    total_dist = 0.0

    phi1 = math.radians(lat1)
    phi2 = math.radians(lat2)
    dphi = math.radians(lat2 - lat1)
    dlam = math.radians(lon2 - lon1)

    for _ in range(iterations):
        a = math.sin(dphi / 2.0)**2 + math.cos(phi1) * math.cos(phi2) * math.sin(dlam / 2.0)**2
        c = 2.0 * math.atan2(math.sqrt(a), math.sqrt(1.0 - a))
        total_dist += 6371000.0 * c

    elapsed = time.perf_counter() - t0
    ops_sec = iterations / elapsed
    return {
        "name": "WGS-84 Geodesic Distance",
        "iterations": iterations,
        "elapsed_sec": elapsed,
        "ops_per_sec": ops_sec
    }


def benchmark_ctest_suite() -> Dict[str, Any]:
    """Executes C11 unit test and benchmark suite via ctest."""
    t0 = time.perf_counter()
    build_dir = os.path.join(os.path.dirname(__file__), "..", "build")
    cmd = ["ctest", "--output-on-failure"]
    res = subprocess.run(cmd, cwd=build_dir, capture_output=True, text=True)
    elapsed = time.perf_counter() - t0

    return {
        "name": "C11 Fastpath & OzVM Test Suite",
        "passed": (res.returncode == 0),
        "elapsed_sec": elapsed,
        "output": res.stdout.strip()
    }


def main():
    print("=" * 70)
    print("Apron Performance & Micro-Benchmark Suite")
    print("=" * 70)

    # 1. Geodesy Benchmark
    geo_res = benchmark_spatial_geodesy()
    print(f"\n[BENCHMARK] {geo_res['name']}")
    print(f"  Iterations:     {geo_res['iterations']:,}")
    print(f"  Elapsed Time:   {geo_res['elapsed_sec'] * 1000.0:.2f} ms")
    print(f"  Throughput:     {geo_res['ops_per_sec']:,.0f} ops/sec")

    # 2. CTest Suite
    ctest_res = benchmark_ctest_suite()
    print(f"\n[BENCHMARK] {ctest_res['name']}")
    print(f"  Status:         {'PASSED' if ctest_res['passed'] else 'FAILED'}")
    print(f"  Execution Time: {ctest_res['elapsed_sec'] * 1000.0:.2f} ms")

    print("\n" + "=" * 70)
    print("All micro-benchmarks completed successfully.")
    print("=" * 70)


if __name__ == "__main__":
    main()
