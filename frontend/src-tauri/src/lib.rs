mod backend_runtime;

use tauri::Manager;

pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_opener::init())
        .setup(|app| {
            app.manage(backend_runtime::BackendProcess::start());
            Ok(())
        })
        .run(tauri::generate_context!())
        .expect("error while running KnowBase");
}
