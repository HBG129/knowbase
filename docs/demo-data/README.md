# Demo Data

This directory contains synthetic documents for KnowBase screenshots, release validation, and interview demos.

Use these files when you need safe sample content that does not expose personal, customer, school, or company data.

## Files

- `sample-handbook.md` - fake workplace handbook for policy-style questions.
- `sample-meeting-notes.txt` - fake product meeting notes for timeline and decision questions.
- `sample-metrics.csv` - fake product metrics for CSV upload and tabular retrieval checks.

## Suggested Knowledge Base

Create a knowledge base named:

```text
KnowBase Demo Workspace
```

Upload all three files, wait for processing, then ask:

```text
What are the onboarding steps, release goals, and support response targets?
```

Expected answer should mention:

- onboarding steps from the handbook,
- release goals from the meeting notes,
- support or uptime targets from the metrics CSV.

## Safety Rules

- Do not replace these files with real customer data.
- Do not add API keys, tokens, personal resumes, private contracts, or internal company documents.
- Keep demo data small enough for fast upload and repeatable screenshots.
