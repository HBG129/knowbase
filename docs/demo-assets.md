# Demo Assets Guide

Use this guide to prepare screenshots, GIFs, and demo copy for the README, GitHub Release page, and portfolio presentation.

The goal is to show the real product workflow without exposing private documents, API keys, local databases, or customer data.

## Required Demo Flow

Capture the product in this order:

1. First launch or login screen.
2. Empty dashboard with first-run guidance.
3. Knowledge base creation.
4. Document upload with supported file types visible.
5. Processing or ready document state.
6. Chat question against the selected knowledge base.
7. AI answer with source citations.
8. Recent conversation reopen.
9. API key prompt or settings entry, with the key hidden.

## Recommended README Assets

Use these assets when the UI is stable:

```text
docs\assets\hero-dashboard.png
docs\assets\upload-flow.png
docs\assets\rag-answer-with-citations.png
docs\assets\desktop-window.png
docs\assets\first-run-flow.gif
```

Keep image width at 1400 to 1800 pixels for GitHub readability.

## Demo Data Rules

Use synthetic documents only.

Good demo document examples:

- a fake employee handbook,
- a fake product FAQ,
- a fake meeting note,
- a public-domain text excerpt,
- a generated CSV with harmless sample rows.

Do not use:

- personal resumes,
- real customer files,
- API keys,
- private school or company documents,
- screenshots that show local tokens, cookies, or database paths with private usernames.

## Screenshot Quality Checklist

Before adding images to the repository:

- Window size is consistent across screenshots.
- Browser or desktop chrome does not distract from the product.
- API keys and personal information are hidden.
- The selected knowledge base has a clear name.
- The question demonstrates a real RAG use case.
- The answer includes visible source citations.
- Light and dark theme screenshots are not mixed in the same flow unless intentionally compared.
- Images are compressed enough for GitHub but still readable.

## Suggested Demo Script

Use this script for a short portfolio or interview walkthrough:

```text
KnowBase is a desktop-first AI knowledge-base assistant.
The user creates a private knowledge base, uploads local documents, and asks questions against those documents.
The backend parses files, chunks text, runs vector retrieval, sends grounded context to the LLM, and streams a cited answer back to the desktop UI.
The packaging direction is PyInstaller for the Python backend plus Tauri for the Windows desktop shell, so the target customer does not need Python or Node.js installed.
```

## Storage

Store final demo assets under:

```text
docs\assets
```

Use lowercase file names with hyphens.

Do not commit raw recordings if they are large. Commit trimmed, compressed assets only.
