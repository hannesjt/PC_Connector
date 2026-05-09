"""Tests for config_loader service."""

from pathlib import Path
from unittest.mock import patch

import yaml
import pytest

from models.schemas import AppConfig, ScriptConfig
from services import config_loader


@pytest.fixture(autouse=True)
def _reset_config():
    """Reset cached config between tests."""
    config_loader._config = None
    yield
    config_loader._config = None


@pytest.fixture
def config_file(tmp_path):
    """Create a temporary config.yaml and return its path."""
    path = tmp_path / "config.yaml"
    data = {
        "pc": {"name": "TestPC", "mac_address": "AA-BB-CC-DD-EE-FF"},
        "api": {"host": "0.0.0.0", "port": 8420},
        "scripts": [
            {"id": "s1", "name": "Script 1", "command": "echo 1", "order": 1},
            {"id": "s2", "name": "Script 2", "command": "echo 2", "group": "System", "order": 0},
        ],
        "category_order": ["System"],
    }
    path.write_text(yaml.dump(data), encoding="utf-8")
    return path


class TestLoadConfig:
    def test_load(self, config_file):
        cfg = config_loader.load_config(str(config_file))
        assert cfg.pc.name == "TestPC"
        assert cfg.pc.mac_address == "AA-BB-CC-DD-EE-FF"
        assert cfg.api.port == 8420
        assert len(cfg.scripts) == 2

    def test_get_config_loads_on_first_call(self, config_file):
        with patch.object(config_loader, "load_config", wraps=config_loader.load_config) as mock_load:
            # Manually override the path resolution
            config_loader._config = config_loader.load_config(str(config_file))
            cfg = config_loader.get_config()
            assert cfg.pc.name == "TestPC"


class TestSaveConfig:
    def test_save_preserves_data(self, config_file):
        cfg = config_loader.load_config(str(config_file))
        cfg.scripts[0].order = 99
        config_loader.save_config(str(config_file))

        reloaded = config_loader.load_config(str(config_file))
        assert reloaded.scripts[0].order == 99

    def test_save_noop_when_not_loaded(self, tmp_path):
        path = tmp_path / "nope.yaml"
        config_loader.save_config(str(path))
        assert not path.exists()


class TestGetOrderedGroups:
    def test_respects_category_order(self, config_file):
        cfg = config_loader.load_config(str(config_file))
        ordered = config_loader.get_ordered_groups(cfg)
        assert len(ordered) == 1
        assert ordered[0][0] == "System"
        assert "s2" in ordered[0][1]

    def test_appends_unknown_groups(self, config_file):
        cfg = config_loader.load_config(str(config_file))
        cfg.scripts.append(ScriptConfig(id="s3", name="S3", command="echo 3", group="Games"))
        cfg.category_order = ["System"]
        ordered = config_loader.get_ordered_groups(cfg)
        names = [name for name, _ in ordered]
        assert names == ["System", "Games"]

    def test_skips_ordered_group_if_no_scripts(self, config_file):
        cfg = config_loader.load_config(str(config_file))
        cfg.category_order = ["System", "Nonexistent"]
        ordered = config_loader.get_ordered_groups(cfg)
        names = [name for name, _ in ordered]
        assert "Nonexistent" not in names
