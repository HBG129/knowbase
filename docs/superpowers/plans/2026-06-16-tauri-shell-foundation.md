# Tauri Shell Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add the first Tauri desktop shell foundation for KnowBase so the project can move toward a customer-installable Windows app.

**Architecture:** Keep the existing Next.js frontend and FastAPI backend. Add Tauri as a desktop shell under the frontend project, then connect it to the already verified backend executable in a later packaging task.

**Tech Stack:** Tauri 2, Rust, Cargo, Next.js, Windows WebView2, PyInstaller backend executable.

---

### Task 1: Toolchain Setup

**Files:**
- Create local tool directories under `D:\Codex_AI_Workspace\.tools`

- [ ] **Step 1: Install Rust to D drive**

Set `RUSTUP_HOME=D:\Codex_AI_Workspace\.tools\rustup` and `CARGO_HOME=D:\Codex_AI_Workspace\.tools\cargo`, then install the stable Rust toolchain.

- [ ] **Step 2: Verify Rust**

Run:

```powershell
D:\Codex_AI_Workspace\.tools\cargo\bin\rustc.exe --version
D:\Codex_AI_Workspace\.tools\cargo\bin\cargo.exe --version
```

Expected: both commands print versions.

- [ ] **Step 3: Check Windows native build tools**

Check for MSVC `cl.exe` and Visual Studio Build Tools. If missing, stop and document the exact requirement instead of guessing around it.

### Task 2: Tauri Project Skeleton

**Files:**
- Modify: `frontend/package.json`
- Create: `frontend/src-tauri/Cargo.toml`
- Create: `frontend/src-tauri/src/main.rs`
- Create: `frontend/src-tauri/tauri.conf.json`
- Modify: `.gitignore`
- Modify: `README.md`

- [ ] **Step 1: Add Tauri dev dependency and scripts**

Add `@tauri-apps/cli` and scripts for `tauri:dev` and `tauri:build`.

- [ ] **Step 2: Add minimal Rust shell**

Create a minimal Tauri app named `KnowBase` that opens the frontend URL in development.

- [ ] **Step 3: Ignore Rust build output**

Ignore `frontend/src-tauri/target/`.

### Task 3: Verification

**Files:**
- Verify only unless a command exposes a directly related issue.

- [ ] **Step 1: Verify frontend build**

Run `npm run build` in `frontend`.

- [ ] **Step 2: Verify Rust metadata if toolchain is complete**

Run `cargo metadata` in `frontend/src-tauri`.

- [ ] **Step 3: Record limitations**

If MSVC Build Tools are missing, document that Tauri compilation requires Microsoft C++ Build Tools and pause before installing system-level dependencies.

Result on this machine: Rust 1.96.0 and Cargo 1.96.0 are installed under `D:\Codex_AI_Workspace\.tools`. `cargo metadata` passes. `cargo check` is blocked because `link.exe` is missing. The Visual Studio Build Tools bootstrapper failed with certificate/network errors while downloading `vs_installer.opc`.

### Task 4: Commit and Push

**Files:**
- Commit all source and documentation changes.

- [ ] **Step 1: Inspect git diff**

Confirm only Tauri setup files, docs, and ignore rules changed.

- [ ] **Step 2: Commit**

Commit with:

```bash
git commit -m "build: add tauri shell foundation"
```

- [ ] **Step 3: Push**

Push to `origin/main`.
