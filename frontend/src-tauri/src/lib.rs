mod backend_runtime;

use tauri::Manager;

pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_opener::init())
        .setup(|app| {
            let resource_dir = app.path().resource_dir().ok();
            app.manage(backend_runtime::BackendProcess::start(resource_dir));
            Ok(())
        })
        .run(tauri::generate_context!())
        .expect("error while running KnowBase");
}
