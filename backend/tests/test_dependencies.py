from pathlib import Path
import tomllib


def test_runtime_dependencies_include_lxml_for_docx_parser():
    pyproject = Path(__file__).resolve().parents[1] / "pyproject.toml"
    data = tomllib.loads(pyproject.read_text(encoding="utf-8"))
    dependencies = data["project"]["dependencies"]

    assert any(dep.lower().startswith("lxml") for dep in dependencies)
