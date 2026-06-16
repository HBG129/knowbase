@echo off
set "RUSTUP_HOME=D:\Codex_AI_Workspace\.tools\rustup"
set "CARGO_HOME=D:\Codex_AI_Workspace\.tools\cargo"
set "PATH=D:\Codex_AI_Workspace\.tools\cargo\bin;%PATH%"

echo Rust environment configured for this terminal.
rustc --version
cargo --version
