mod backup;
mod commands;
mod downloader;
mod exe_version;
mod installer;
mod models;
mod version;

use commands::{
    check_update_with_endpoint, create_app_state, download_and_install_with_endpoint, emit_log,
    get_features, get_installed_version, get_latest_version, get_version_info, install, install_offline,
    uninstall,
};
use tauri::Manager;
use window_vibrancy::*;

#[cfg(target_os = "windows")]
fn acrylic_tint(theme: Option<tauri::Theme>) -> Option<(u8, u8, u8, u8)> {
    match theme {
        Some(tauri::Theme::Dark) => Some((30, 30, 30, 125)),
        _ => Some((255, 255, 255, 125)),
    }
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    // Initialize logger
    env_logger::Builder::from_env(env_logger::Env::default().default_filter_or("info")).init();

    log::info!("Starting Logi Options+ mini application...");

    tauri::Builder::default()
        .plugin(tauri_plugin_process::init())
        .plugin(tauri_plugin_updater::Builder::new().build())
        .plugin(tauri_plugin_opener::init())
        .plugin(tauri_plugin_shell::init())
        .plugin(tauri_plugin_dialog::init())
        .plugin(tauri_plugin_fs::init())
        .manage(create_app_state())
        .invoke_handler(tauri::generate_handler![
            get_features,
            get_installed_version,
            get_latest_version,
            get_version_info,
            install,
            uninstall,
            install_offline,
            emit_log,
            check_update_with_endpoint,
            download_and_install_with_endpoint,
        ])
        .setup(|app| {
            #[cfg(target_os = "windows")]
            {
                for label in ["main", "settings", "update"] {
                    if let Some(window) = app.get_webview_window(label) {
                        let _ = apply_acrylic(&window, acrylic_tint(window.theme().ok()));
                    }
                }
            }

            Ok(())
        })
        .on_window_event(|window, event| {
            #[cfg(target_os = "windows")]
            if let tauri::WindowEvent::ThemeChanged(theme) = event {
                let _ = apply_acrylic(window, acrylic_tint(Some(*theme)));
            }

            if window.label() == "main" && matches!(event, tauri::WindowEvent::CloseRequested { .. })
            {
                log::info!("Main window close requested, exiting application...");
                window.app_handle().exit(0);
            }
        })
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
