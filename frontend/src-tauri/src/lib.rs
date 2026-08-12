mod backend_runtime;

use tauri::Manager;

#[tauri::command]
fn backend_base_url(
    state: tauri::State<'_, backend_runtime::BackendProcess>,
) -> Result<String, String> {
    state.base_url()
}

#[tauri::command]
fn backend_capability_token(
    state: tauri::State<'_, backend_runtime::BackendProcess>,
) -> Result<String, String> {
    state.capability_token()
}

pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_opener::init())
        .invoke_handler(tauri::generate_handler![
            backend_base_url,
            backend_capability_token
        ])
        .setup(|app| {
            let resource_dir = app.path().resource_dir().ok();
            app.manage(backend_runtime::BackendProcess::start(resource_dir));
            Ok(())
        })
        .on_window_event(|window, event| {
            if matches!(event, tauri::WindowEvent::CloseRequested { .. }) {
                window
                    .app_handle()
                    .state::<backend_runtime::BackendProcess>()
                    .stop();
            }
        })
        .build(tauri::generate_context!())
        .expect("error while building KnowBase")
        .run(|app_handle, event| {
            if matches!(
                event,
                tauri::RunEvent::ExitRequested { .. } | tauri::RunEvent::Exit
            ) {
                app_handle.state::<backend_runtime::BackendProcess>().stop();
            }
        });
}
