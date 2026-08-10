use std::{
    env, io,
    net::TcpListener,
    path::{Path, PathBuf},
    process::{Child, Command, Stdio},
    sync::Mutex,
};

#[cfg(windows)]
use std::os::windows::process::CommandExt;

const BACKEND_EXE_NAME: &str = "KnowBaseBackend.exe";
const BACKEND_HOST: &str = "127.0.0.1";
const PREFERRED_BACKEND_PORT: u16 = 8000;
const DESKTOP_CORS_ORIGINS: &str = r#"["http://localhost:3000","tauri://localhost","http://tauri.localhost","https://tauri.localhost"]"#;
#[cfg(windows)]
const CREATE_NO_WINDOW: u32 = 0x08000000;

pub struct BackendProcess {
    child: Mutex<Option<Child>>,
    port: Option<u16>,
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

            let port = match select_backend_port() {
                Ok(port) => port,
                Err(error) => {
                    eprintln!("Failed to select a KnowBase backend port: {error}");
                    break;
                }
            };
            let mut command = Command::new(&candidate);
            command
                .env("KNOWBASE_BACKEND_HOST", BACKEND_HOST)
                .env("KNOWBASE_BACKEND_PORT", port.to_string())
                .env("CORS_ORIGINS", DESKTOP_CORS_ORIGINS)
                .stdin(Stdio::null())
                .stdout(Stdio::null())
                .stderr(Stdio::null());

            #[cfg(windows)]
            {
                command.creation_flags(CREATE_NO_WINDOW);
            }

            match command.spawn() {
                Ok(child) => {
                    eprintln!("KnowBase backend started: {}", candidate.display());
                    return Self {
                        child: Mutex::new(Some(child)),
                        port: Some(port),
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
            port: None,
        }
    }

    pub fn base_url(&self) -> Result<String, String> {
        self.port
            .map(|port| format!("http://{BACKEND_HOST}:{port}"))
            .ok_or_else(|| "KnowBase backend is not running".to_string())
    }

    pub fn stop(&self) {
        let Ok(mut child) = self.child.lock() else {
            return;
        };

        if let Some(mut child) = child.take() {
            stop_child(&mut child);
        }
    }
}

fn select_backend_port() -> io::Result<u16> {
    select_backend_port_with_preferred(PREFERRED_BACKEND_PORT)
}

fn select_backend_port_with_preferred(preferred_port: u16) -> io::Result<u16> {
    match TcpListener::bind((BACKEND_HOST, preferred_port)) {
        Ok(listener) => listener.local_addr().map(|address| address.port()),
        Err(_) => {
            let listener = TcpListener::bind((BACKEND_HOST, 0))?;
            listener.local_addr().map(|address| address.port())
        }
    }
}

impl Drop for BackendProcess {
    fn drop(&mut self) {
        self.stop();
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

fn stop_child(child: &mut Child) {
    #[cfg(windows)]
    {
        let _ = Command::new("taskkill")
            .args(windows_taskkill_args(child.id()))
            .stdin(Stdio::null())
            .stdout(Stdio::null())
            .stderr(Stdio::null())
            .status();
    }

    #[cfg(not(windows))]
    {
        let _ = child.kill();
    }

    let _ = child.wait();
}

#[cfg(windows)]
fn windows_taskkill_args(pid: u32) -> Vec<String> {
    vec![
        "/F".to_string(),
        "/T".to_string(),
        "/PID".to_string(),
        pid.to_string(),
    ]
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::path::{Path, PathBuf};

    #[test]
    fn backend_port_falls_back_when_preferred_port_is_occupied() {
        let occupied = TcpListener::bind((BACKEND_HOST, 0)).expect("bind occupied port");
        let occupied_port = occupied.local_addr().expect("occupied address").port();

        let selected = select_backend_port_with_preferred(occupied_port)
            .expect("select fallback backend port");

        assert_ne!(selected, occupied_port);
    }

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

    #[cfg(windows)]
    #[test]
    fn windows_taskkill_args_kill_process_tree() {
        assert_eq!(
            windows_taskkill_args(1234),
            vec!["/F", "/T", "/PID", "1234"]
        );
    }

    #[cfg(windows)]
    #[test]
    fn windows_backend_process_uses_no_console_flag() {
        assert_eq!(CREATE_NO_WINDOW, 0x08000000);
    }
}
