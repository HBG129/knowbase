# KnowBase App Polish Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Polish KnowBase into a premium app-like knowledge workspace and improve the first-run flow.

**Architecture:** Keep the existing Next.js, Tailwind, Zustand, and FastAPI contracts. Make focused frontend changes in page/components that already own the relevant UI.

**Tech Stack:** Next.js 14, React 18, Tailwind CSS, lucide-react, Zustand.

---

### Task 1: Dev startup script

**Files:**
- Create: `knowbase/start-dev.bat`

- [ ] Add a Windows script that starts backend and frontend dev processes from the project root.
- [ ] Verify the script references existing `backend` and `frontend` folders.

### Task 2: App dashboard home

**Files:**
- Modify: `knowbase/frontend/src/app/page.tsx`

- [ ] Replace the landing-style hero with an app dashboard.
- [ ] Keep `KBCreateDialog` as the primary creation path.
- [ ] Add clear empty state guidance when there are no knowledge bases.
- [ ] Add recent conversation shortcuts by fetching conversations for the current knowledge bases.

### Task 3: Upload and document readiness

**Files:**
- Modify: `knowbase/frontend/src/components/kb/document-upload.tsx`
- Modify: `knowbase/frontend/src/app/kb/[id]/chat/page.tsx`

- [ ] Show supported file type chips in the upload drop zone.
- [ ] Fetch knowledge base documents on the chat page.
- [ ] Disable or reword the chat input when no document is ready.

### Task 4: In-app destructive confirmation

**Files:**
- Modify: `knowbase/frontend/src/app/kb/[id]/chat/page.tsx`

- [ ] Replace `confirm()` for conversation deletion and clearing messages with an in-app confirmation bar.
- [ ] Keep deletion behavior unchanged after confirmation.

### Task 5: Verification

**Files:**
- Verify only.

- [ ] Run `npm run build` in `knowbase/frontend`.
- [ ] Fix compile errors if any.
