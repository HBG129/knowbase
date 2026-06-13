from app.services.chat_service import build_system_prompt


def test_system_prompt_uses_readable_chinese_instructions():
    prompt = build_system_prompt("")

    assert "你是一个知识库 AI 助手" in prompt
    assert "请用与用户相同的语言回答" in prompt
    assert "浣犳槸" not in prompt
    assert "俓n" not in prompt
    assert "鈥" not in prompt


def test_system_prompt_includes_reference_context_when_available():
    prompt = build_system_prompt("Alpha policy excerpt.")

    assert "Reference Context" in prompt
    assert "Alpha policy excerpt." in prompt
