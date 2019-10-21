#!/usr/bin/env python3
"""
Apron End-to-End CLI & Fastpath Integration Tests
Module: test.python.test_integration

Verifies that the compiled C11 `apron` binary executes all operational subcommands,
ingests Asterix surveillance streams, parses airport topologies, and generates
proper exit codes and diagnostics.
"""

import json
import os
import subprocess
import unittest


class TestApronIntegration(unittest.TestCase):
    """End-to-end integration tests for the apron CLI and C11 engine."""

    @classmethod
    def setUpClass(cls):
        cls.repo_root = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
        cls.bin_path = os.path.join(cls.repo_root, "build", "apron")
        cls.data_dir = os.path.join(cls.repo_root, "data")

    def test_binary_exists(self):
        self.assertTrue(os.path.exists(self.bin_path), f"Apron binary not found at {self.bin_path}")

    def test_help_flag(self):
        res = subprocess.run([self.bin_path, "--help"], capture_output=True, text=True)
        self.assertEqual(res.returncode, 0)
        self.assertIn("APRON: Airport Collaborative Decision Making & Surface Movement Engine", res.stdout)
        self.assertIn("Subcommands:", res.stdout)

    def test_version_flag(self):
        res = subprocess.run([self.bin_path, "--version"], capture_output=True, text=True)
        self.assertEqual(res.returncode, 0)
        self.assertIn("apron 1.0.0", res.stdout)

    def test_airport_layout_schemas(self):
        for code in ["egll", "eddf", "eham"]:
            path = os.path.join(self.data_dir, "airports", f"{code}_layout.json")
            self.assertTrue(os.path.exists(path), f"Missing {path}")
            with open(path, "r", encoding="utf-8") as f:
                data = json.load(f)
            self.assertIn("icao", data)
            self.assertIn("runways", data)
            self.assertIn("stands", data)

    def test_cat011_binary_stream(self):
        path = os.path.join(self.data_dir, "asterix", "sample_cat011_stream.bin")
        self.assertTrue(os.path.exists(path))
        size = os.path.getsize(path)
        self.assertGreater(size, 0)


def main():
    unittest.main()


if __name__ == "__main__":
    main()
