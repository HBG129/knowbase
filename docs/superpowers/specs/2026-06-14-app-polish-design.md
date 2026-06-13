# KnowBase app polish design

## Goal

Make KnowBase feel like a premium desktop-style knowledge workspace while improving the first-run path: create a knowledge base, upload documents, then start a cited chat.

## Scope

- Add a developer script for one-command dev startup.
- Replace the home page marketing hero with an app dashboard.
- Add first-run guidance for empty knowledge bases.
- Show supported upload file types directly in the upload area.
- Make chat input copy react to whether the knowledge base has documents.
- Replace destructive browser confirmations in chat with in-app confirmation UI.

## Out of scope

- Tauri or Electron packaging.
- OAuth, public share links, reranker changes, or backend architecture changes.
- A new frontend UI framework.

## Design direction

Use the existing Tailwind token system and components. Shift the product toward a dark, technical workspace: precise borders, compact metadata, strong app-shell hierarchy, restrained accent color, and clear operational states. Avoid a landing-page hero and avoid decorative UI that does not help users complete the workflow.

## Verification

- `npm run build` must pass in `knowbase/frontend`.
- The app must keep existing routes and API calls intact.
- Empty states must give users one clear next action.
