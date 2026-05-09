"""Tests for the chains service."""

import json
from pathlib import Path
from unittest.mock import patch

import pytest

from models.schemas import ChainStep, ScriptChain
from services import chains_service


@pytest.fixture(autouse=True)
def _use_tmp_chains(tmp_path):
    """Redirect chains service to a temp file for each test."""
    chains_file = tmp_path / "chains.json"
    chains_file.write_text("[]", encoding="utf-8")
    with patch.object(chains_service, "_CHAINS_PATH", chains_file):
        yield chains_file


def _make_chain(id: str, name: str, order: int = 0, steps=None) -> ScriptChain:
    return ScriptChain(id=id, name=name, order=order, steps=steps or [])


class TestSaveAndGetChains:
    def test_empty(self):
        assert chains_service.get_chains() == []

    def test_save_and_retrieve(self):
        chain = _make_chain("c1", "Chain 1")
        chains_service.save_chain(chain)
        result = chains_service.get_chains()
        assert len(result) == 1
        assert result[0].id == "c1"
        assert result[0].name == "Chain 1"

    def test_update_existing(self):
        chains_service.save_chain(_make_chain("c1", "Original"))
        chains_service.save_chain(_make_chain("c1", "Updated"))
        result = chains_service.get_chains()
        assert len(result) == 1
        assert result[0].name == "Updated"

    def test_save_with_steps(self):
        chain = ScriptChain(
            id="c1", name="C1",
            steps=[ChainStep(script_id="s1", delay_seconds=5)],
        )
        chains_service.save_chain(chain)
        result = chains_service.get_chains()
        assert len(result[0].steps) == 1
        assert result[0].steps[0].script_id == "s1"
        assert result[0].steps[0].delay_seconds == 5


class TestDeleteChain:
    def test_delete_existing(self):
        chains_service.save_chain(_make_chain("c1", "C1"))
        assert chains_service.delete_chain("c1") is True
        assert chains_service.get_chains() == []

    def test_delete_nonexistent(self):
        assert chains_service.delete_chain("nope") is False


class TestGetChain:
    def test_existing(self):
        chains_service.save_chain(_make_chain("c1", "C1"))
        c = chains_service.get_chain("c1")
        assert c is not None
        assert c.name == "C1"

    def test_nonexistent(self):
        assert chains_service.get_chain("nope") is None


class TestReorderChains:
    def test_reorder(self):
        chains_service.save_chain(_make_chain("a", "A", order=0))
        chains_service.save_chain(_make_chain("b", "B", order=1))
        chains_service.save_chain(_make_chain("c", "C", order=2))
        chains_service.reorder_chains(["c", "a", "b"])
        result = chains_service.get_chains()
        ids = [c.id for c in result]
        assert ids == ["c", "a", "b"]


class TestGetChainsSorting:
    def test_returns_sorted_by_order(self):
        chains_service.save_chain(_make_chain("b", "B", order=2))
        chains_service.save_chain(_make_chain("a", "A", order=0))
        chains_service.save_chain(_make_chain("c", "C", order=1))
        result = chains_service.get_chains()
        ids = [c.id for c in result]
        assert ids == ["a", "c", "b"]
