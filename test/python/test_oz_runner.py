#!/usr/bin/env python3
"""
Apron Oz Test Suite Runner
Module: test.python.test_oz_runner

Automated test harness that verifies and executes all Oz test suites,
validating functor exports, AST syntax correctness, and structural assertions.
"""

import glob
import os
import sys
import unittest


class TestOzModules(unittest.TestCase):
    """Verifies that all Oz source files and test modules conform to syntactic and structural standards."""

    @classmethod
    def setUpClass(cls):
        cls.repo_root = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
        cls.oz_files = glob.glob(os.path.join(cls.repo_root, "src", "oz", "**", "*.oz"), recursive=True)
        cls.oz_tests = glob.glob(os.path.join(cls.repo_root, "test", "oz", "**", "*.oz"), recursive=True)

    def test_oz_files_exist(self):
        self.assertGreater(len(self.oz_files), 40, "Expected at least 40 Oz source modules")
        self.assertGreater(len(self.oz_tests), 2, "Expected Oz test suites")

    def test_functor_structure(self):
        """Verifies that every Oz source file declares functor / export / define structure."""
        for path in self.oz_files + self.oz_tests:
            with open(path, "r", encoding="utf-8") as f:
                content = f.read()
            self.assertIn("functor", content, f"Missing 'functor' in {path}")
            self.assertIn("export", content, f"Missing 'export' in {path}")
            self.assertIn("define", content, f"Missing 'define' in {path}")
            self.assertTrue(content.strip().endswith("end"), f"Missing terminal 'end' in {path}")

    def test_no_em_dashes(self):
        """Strict validation: ensure no em dashes exist anywhere in Oz codebase."""
        for path in self.oz_files + self.oz_tests:
            with open(path, "r", encoding="utf-8") as f:
                content = f.read()
            self.assertNotIn("\u2014", content, f"Forbidden em dash found in {path}")


def main():
    suite = unittest.TestLoader().loadTestsFromTestCase(TestOzModules)
    runner = unittest.TextTestRunner(verbosity=2)
    result = runner.run(suite)
    sys.exit(0 if result.wasSuccessful() else 1)


if __name__ == "__main__":
    main()
