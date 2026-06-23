use std::{
    env,
    path::{Path, PathBuf},
    process::{Child, Command, Stdio},
    sync::Mutex,
};

const BACKEND_EXE_NAME: &str = "KnowBaseBackend.exe";
const BACKEND_HOST: &str = "127.0.0.1";
const BACKEND_PORT: &str = "8000";
const DESKTOP_CORS_ORIGINS: &str =
    r#"["http://localhost:3000","tauri://localhost","http://tauri.localhost","https://tauri.localhost"]"#;

pub struct BackendProcess {
    child: Mutex<Option<Child>>,
}

impl BackendProcess {
    pub fn start(resource_dir: Option<PathBuf>) -> Self {
        let manifest_dir = manifest_dir();
        let current_exe = env::current_exe().ok();
        let override_path = env::var_os("KNOWBASE_BACKEND_EXE").map(PathBuf::from);

        for candidate in backend_exe_candidates(
            &manifest_dir,
            resource_dir.as_deref(),
            current_exe.as_deref(),
            override_path.as_deref(),
        ) {
            if !candidate.exists() {
                continue;
            }

            match Command::new(&candidate)
                .env("KNOWBASE_BACKEND_HOST", BACKEND_HOST)
                .env("KNOWBASE_BACKEND_PORT", BACKEND_PORT)
                .env("CORS_ORIGINS", DESKTOP_CORS_ORIGINS)
                .stdin(Stdio::null())
                .stdout(Stdio::null())
                .stderr(Stdio::null())
                .spawn()
            {
                Ok(child) => {
                    eprintln!("KnowBase backend started: {}", candidate.display());
                    return Self {
                        child: Mutex::new(Some(child)),
                    };
                }
                Err(error) => {
                    eprintln!(
                        "Failed to start KnowBase backend at {}: {error}",
                        candidate.display()
                    );
                }
            }
        }

        eprintln!(
            "KnowBase backend executable was not found; desktop shell will start without it."
        );
        Self {
            child: Mutex::new(None),
        }
    }
}

impl Drop for BackendProcess {
    fn drop(&mut self) {
        let Ok(mut child) = self.child.lock() else {
            return;
        };

        if let Some(mut child) = child.take() {
            let _ = child.kill();
            let _ = child.wait();
        }
    }
}

fn manifest_dir() -> PathBuf {
    option_env!("CARGO_MANIFEST_DIR")
        .map(PathBuf::from)
        .unwrap_or_else(|| env::current_dir().unwrap_or_else(|_| PathBuf::from(".")))
}

fn backend_exe_candidates(
    manifest_dir: &Path,
    resource_dir: Option<&Path>,
    current_exe: Option<&Path>,
    override_path: Option<&Path>,
) -> Vec<PathBuf> {
    let mut candidates = Vec::new();

    if let Some(path) = override_path {
        candidates.push(path.to_path_buf());
    }

    if let Some(path) = resource_dir {
        candidates.push(path.join(BACKEND_EXE_NAME));
    }

    if let Some(path) = current_exe.and_then(packaged_backend_path_from_current_exe) {
        candidates.push(path);
    }

    if let Some(path) = dev_backend_path_from_manifest_dir(manifest_dir) {
        candidates.push(path);
    }

    candidates
}

fn packaged_backend_path_from_current_exe(current_exe: &Path) -> Option<PathBuf> {
    current_exe.parent().map(|dir| dir.join(BACKEND_EXE_NAME))
}

fn dev_backend_path_from_manifest_dir(manifest_dir: &Path) -> Option<PathBuf> {
    manifest_dir
        .parent()
        .and_then(Path::parent)
        .map(|repo_root| {
            repo_root
                .join("backend")
                .join("dist")
                .join(BACKEND_EXE_NAME)
        })
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::path::{Path, PathBuf};

    #[test]
    fn dev_backend_path_uses_repo_root_from_tauri_manifest_dir() {
        let manifest_dir = Path::new(r"D:\Codex_AI_Workspace\knowbase\frontend\src-tauri");

        let path = dev_backend_path_from_manifest_dir(manifest_dir);

        assert_eq!(
            path,
            Some(PathBuf::from(
                r"D:\Codex_AI_Workspace\knowbase\backend\dist\KnowBaseBackend.exe"
            ))
        );
    }

    #[test]
    fn backend_candidates_prefer_explicit_env_path() {
        let manifest_dir = Path::new(r"D:\Codex_AI_Workspace\knowbase\frontend\src-tauri");
        let current_exe = Path::new(r"D:\Apps\KnowBase\KnowBase.exe");
        let override_path = Path::new(r"D:\Runtime\KnowBaseBackend.exe");

        let candidates =
            backend_exe_candidates(manifest_dir, None, Some(current_exe), Some(override_path));

        assert_eq!(candidates[0], override_path);
    }

    #[test]
    fn backend_candidates_include_packaged_and_dev_paths() {
        let manifest_dir = Path::new(r"D:\Codex_AI_Workspace\knowbase\frontend\src-tauri");
        let current_exe = Path::new(r"D:\Apps\KnowBase\KnowBase.exe");

        let candidates = backend_exe_candidates(manifest_dir, None, Some(current_exe), None);

        assert!(candidates.contains(&PathBuf::from(r"D:\Apps\KnowBase\KnowBaseBackend.exe")));
        assert!(candidates.contains(&PathBuf::from(
            r"D:\Codex_AI_Workspace\knowbase\backend\dist\KnowBaseBackend.exe"
        )));
    }

    #[test]
    fn backend_candidates_include_resource_dir_before_packaged_path() {
        let manifest_dir = Path::new(r"D:\Codex_AI_Workspace\knowbase\frontend\src-tauri");
        let resource_dir = Path::new(r"D:\Apps\KnowBase\resources");
        let current_exe = Path::new(r"D:\Apps\KnowBase\KnowBase.exe");

        let candidates =
            backend_exe_candidates(manifest_dir, Some(resource_dir), Some(current_exe), None);

        assert_eq!(
            candidates[0],
            PathBuf::from(r"D:\Apps\KnowBase\resources\KnowBaseBackend.exe")
        );
        assert_eq!(
            candidates[1],
            PathBuf::from(r"D:\Apps\KnowBase\KnowBaseBackend.exe")
        );
    }
}
