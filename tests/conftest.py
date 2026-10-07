import json
import os
import re
import shutil
import subprocess
from pathlib import Path

import pytest


@pytest.fixture(scope="module")
def cooldown(tmp_path_factory):
    for name in ("CLOUDSMITH_API_KEY", "TF_VAR_workspace"):
        if not os.environ.get(name):
            pytest.fail(f"{name} is required for integration tests")

    package = tmp_path_factory.mktemp("cooldown") / "policy"
    shutil.copytree(
        Path(__file__).resolve().parents[1] / "modules/policy",
        package,
        ignore=shutil.ignore_patterns(
            ".terraform", ".terraform.lock.hcl", "*.tfstate*", "*.tfvars*"
        ),
    )
    directory = package / "tests/e2e/cooldown"
    variables_file = directory / "test.auto.tfvars.json"
    environment = {**os.environ, "TF_IN_AUTOMATION": "1", "TF_INPUT": "0"}
    environment.pop("TF_LOG", None)
    environment.pop("TF_LOG_PATH", None)

    def run(*arguments):
        result = subprocess.run(
            ["terraform", *arguments, "-no-color"],
            cwd=directory,
            env=environment,
            capture_output=True,
            text=True,
            check=False,
        )
        if result.returncode:
            diagnostics = re.sub(
                r"https://dl\.cloudsmith\.io/\S+",
                "<redacted download URL>",
                result.stdout + result.stderr,
            ).replace(os.environ["CLOUDSMITH_API_KEY"], "<redacted API key>")
            pytest.fail(f"terraform {arguments[0]} failed:\n{diagnostics}")
        return result.stdout

    def apply(*, enabled, within_past_days, supported_formats=("python",)):
        variables_file.write_text(
            json.dumps(
                {
                    "enabled": enabled,
                    "within_past_days": within_past_days,
                    "supported_formats": list(supported_formats),
                }
            )
        )
        run("apply", "-auto-approve", "-input=false")
        return {
            key: output["value"]
            for key, output in json.loads(run("output", "-json")).items()
        }

    run("init", "-input=false")
    try:
        yield apply
    finally:
        if variables_file.exists():
            run("destroy", "-auto-approve", "-input=false")
