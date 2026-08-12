use std::{
    env,
    fmt::Write as FmtWrite,
    fs, io,
    io::{Read, Write},
    net::{Ipv4Addr, SocketAddr, SocketAddrV4, TcpStream},
    path::{Path, PathBuf},
    process::{Child, Command, Stdio},
    sync::Mutex,
    thread,
    time::{Duration, Instant},
};

#[cfg(windows)]
use std::os::windows::process::CommandExt;

const BACKEND_EXE_NAME: &str = "KnowBaseBackend.exe";
const BACKEND_HOST: &str = "127.0.0.1";
const PREFERRED_BACKEND_PORT: u16 = 8000;
const BACKEND_START_TIMEOUT: Duration = Duration::from_secs(20);
const DESKTOP_CORS_ORIGINS: &str = r#"["http://localhost:3000","tauri://localhost","http://tauri.localhost","https://tauri.localhost"]"#;
#[cfg(windows)]
const CREATE_NO_WINDOW: u32 = 0x08000000;

pub struct BackendProcess {
    child: Mutex<Option<Child>>,
    port: Option<u16>,
    capability_token: Option<String>,
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

            let capability_token = match generate_desktop_token() {
                Ok(token) => token,
                Err(error) => {
                    eprintln!("Failed to generate the desktop capability token: {error}");
                    break;
                }
            };
            let ready_file = env::temp_dir().join(format!(
                "knowbase-backend-ready-{}-{}.txt",
                std::process::id(),
                &capability_token[..16]
            ));
            let _ = fs::remove_file(&ready_file);
            let mut command = Command::new(&candidate);
            command
                .env("KNOWBASE_BACKEND_HOST", BACKEND_HOST)
                .env("KNOWBASE_BACKEND_PORT", PREFERRED_BACKEND_PORT.to_string())
                .env("KNOWBASE_BACKEND_READY_FILE", &ready_file)
                .env("KNOWBASE_DESKTOP_TOKEN", &capability_token)
                .env("CORS_ORIGINS", DESKTOP_CORS_ORIGINS)
                .stdin(Stdio::null())
                .stdout(Stdio::null())
                .stderr(Stdio::null());

            #[cfg(windows)]
            {
                command.creation_flags(CREATE_NO_WINDOW);
            }

            match command.spawn() {
                Ok(mut child) => {
                    let readiness = wait_for_backend(
                        &mut child,
                        &ready_file,
                        &capability_token,
                        BACKEND_START_TIMEOUT,
                    );
                    let _ = fs::remove_file(&ready_file);
                    match readiness {
                        Ok(port) => {
                            eprintln!("KnowBase backend started: {}", candidate.display());
                            return Self {
                                child: Mutex::new(Some(child)),
                                port: Some(port),
                                capability_token: Some(capability_token),
                            };
                        }
                        Err(error) => {
                            eprintln!("KnowBase backend failed readiness checks: {error}");
                            stop_child(&mut child);
                        }
                    }
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
            capability_token: None,
        }
    }

    pub fn base_url(&self) -> Result<String, String> {
        self.port
            .map(|port| format!("http://{BACKEND_HOST}:{port}"))
            .ok_or_else(|| "KnowBase backend is not running".to_string())
    }

    pub fn capability_token(&self) -> Result<String, String> {
        self.capability_token
            .clone()
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

#[cfg(windows)]
fn generate_desktop_token() -> io::Result<String> {
    const BCRYPT_USE_SYSTEM_PREFERRED_RNG: u32 = 0x00000002;
    #[link(name = "bcrypt")]
    extern "system" {
        fn BCryptGenRandom(
            algorithm: *mut std::ffi::c_void,
            buffer: *mut u8,
            buffer_len: u32,
            flags: u32,
        ) -> i32;
    }

    let mut bytes = [0u8; 32];
    let status = unsafe {
        BCryptGenRandom(
            std::ptr::null_mut(),
            bytes.as_mut_ptr(),
            bytes.len() as u32,
            BCRYPT_USE_SYSTEM_PREFERRED_RNG,
        )
    };
    if status != 0 {
        return Err(io::Error::new(
            io::ErrorKind::Other,
            format!("BCryptGenRandom failed with status {status}"),
        ));
    }
    let mut token = String::with_capacity(bytes.len() * 2);
    for byte in bytes {
        let _ = write!(&mut token, "{byte:02x}");
    }
    Ok(token)
}

#[cfg(not(windows))]
fn generate_desktop_token() -> io::Result<String> {
    Err(io::Error::new(
        io::ErrorKind::Unsupported,
        "KnowBase desktop is supported on Windows only",
    ))
}

fn backend_health_request(capability_token: &str) -> String {
    format!(
        "GET /api/desktop/health HTTP/1.1\r\nHost: {BACKEND_HOST}\r\nX-KnowBase-Desktop-Token: {capability_token}\r\nConnection: close\r\n\r\n"
    )
}

fn is_healthy_backend_response(response: &[u8]) -> bool {
    let response = String::from_utf8_lossy(response);
    (response.starts_with("HTTP/1.1 200 ") || response.starts_with("HTTP/1.0 200 "))
        && response.contains("{\"status\":\"ok\"}")
}

fn wait_for_backend(
    child: &mut Child,
    ready_file: &Path,
    capability_token: &str,
    timeout: Duration,
) -> Result<u16, String> {
    let deadline = Instant::now() + timeout;
    while Instant::now() < deadline {
        if let Some(status) = child.try_wait().map_err(|error| error.to_string())? {
            return Err(format!("backend process exited with {status}"));
        }
        let Ok(port_text) = fs::read_to_string(ready_file) else {
            thread::sleep(Duration::from_millis(100));
            continue;
        };
        let Ok(port) = port_text.trim().parse::<u16>() else {
            thread::sleep(Duration::from_millis(100));
            continue;
        };
        let address = SocketAddr::V4(SocketAddrV4::new(Ipv4Addr::LOCALHOST, port));
        if let Ok(mut stream) = TcpStream::connect_timeout(&address, Duration::from_millis(200)) {
            let _ = stream.set_read_timeout(Some(Duration::from_millis(500)));
            let _ = stream.set_write_timeout(Some(Duration::from_millis(500)));
            if stream
                .write_all(backend_health_request(capability_token).as_bytes())
                .is_ok()
            {
                let mut response = Vec::new();
                if stream.take(8192).read_to_end(&mut response).is_ok()
                    && is_healthy_backend_response(&response)
                {
                    return Ok(port);
                }
            }
        }
        thread::sleep(Duration::from_millis(100));
    }
    Err("backend health check timed out".to_string())
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
    fn health_probe_carries_desktop_capability_token() {
        let request = backend_health_request("secret-token");

        assert!(request.starts_with("GET /api/desktop/health HTTP/1.1\r\n"));
        assert!(request.contains("X-KnowBase-Desktop-Token: secret-token\r\n"));
    }

    #[test]
    fn health_probe_accepts_only_successful_knowbase_response() {
        assert!(is_healthy_backend_response(
            b"HTTP/1.1 200 OK\r\ncontent-length: 15\r\n\r\n{\"status\":\"ok\"}"
        ));
        assert!(!is_healthy_backend_response(
            b"HTTP/1.1 403 Forbidden\r\ncontent-length: 9\r\n\r\nForbidden"
        ));
        assert!(!is_healthy_backend_response(
            b"HTTP/1.1 200 OK\r\ncontent-length: 2\r\n\r\n{}"
        ));
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
