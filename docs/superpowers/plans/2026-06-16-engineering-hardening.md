# KnowBase Engineering Hardening Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add CI, repository hygiene, and reliable Windows startup documentation for KnowBase.

**Architecture:** Keep changes limited to repository infrastructure and documentation. Use GitHub Actions for automated verification, `.gitattributes` for line-ending policy, and ASCII-only Windows batch output for reliability.

**Tech Stack:** GitHub Actions, Node 20, Python 3.12, Next.js, FastAPI, pytest.

---

### Task 1: GitHub Actions CI

**Files:**
- Create: `.github/workflows/ci.yml`

- [ ] Add a frontend job that runs `npm ci` and `npm run build` in `frontend`.
- [ ] Add a backend job that installs `backend[dev]` and runs pytest with a workspace-local temp directory.

### Task 2: Repository line endings

**Files:**
- Create: `.gitattributes`

- [ ] Set text normalization for source files.
- [ ] Force `.bat` files to CRLF.
- [ ] Force shell scripts and YAML/Markdown/source files to LF.

### Task 3: Startup script cleanup

**Files:**
- Modify: `start-utf8.bat`

- [ ] Replace mojibake output with ASCII text.
- [ ] Keep backend/frontend startup behavior unchanged.
- [ ] Keep browser opening behavior unchanged.

### Task 4: README update

**Files:**
- Modify: `README.md`

- [ ] Mention GitHub Actions CI.
- [ ] Document the stable backend pytest command for Windows.
- [ ] Mention `.gitattributes` and batch script encoding policy.

### Task 5: Verification and publish

**Files:**
- Verify only.

- [ ] Run `npm run build` in `frontend`.
- [ ] Run backend pytest with workspace-local temp directory.
- [ ] Commit and push to `HBG129/knowbase`.
