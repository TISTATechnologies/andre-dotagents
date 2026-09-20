"""Offline rendering regressions for the Cursor shell status line."""

import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import unittest


REPO = Path(__file__).resolve().parents[1]


@unittest.skipUnless(
    os.name != "nt" and all(shutil.which(cmd) for cmd in ("sh", "jq", "python3", "git", "awk")),
    "requires Unix shell status-line dependencies",
)
class CursorStatuslineTests(unittest.TestCase):
    def test_model_display_is_preserved_without_appended_effort(self):
        with tempfile.TemporaryDirectory() as directory:
            home = Path(directory)
            cache = home / "cache"
            cache.mkdir()
            (cache / "cursor-statusline-usage.json").write_text(
                json.dumps({"models": 12, "api": 34}), encoding="utf-8"
            )
            env = dict(os.environ, HOME=str(home), XDG_CACHE_HOME=str(cache))
            for params in (
                {"param_summary": "(high)", "max_mode": True},
                {"param_summary": "", "max_mode": True},
                {"param_summary": "(custom effort)"},
                {},
            ):
                with self.subTest(params=params):
                    payload = {
                        "workspace": {"current_dir": str(home)},
                        "model": {"display_name": "Example Model (high)", **params},
                        "context_window": {"used_percentage": 25},
                    }
                    result = subprocess.run(
                        ["sh", str(REPO / "cursor/statusline-command.sh")],
                        input=json.dumps(payload), text=True, capture_output=True,
                        cwd=home, env=env, timeout=10,
                    )
                    self.assertEqual(result.returncode, 0, result.stderr)
                    self.assertEqual(result.stderr, "")
                    rendered = re.sub(r"\x1b\[[0-9;]*m", "", result.stdout)
                    self.assertEqual(
                        re.findall(r"\{([^}]*)\}", rendered), ["Example Model (high)"]
                    )
                    self.assertIn("ctx ", rendered)
                    self.assertIn("25%", rendered)
                    self.assertIn("models 12% used", rendered)
                    self.assertIn("api 34% used", rendered)


if __name__ == "__main__":
    unittest.main()
