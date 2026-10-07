import math
import re
import time
from datetime import UTC, datetime
from uuid import uuid4

import pytest
import requests

FORMATS = ("cargo", "conda", "docker", "go", "maven", "npm", "nuget", "python")
VERSIONS = ("1.16.0", "1.17.0")


def probe(session, root):
    statuses = {}
    listed = set()
    for name, method, path in (
        ("index", "GET", "/simple/six/"),
        *(
            (version, "HEAD", f"/six-{version}-py2.py3-none-any.whl")
            for version in VERSIONS
        ),
    ):
        try:
            # A fresh request_id bypasses the CDN cache, including on retries.
            response = session.request(
                method,
                root + path,
                params={"request_id": uuid4().hex},
                timeout=(10, 30),
                allow_redirects=True,
            )
        except requests.RequestException as error:
            statuses[name] = type(error).__name__
            continue
        with response:
            statuses[name] = response.status_code
            if name == "index" and response.status_code == 200:
                listed = set(
                    re.findall(
                        r"six-(\d+\.\d+\.\d+)-py2\.py3-none-any\.whl", response.text
                    )
                )
    return listed, statuses


def wait_for_visibility(session, root, *, hidden, timeout=180):
    deadline = time.monotonic() + timeout
    expected = {
        "index": 200,
        "1.16.0": 200,
        "1.17.0": 403 if hidden else 200,
    }
    while True:
        listed, statuses = probe(session, root)
        if (
            statuses == expected
            and "1.16.0" in listed
            and ("1.17.0" not in listed if hidden else "1.17.0" in listed)
        ):
            return
        if time.monotonic() >= deadline:
            pytest.fail(
                f"Cooldown did not converge (hidden={hidden}): "
                f"listed={sorted(listed)}, HTTP={statuses}; expected HTTP={expected}"
            )
        time.sleep(5)


@pytest.mark.integration
@pytest.mark.parametrize("formats", [(value,) for value in FORMATS] + [FORMATS])
def test_accepts_cooldown_formats(cooldown, formats):
    outputs = cooldown(enabled=False, within_past_days=3, supported_formats=formats)
    assert outputs["cooldown"]["read_only"], f"Cooldown not recognized for {formats}"


@pytest.mark.integration
def test_cooldown_visibility_and_downloads(cooldown):
    # six 1.17.0 was released on 2024-12-04; 1.16.0 is over three years older.
    age = math.ceil(
        (datetime.now(UTC) - datetime(2024, 12, 4, tzinfo=UTC)).total_seconds() / 86400
    )
    with requests.Session() as session:
        for phase, enabled, days, hidden in (
            ("disabled", False, age + 30, False),
            ("enabled", True, age + 30, True),
            ("shorter", True, age - 30, False),
        ):
            outputs = cooldown(enabled=enabled, within_past_days=days)
            assert outputs["cooldown"]["read_only"]
            wait_for_visibility(
                session, outputs["download_roots"][phase], hidden=hidden
            )
