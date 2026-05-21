"""Integration tests for the /api/input endpoints (mouse & keyboard).

pyautogui is mocked so these tests run in headless CI environments.
"""

import sys
from pathlib import Path
from unittest.mock import MagicMock, patch

import pytest
from fastapi.testclient import TestClient

# Ensure pc_agent root is on the path
sys.path.insert(0, str(Path(__file__).parent.parent))


@pytest.fixture(autouse=True)
def _mock_pyautogui():
    """Replace pyautogui with a MagicMock before any import of the input router."""
    mock = MagicMock()
    # Patch inside the router module so _pag() returns the mock
    import routers.input as input_router  # noqa: PLC0415
    input_router._pyautogui = mock
    yield mock
    # Reset so other test modules are unaffected
    input_router._pyautogui = None


@pytest.fixture()
def client(_mock_pyautogui):
    from services import auth_service  # noqa: PLC0415
    auth_service._paired_devices = {"tok": {"name": "T", "paired_at": 0}}
    auth_service._loaded = True
    from main import app  # noqa: PLC0415
    return TestClient(app)


AUTH = {"Authorization": "Bearer tok"}


# ---------------------------------------------------------------------------
# Mouse – move
# ---------------------------------------------------------------------------

class TestMouseMove:
    def test_move_authorized(self, client, _mock_pyautogui):
        resp = client.post("/api/input/mouse/move", json={"dx": 10, "dy": -5}, headers=AUTH)
        assert resp.status_code == 200
        assert resp.json() == {"success": True}
        _mock_pyautogui.moveRel.assert_called_once_with(10, -5, duration=0)

    def test_move_unauthorized(self, client):
        resp = client.post("/api/input/mouse/move", json={"dx": 1, "dy": 1})
        assert resp.status_code == 401

    def test_move_zero(self, client, _mock_pyautogui):
        resp = client.post("/api/input/mouse/move", json={"dx": 0, "dy": 0}, headers=AUTH)
        assert resp.status_code == 200
        _mock_pyautogui.moveRel.assert_called_once_with(0, 0, duration=0)


# ---------------------------------------------------------------------------
# Mouse – click
# ---------------------------------------------------------------------------

class TestMouseClick:
    def test_left_click(self, client, _mock_pyautogui):
        resp = client.post("/api/input/mouse/click", json={"button": "left"}, headers=AUTH)
        assert resp.status_code == 200
        _mock_pyautogui.click.assert_called_once_with(button="left")
        _mock_pyautogui.doubleClick.assert_not_called()

    def test_right_click(self, client, _mock_pyautogui):
        resp = client.post("/api/input/mouse/click", json={"button": "right"}, headers=AUTH)
        assert resp.status_code == 200
        _mock_pyautogui.click.assert_called_once_with(button="right")

    def test_double_click(self, client, _mock_pyautogui):
        resp = client.post("/api/input/mouse/click", json={"button": "left", "double": True}, headers=AUTH)
        assert resp.status_code == 200
        _mock_pyautogui.doubleClick.assert_called_once_with(button="left")
        _mock_pyautogui.click.assert_not_called()

    def test_invalid_button_falls_back_to_left(self, client, _mock_pyautogui):
        resp = client.post("/api/input/mouse/click", json={"button": "unknown"}, headers=AUTH)
        assert resp.status_code == 200
        _mock_pyautogui.click.assert_called_once_with(button="left")

    def test_click_unauthorized(self, client):
        resp = client.post("/api/input/mouse/click", json={"button": "left"})
        assert resp.status_code == 401


# ---------------------------------------------------------------------------
# Mouse – scroll
# ---------------------------------------------------------------------------

class TestMouseScroll:
    def test_scroll_vertical(self, client, _mock_pyautogui):
        resp = client.post("/api/input/mouse/scroll", json={"dy": 3}, headers=AUTH)
        assert resp.status_code == 200
        _mock_pyautogui.scroll.assert_called_once_with(3)
        _mock_pyautogui.hscroll.assert_not_called()

    def test_scroll_horizontal(self, client, _mock_pyautogui):
        resp = client.post("/api/input/mouse/scroll", json={"dx": -2}, headers=AUTH)
        assert resp.status_code == 200
        _mock_pyautogui.hscroll.assert_called_once_with(-2)
        _mock_pyautogui.scroll.assert_not_called()

    def test_scroll_both_axes(self, client, _mock_pyautogui):
        resp = client.post("/api/input/mouse/scroll", json={"dx": 1, "dy": 2}, headers=AUTH)
        assert resp.status_code == 200
        _mock_pyautogui.scroll.assert_called_once_with(2)
        _mock_pyautogui.hscroll.assert_called_once_with(1)

    def test_scroll_zero_no_calls(self, client, _mock_pyautogui):
        resp = client.post("/api/input/mouse/scroll", json={"dx": 0, "dy": 0}, headers=AUTH)
        assert resp.status_code == 200
        _mock_pyautogui.scroll.assert_not_called()
        _mock_pyautogui.hscroll.assert_not_called()

    def test_scroll_unauthorized(self, client):
        resp = client.post("/api/input/mouse/scroll", json={"dy": 1})
        assert resp.status_code == 401


# ---------------------------------------------------------------------------
# Keyboard – type
# ---------------------------------------------------------------------------

class TestKeyboardType:
    def test_type_text(self, client, _mock_pyautogui):
        resp = client.post("/api/input/keyboard/type", json={"text": "hello"}, headers=AUTH)
        assert resp.status_code == 200
        _mock_pyautogui.typewrite.assert_called_once_with("hello", interval=0.02)

    def test_type_empty_string_no_call(self, client, _mock_pyautogui):
        resp = client.post("/api/input/keyboard/type", json={"text": ""}, headers=AUTH)
        assert resp.status_code == 200
        _mock_pyautogui.typewrite.assert_not_called()

    def test_type_unauthorized(self, client):
        resp = client.post("/api/input/keyboard/type", json={"text": "x"})
        assert resp.status_code == 401


# ---------------------------------------------------------------------------
# Keyboard – key
# ---------------------------------------------------------------------------

class TestKeyboardKey:
    def test_press_enter(self, client, _mock_pyautogui):
        resp = client.post("/api/input/keyboard/key", json={"key": "enter"}, headers=AUTH)
        assert resp.status_code == 200
        _mock_pyautogui.press.assert_called_once_with("enter")

    def test_press_backspace(self, client, _mock_pyautogui):
        resp = client.post("/api/input/keyboard/key", json={"key": "backspace"}, headers=AUTH)
        assert resp.status_code == 200
        _mock_pyautogui.press.assert_called_once_with("backspace")

    def test_alias_esc(self, client, _mock_pyautogui):
        resp = client.post("/api/input/keyboard/key", json={"key": "esc"}, headers=AUTH)
        assert resp.status_code == 200
        _mock_pyautogui.press.assert_called_once_with("escape")

    def test_alias_win(self, client, _mock_pyautogui):
        resp = client.post("/api/input/keyboard/key", json={"key": "win"}, headers=AUTH)
        assert resp.status_code == 200
        _mock_pyautogui.press.assert_called_once_with("winleft")

    def test_alias_del(self, client, _mock_pyautogui):
        resp = client.post("/api/input/keyboard/key", json={"key": "del"}, headers=AUTH)
        assert resp.status_code == 200
        _mock_pyautogui.press.assert_called_once_with("delete")

    def test_case_insensitive(self, client, _mock_pyautogui):
        resp = client.post("/api/input/keyboard/key", json={"key": "ESC"}, headers=AUTH)
        assert resp.status_code == 200
        _mock_pyautogui.press.assert_called_once_with("escape")

    def test_key_unauthorized(self, client):
        resp = client.post("/api/input/keyboard/key", json={"key": "enter"})
        assert resp.status_code == 401
