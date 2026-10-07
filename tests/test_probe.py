from unittest.mock import MagicMock

import pytest
import requests
from test_cooldown import probe, wait_for_visibility


def response(status=200, body=""):
    result = MagicMock(status_code=status, text=body)
    result.__enter__.return_value = result
    return result


def test_probe_parses_wheels_and_busts_every_request():
    session = MagicMock()
    session.request.side_effect = [
        response(body="six-1.16.0-py2.py3-none-any.whl six-1.17.0.tar.gz"),
        response(),
        response(403),
    ]

    listed, statuses = probe(session, "https://example.invalid")

    assert listed == {"1.16.0"}
    assert statuses == {"index": 200, "1.16.0": 200, "1.17.0": 403}
    calls = session.request.call_args_list
    assert [call.args[0] for call in calls] == ["GET", "HEAD", "HEAD"]
    assert len({call.kwargs["params"]["request_id"] for call in calls}) == 3


def test_probe_does_not_expose_entitlement_on_network_errors():
    session = MagicMock()
    session.request.side_effect = requests.Timeout("secret-entitlement-url")
    listed, statuses = probe(session, "https://example.invalid")
    assert listed == set()
    assert set(statuses.values()) == {"Timeout"}


def test_visibility_retries_replication_lag(monkeypatch):
    monkeypatch.setattr("test_cooldown.time.sleep", lambda _: None)
    session = MagicMock()
    session.request.side_effect = [
        response(503),
        response(503),
        response(503),
        response(body="six-1.16.0-py2.py3-none-any.whl"),
        response(),
        response(403),
    ]
    wait_for_visibility(session, "https://example.invalid", hidden=True)
    assert session.request.call_count == 6


@pytest.mark.parametrize("status", [200, 403])
def test_visibility_requires_index_and_download_to_agree(status):
    session = MagicMock()
    session.request.side_effect = [
        response(body="six-1.17.0-py2.py3-none-any.whl"),
        response(),
        response(status),
    ]
    with pytest.raises(pytest.fail.Exception, match="Cooldown did not converge"):
        wait_for_visibility(session, "https://example.invalid", hidden=True, timeout=0)
