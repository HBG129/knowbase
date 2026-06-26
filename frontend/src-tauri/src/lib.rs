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
