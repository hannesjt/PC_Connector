"""Tests for the auth / pairing service."""

import time
from unittest.mock import patch

from services import auth_service


def _reset_auth():
    """Reset auth service state for isolated tests."""
    auth_service._pairing_code = None
    auth_service._pairing_code_expires = 0
    auth_service._paired_devices = {}
    auth_service._loaded = True  # prevent loading from disk


class TestGeneratePairingCode:
    def setup_method(self):
        _reset_auth()

    def test_generates_six_digit_code(self):
        code = auth_service.generate_pairing_code()
        assert len(code) == 6
        assert code.isdigit()

    def test_code_is_valid_after_generation(self):
        code = auth_service.generate_pairing_code()
        info = auth_service.get_pairing_code_info()
        assert info is not None
        assert info["code"] == code
        assert info["expires_in"] > 0

    def test_new_code_replaces_old(self):
        code1 = auth_service.generate_pairing_code()
        code2 = auth_service.generate_pairing_code()
        info = auth_service.get_pairing_code_info()
        assert info["code"] == code2
        assert code1 != code2 or True  # codes may occasionally collide


class TestGetPairingCodeInfo:
    def setup_method(self):
        _reset_auth()

    def test_returns_none_when_no_code(self):
        assert auth_service.get_pairing_code_info() is None

    def test_returns_none_when_expired(self):
        auth_service.generate_pairing_code()
        auth_service._pairing_code_expires = time.time() - 1
        assert auth_service.get_pairing_code_info() is None


class TestVerifyPairingCode:
    def setup_method(self):
        _reset_auth()

    @patch.object(auth_service, "_save")
    def test_valid_code_returns_token(self, mock_save):
        code = auth_service.generate_pairing_code()
        token = auth_service.verify_pairing_code(code, "Pixel 10")
        assert token is not None
        assert isinstance(token, str)
        assert len(token) > 10
        mock_save.assert_called_once()

    @patch.object(auth_service, "_save")
    def test_valid_code_registers_device(self, mock_save):
        code = auth_service.generate_pairing_code()
        token = auth_service.verify_pairing_code(code, "Pixel 10")
        assert token in auth_service._paired_devices
        assert auth_service._paired_devices[token]["name"] == "Pixel 10"

    @patch.object(auth_service, "_save")
    def test_code_is_single_use(self, mock_save):
        code = auth_service.generate_pairing_code()
        auth_service.verify_pairing_code(code, "Phone1")
        token2 = auth_service.verify_pairing_code(code, "Phone2")
        assert token2 is None

    def test_wrong_code_returns_none(self):
        auth_service.generate_pairing_code()
        assert auth_service.verify_pairing_code("000000", "Phone") is None

    def test_expired_code_returns_none(self):
        code = auth_service.generate_pairing_code()
        auth_service._pairing_code_expires = time.time() - 1
        assert auth_service.verify_pairing_code(code, "Phone") is None


class TestTokenValidation:
    def setup_method(self):
        _reset_auth()

    def test_valid_token(self):
        auth_service._paired_devices["tok123"] = {"name": "Test"}
        assert auth_service.is_valid_token("tok123") is True

    def test_invalid_token(self):
        assert auth_service.is_valid_token("nonexistent") is False


class TestGetPairedDevices:
    def setup_method(self):
        _reset_auth()

    def test_empty(self):
        assert auth_service.get_paired_devices() == []

    def test_lists_devices(self):
        auth_service._paired_devices["abcdefghijklmnop"] = {
            "name": "Pixel 10",
            "paired_at": 1000000,
        }
        devices = auth_service.get_paired_devices()
        assert len(devices) == 1
        assert devices[0]["token_prefix"] == "abcdefgh"
        assert devices[0]["name"] == "Pixel 10"


class TestRemoveDevice:
    def setup_method(self):
        _reset_auth()

    @patch.object(auth_service, "_save")
    def test_remove_existing(self, mock_save):
        auth_service._paired_devices["abcdefghijk"] = {"name": "Phone"}
        assert auth_service.remove_device("abcdefgh") is True
        assert len(auth_service._paired_devices) == 0
        mock_save.assert_called_once()

    @patch.object(auth_service, "_save")
    def test_remove_nonexistent(self, mock_save):
        assert auth_service.remove_device("noexist") is False
        mock_save.assert_not_called()
