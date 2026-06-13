from app.services.ingestion_service import parse_document


def test_parse_document_reads_plain_text(tmp_path):
    path = tmp_path / "note.txt"
    path.write_text("KnowBase supports plain text.", encoding="utf-8")

    assert parse_document(str(path), "txt") == "KnowBase supports plain text."


def test_parse_document_reads_markdown(tmp_path):
    path = tmp_path / "note.md"
    path.write_text("# Title\n\nMarkdown body.", encoding="utf-8")

    assert parse_document(str(path), "md") == "# Title\n\nMarkdown body."
