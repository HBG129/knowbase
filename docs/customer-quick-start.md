# Customer Quick Start

This guide describes the target first-run flow for a packaged KnowBase Windows desktop app.

The customer installer is not released yet. Use this guide as the expected customer experience for release validation.

## 1. Launch KnowBase

Open KnowBase from the Windows shortcut or Start Menu entry.

The desktop app should start its local backend automatically. Customers should not need to install Python, Node.js, Rust, Git, or project source code.

## 2. Create An Account

Register an account inside the app.

The current desktop runtime stores account data locally in:

```text
%APPDATA%\KnowBase
```

This account is local to the installed app unless a future hosted account service is added.

## 3. Configure An LLM API Key

If the build does not include a system fallback key, add a personal provider key from:

```text
Sidebar -> Set API Key
```

Supported provider choices:

- Zhipu GLM
- DeepSeek
- OpenAI

Without a configured key, chat and document embedding features may show an API key required message.

## 4. Create A Knowledge Base

Create a knowledge base for one topic, project, class, or document collection.

Recommended customer pattern:

- one knowledge base per subject,
- upload related files together,
- avoid mixing unrelated private and work documents.

## 5. Upload Documents And Ask Questions

Upload supported files:

- PDF
- Word
- Markdown
- TXT
- CSV

Wait until at least one document finishes processing. Then open chat and ask a question.

Expected result:

- the app answers using retrieved document context,
- citations appear with the answer,
- the conversation is saved for later.

## If Something Fails

Check these common causes first:

- No LLM API key is configured.
- The selected provider key is invalid, expired, or out of quota.
- The machine has no internet access.
- The uploaded file is too large or unsupported.
- The document has not finished processing yet.

For local data and privacy notes, see:

```text
docs\customer-data-and-privacy.md
```

For current product limitations, see:

```text
docs\known-limitations.md
```
