#!/usr/bin/env python3
"""Offline unit tests for validate_skills_spec.py, using a fake reference validator."""

from __future__ import annotations

import contextlib
import io
import json
import os
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock

import validate_skills_spec

# Stands in for the reference validator: `<fake> validate <skill_dir>` replays
# the exit code and output stored in <skill_dir>/fake.json.
FAKE_VALIDATOR = """
import json, sys
from pathlib import Path
reply = json.loads((Path(sys.argv[2]) / "fake.json").read_text())
sys.stdout.write(reply["output"])
sys.exit(reply["code"])
"""

ALLOWED = "Only ['allowed-tools', 'compatibility', 'description', 'license', 'metadata', 'name'] are allowed."


def failed(*problems: str) -> str:
    """Return validator output reporting the given problems; {path} names the skill."""
    return "\n".join(["Validation failed for {path}:", *(f"  - {p}" for p in problems)]) + "\n"


def unexpected(*fields: str) -> str:
    """Return the validator's message for frontmatter fields outside the specification."""
    return f"Unexpected fields in frontmatter: {', '.join(fields)}. {ALLOWED}"


class ValidateSkillsSpecTest(unittest.TestCase):
    """Behavioral tests for the reference-validator wrapper."""

    def setUp(self) -> None:
        self._tempdir = tempfile.TemporaryDirectory()
        self.addCleanup(self._tempdir.cleanup)
        self.root = Path(self._tempdir.name)
        self.skills = self.root / "skills"
        self.skills.mkdir()
        fake = self.root / "fake_validator.py"
        fake.write_text(FAKE_VALIDATOR)
        self.command = [sys.executable, str(fake)]

    def skill(self, name: str, code: int, output: str) -> Path:
        """Create a skill whose validator run replays the result; {path} in output names it."""
        path = self.skills / name
        path.mkdir()
        output = output.replace("{path}", str(path))
        (path / "fake.json").write_text(json.dumps({"code": code, "output": output}))
        return path

    def check(self, path: Path) -> list[str]:
        return validate_skills_spec.check_skill(self.command, path)

    def run_main(self, command: list[str] | None, ci: str | None = None) -> tuple[int, str, str]:
        """Run main with the given validator command and CI value, capturing its output."""
        env = {key: value for key, value in os.environ.items() if key != "CI"}
        if ci is not None:
            env["CI"] = ci
        stdout, stderr = io.StringIO(), io.StringIO()
        with mock.patch.dict(os.environ, env, clear=True), \
                mock.patch.object(validate_skills_spec, "validator_command", return_value=command), \
                contextlib.redirect_stdout(stdout), contextlib.redirect_stderr(stderr):
            status = validate_skills_spec.main([str(self.skills)])
        return status, stdout.getvalue(), stderr.getvalue()

    def test_valid_skill_passes(self) -> None:
        path = self.skill("valid", 0, "Valid skill: valid\n")
        self.assertEqual(self.check(path), [])

    def test_client_fields_are_accepted(self) -> None:
        path = self.skill("client", 1, failed(unexpected("disable-model-invocation", "user-invocable")))
        self.assertEqual(self.check(path), [])

    def test_non_client_field_is_an_error_naming_only_that_field(self) -> None:
        path = self.skill("mixed", 1, failed(unexpected("user-invocable", "colour")))
        errors = self.check(path)
        self.assertEqual(len(errors), 1)
        self.assertIn("colour", errors[0])
        self.assertNotIn("user-invocable", errors[0])

    def test_other_problems_are_errors_alongside_accepted_client_fields(self) -> None:
        path = self.skill("named", 1, failed(unexpected("user-invocable"), "Skill name must be lowercase"))
        self.assertEqual(self.check(path), [f"{path}: Skill name must be lowercase"])

    def test_unrecognized_failure_output_is_an_error(self) -> None:
        path = self.skill("garbled", 2, "Traceback (most recent call last):\n  boom\n")
        errors = self.check(path)
        self.assertEqual(len(errors), 1)
        self.assertIn("unrecognized output", errors[0])

    def test_unrecognized_problem_line_is_an_error(self) -> None:
        path = self.skill("reworded", 1, "Validation failed for {path}:\n  * a reworded bullet\n")
        self.assertIn("unrecognized validator output line", self.check(path)[0])

    def test_failure_without_problems_is_an_error(self) -> None:
        path = self.skill("silent", 1, failed())
        self.assertIn("without reporting a problem", self.check(path)[0])

    def test_pass_with_unrecognized_output_is_an_error(self) -> None:
        path = self.skill("odd", 0, "All good\n")
        self.assertIn("unrecognized output", self.check(path)[0])

    def test_main_reports_every_skill_ok(self) -> None:
        self.skill("one", 0, "Valid skill: one\n")
        self.skill("two", 1, failed(unexpected("user-invocable")))
        status, stdout, stderr = self.run_main(self.command)
        self.assertEqual(status, 0)
        self.assertEqual(stdout.strip(), "validate_skills_spec: 2 skill(s) OK")
        self.assertEqual(stderr, "")

    def test_main_fails_and_counts_errors(self) -> None:
        self.skill("bad", 1, failed("Missing description"))
        status, _, stderr = self.run_main(self.command)
        self.assertEqual(status, 1)
        self.assertIn("Missing description", stderr)
        self.assertIn("validate_skills_spec: 1 error(s) in 1 skill(s)", stderr)

    def test_missing_validator_skips_locally(self) -> None:
        for ci in (None, "", "false", "0"):
            with self.subTest(ci=ci):
                status, stdout, _ = self.run_main(None, ci=ci)
                self.assertEqual(status, 0)
                self.assertIn("skipping specification validation", stdout)
                self.assertIn(validate_skills_spec.PINNED_PACKAGE, stdout)

    def test_missing_validator_fails_under_ci(self) -> None:
        status, _, stderr = self.run_main(None, ci="true")
        self.assertEqual(status, 1)
        self.assertIn("agentskills or skills-ref not found", stderr)

    def test_validator_command_prefers_agentskills(self) -> None:
        found = {"agentskills": "/bin/agentskills", "skills-ref": "/bin/skills-ref"}
        with mock.patch.object(validate_skills_spec.shutil, "which", side_effect=found.get):
            self.assertEqual(validate_skills_spec.validator_command(), ["/bin/agentskills"])
        with mock.patch.object(validate_skills_spec.shutil, "which", side_effect={"skills-ref": "/bin/skills-ref"}.get):
            self.assertEqual(validate_skills_spec.validator_command(), ["/bin/skills-ref"])
        with mock.patch.object(validate_skills_spec.shutil, "which", return_value=None):
            self.assertIsNone(validate_skills_spec.validator_command())


if __name__ == "__main__":
    unittest.main()
