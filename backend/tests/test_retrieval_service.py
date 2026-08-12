from app.services.retrieval_service import _bm25_score, _tokenize


def test_tokenize_keeps_words_numbers_and_cjk_characters():
    tokens = _tokenize("KnowBase RAG 2026 知识库")

    assert "knowbase" in tokens
    assert "rag" in tokens
    assert "2026" in tokens
    assert "知" in tokens
    assert "识" in tokens
    assert "库" in tokens


def test_bm25_score_increases_for_matching_terms():
    score = _bm25_score(
        query_tokens=["rag"],
        doc_tokens=["enterprise", "rag", "platform"],
        doc_freqs={"rag": 1},
        total_docs=3,
    )

    assert score > 0


def test_bm25_length_normalization_rewards_focused_chunks():
    shared = {
        "query_tokens": ["rag"],
        "doc_freqs": {"rag": 2},
        "total_docs": 2,
        "avg_doc_length": 51.0,
    }

    focused = _bm25_score(doc_tokens=["rag", "answer"], **shared)
    verbose = _bm25_score(doc_tokens=["rag", *(["noise"] * 99)], **shared)

    assert focused > verbose
