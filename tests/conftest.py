"""pytest fixtures for king-core test suite."""
import shutil
from pathlib import Path
import pytest

FIXTURES_DIR = Path(__file__).parent / "fixtures"


@pytest.fixture
def king_project(tmp_path):
    """Copy a named fixture project to tmp_path and return the path.

    Usage: king_project("minimal") -> Path to isolated copy.
    """
    def _factory(project_type: str) -> Path:
        src = FIXTURES_DIR / f"{project_type}-king-project"
        if not src.exists():
            raise ValueError(f"No fixture for project type: {project_type!r}")
        dst = tmp_path / f"{project_type}-king-project"
        shutil.copytree(src, dst)
        return dst
    return _factory
