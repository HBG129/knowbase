# KnowBase Complete Bilingual Localization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans or superpowers:subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make every customer-facing KnowBase workflow complete in Chinese and English and prevent future partial translations.

**Architecture:** Retain the local Zustand language store and TypeScript dictionary. Derive a strict `TranslationKey` type from the canonical dictionary, add named interpolation, move all user-visible component copy behind `t()`, and enforce coverage through a PowerShell repository check used by CI and release preflight.

**Tech Stack:** Next.js, React, TypeScript, Zustand, PowerShell, GitHub Actions.

---

### Task 1: Add a failing localization contract

**Files:**
- Create: `scripts/check-i18n-coverage.ps1`
- Modify: `backend/tests/test_desktop_runtime.py`
- Modify: `.github/workflows/ci.yml`
- Modify: `scripts/check-release-preflight.ps1`

- [ ] Add a test that requires the localization checker and release-preflight integration.
- [ ] Add dictionary key parity, duplicate-key, translation-usage, and hardcoded-copy checks.
- [ ] Run the new check against the current frontend and record the expected failure.
- [ ] Keep technical terms and non-visible implementation strings in an explicit narrow allowlist.

### Task 2: Make the dictionary type-safe

**Files:**
- Modify: `frontend/src/lib/i18n.ts`
- Modify: `frontend/src/stores/i18n-store.ts`

- [ ] Define complete Chinese and English dictionaries with exact key parity.
- [ ] Export a `TranslationKey` type and type `t()` calls.
- [ ] Add named interpolation for dynamic interface text.
- [ ] Remove normal English fallback behavior from Chinese mode.
- [ ] Preserve the saved `knowbase-lang` preference and validate its value.

### Task 3: Localize shared layout and authentication

**Files:**
- Modify: `frontend/src/app/layout.tsx`
- Modify: `frontend/src/app/error.tsx`
- Modify: `frontend/src/app/global-error.tsx`
- Modify: `frontend/src/app/login/page.tsx`
- Modify: `frontend/src/app/register/page.tsx`
- Modify: `frontend/src/components/layout/sidebar.tsx`
- Modify: `frontend/src/components/layout/top-nav.tsx`
- Modify: `frontend/src/components/layout/language-switcher.tsx`
- Modify: `frontend/src/components/auth/login-form.tsx`
- Modify: `frontend/src/components/auth/register-form.tsx`
- Modify: `frontend/src/components/auth/api-key-dialog.tsx`

- [ ] Localize navigation, theme, sign-out, API Key, authentication, and global error copy.
- [ ] Localize titles, descriptions, placeholders, validation, button states, tooltips, and ARIA labels.
- [ ] Keep KnowBase and API Key as product/technical terms.

### Task 4: Localize dashboard and knowledge-base management

**Files:**
- Modify: `frontend/src/app/page.tsx`
- Modify: `frontend/src/app/kb/page.tsx`
- Modify: `frontend/src/components/kb/kb-card.tsx`
- Modify: `frontend/src/components/kb/kb-create-dialog.tsx`
- Modify: `frontend/src/components/kb/document-upload.tsx`
- Modify: `frontend/src/components/kb/document-list.tsx`

- [ ] Localize the dashboard hero, metrics, activation path, empty states, recent conversations, and all actions.
- [ ] Localize knowledge-base tabs, settings, document upload, processing states, delete flows, and file metadata.
- [ ] Route dates, relative times, counts, and document statuses through localized formatters.

### Task 5: Localize chat and citations

**Files:**
- Modify: `frontend/src/app/chat/page.tsx`
- Modify: `frontend/src/components/chat/chat-input.tsx`
- Modify: `frontend/src/components/chat/chat-message.tsx`
- Modify: `frontend/src/components/chat/citation-panel.tsx`

- [ ] Localize conversation navigation, empty states, input states, citations, copy actions, and errors.
- [ ] Localize API Key requirements without hiding provider diagnostics.
- [ ] Localize accessibility names for icon-only actions.

### Task 6: Localize the Analysis workbench

**Files:**
- Modify: `frontend/src/components/kb/analysis-panel.tsx`

- [ ] Localize dataset selection, profile, preview, quality metrics, recommended questions, query execution, SQL, charts, table results, insights, history, and empty/error states.
- [ ] Preserve CSV, SQL, DuckDB, field names, data values, and generated SQL unchanged.
- [ ] Localize result counts and dynamic summary framing.

### Task 7: Localize formatting helpers

**Files:**
- Modify: `frontend/src/lib/utils.ts`
- Modify callers found by repository search.

- [ ] Make date, relative-time, and number formatting language-aware.
- [ ] Verify all callers provide the active language.
- [ ] Keep stored values and API contracts unchanged.

### Task 8: Automated and visual verification

**Files:**
- Modify only when a verification failure identifies a scoped defect.

- [ ] Run `scripts/check-i18n-coverage.ps1`.
- [ ] Run `scripts/check-frontend-text.ps1`.
- [ ] Run `npm run build` in `frontend`.
- [ ] Run focused backend tests for release-script integration.
- [ ] Run release preflight.
- [ ] Capture Chinese and English desktop screenshots.
- [ ] Capture at least one mobile-width screenshot and verify no overflow or overlap.

### Task 9: Publish and verify GitHub automation

**Files:**
- Update release evidence documentation if verification results change.

- [ ] Review the final diff for unrelated edits and exposed secrets.
- [ ] Commit all scoped changes to `agent/analysis-workbench`.
- [ ] Push to `origin` and update PR #16.
- [ ] Wait for repository checks and frontend build to pass.
- [ ] Record any remaining external release blockers separately from localization completion.
