use log::{debug, error, info};
use std::path::PathBuf;
use std::process::Command;
use tauri::Emitter;

use crate::backup::BackupManager;
use crate::downloader::Downloader;
use crate::exe_version;
use crate::models::InstallResult;
use crate::version::get_installed_version_with_app;

fn emit_log_internal(app: &tauri::AppHandle, message: &str, level: &str) {
    // Emit to frontend
    let _ = app.emit(
        "log-message",
        serde_json::json!({
            "message": message,
            "level": level,
        }),
    );
    // Also log to console
    match level {
        "error" => error!("{}", message),
        "debug" => debug!("{}", message),
        _ => info!("{}", message),
    }
}

pub struct Installer {
    temp_dir: PathBuf,
    downloader: Downloader,
    backup_manager: BackupManager,
}

/// 读取安装程序 exe 文件属性中的版本，按 `exe_version::PARAM_SUPPORT_RULES`
/// 计算各安装参数的支持状态。
///
/// 结果会写入日志，并通过 `installer-param-support` 事件发送给前端，
/// 前端据此在功能列表中禁用/恢复对应选项；下载的安装包被清理后，
/// 状态会随 `installer-cache-cleared` 事件重置。
/// 读取版本失败时所有参数按"支持"处理，保持旧行为。
fn check_installer_param_support(
    app: &tauri::AppHandle,
    installer_path: &std::path::Path,
) -> Vec<(&'static exe_version::ParamSupportRule, bool)> {
    match exe_version::get_file_version_string(installer_path) {
        Some(version) => {
            emit_log_internal(app, &format!("Installer file version: {}", version), "info");
            let support = exe_version::evaluate_param_support(&version);
            for (rule, supported) in &support {
                if *supported {
                    emit_log_internal(
                        app,
                        &format!("Parameter /{} is supported by this installer", rule.param),
                        "debug",
                    );
                } else {
                    emit_log_internal(
                        app,
                        &format!(
                            "Parameter /{} is not supported since installer {}, skipping it",
                            rule.param,
                            exe_version::format_version(&rule.unsupported_since)
                        ),
                        "info",
                    );
                }
            }
            emit_installer_param_support(app, &Some(version), &support);
            support
        }
        None => {
            emit_log_internal(
                app,
                "Unable to read installer file version, assuming all parameters are supported",
                "warn",
            );
            let support: Vec<(&'static exe_version::ParamSupportRule, bool)> =
                exe_version::PARAM_SUPPORT_RULES
                    .iter()
                    .map(|rule| (rule, true))
                    .collect();
            emit_installer_param_support(app, &None, &support);
            support
        }
    }
}

/// 向前端发送安装程序参数支持状态（`installer-param-support` 事件）。
fn emit_installer_param_support(
    app: &tauri::AppHandle,
    version: &Option<String>,
    support: &[(&'static exe_version::ParamSupportRule, bool)],
) {
    let mut params = serde_json::Map::new();
    for (rule, supported) in support {
        params.insert(rule.param.to_string(), serde_json::Value::Bool(*supported));
    }
    let _ = app.emit(
        "installer-param-support",
        serde_json::json!({
            "version": version,
            "params": params,
        }),
    );
}

/// 通知前端：下载的安装包（下载缓存）已被删除，据此判定的参数支持状态一并失效。
fn emit_installer_cache_cleared(app: &tauri::AppHandle) {
    emit_log_internal(
        app,
        "Downloaded installer removed, installer parameter support state cleared",
        "debug",
    );
    let _ = app.emit("installer-cache-cleared", serde_json::json!({}));
}

impl Installer {
    pub fn new() -> Self {
        let temp_dir = std::env::temp_dir().join("logi_options_plus_mini");

        // Create temp directory if not exists (use std::fs for sync creation in constructor)
        std::fs::create_dir_all(&temp_dir).ok();

        Installer {
            temp_dir,
            downloader: Downloader::new(),
            backup_manager: BackupManager::new(),
        }
    }

    pub async fn install(
        &mut self,
        app: tauri::AppHandle,
        selected_features: Vec<(String, bool)>,
        source: Option<String>,
    ) -> Result<InstallResult, String> {
        emit_log_internal(&app, "Starting installation process...", "info");

        // Step 1: Detect region (or use manually chosen download source)
        self.downloader.detect_region_with_app(&app, source.as_deref()).await?;

        // Step 2: Download installer
        self.prepare_temp_dir(&app);
        emit_log_internal(&app, "Step 1/5: Downloading installer...", "info");
        let installer_path = self
            .downloader
            .download_installer_with_app(&app, &self.temp_dir)
            .await?;

        // Step 3: Backup configuration
        emit_log_internal(&app, "Step 2/5: Backing up configuration...", "info");
        if let Err(e) = self.backup_manager.backup(&app).await {
            emit_log_internal(&app, &format!("Failed to backup config: {}", e), "error");
        }

        // Step 4: Uninstall existing version
        emit_log_internal(&app, "Step 3/5: Uninstalling existing version...", "info");
        self.uninstall_internal(&app, &installer_path).await?;

        // Step 5: Restore configuration
        emit_log_internal(&app, "Step 4/5: Restoring configuration...", "info");
        if let Err(e) = self.backup_manager.restore(&app).await {
            emit_log_internal(&app, &format!("Failed to restore config: {}", e), "error");
        }

        // Step 6: Install new version
        emit_log_internal(&app, "Step 5/5: Installing new version...", "info");
        self.install_internal(&app, &installer_path, &selected_features)
            .await?;

        // Get installed version
        let version = get_installed_version_with_app(Some(&app));

        // Clean up temp directory after successful installation
        self.remove_temp_dir(&app);

        emit_log_internal(&app, "Installation completed successfully!", "info");
        Ok(InstallResult {
            success: true,
            message: "Installation completed successfully!".to_string(),
            version: Some(version),
        })
    }

    pub async fn install_offline(
        &mut self,
        app: tauri::AppHandle,
        selected_features: Vec<(String, bool)>,
        source: Option<String>,
    ) -> Result<InstallResult, String> {
        emit_log_internal(&app, "Starting offline installation process...", "info");

        // Step 1: Detect region (or use manually chosen download source)
        self.downloader.detect_region_with_app(&app, source.as_deref()).await?;

        // Step 2: Download offline installer
        self.prepare_temp_dir(&app);
        emit_log_internal(&app, "Step 1/5: Downloading offline installer...", "info");
        let installer_path = self
            .downloader
            .download_offline_installer_with_app(&app, &self.temp_dir)
            .await?;

        // Step 3: Backup configuration
        emit_log_internal(&app, "Step 2/5: Backing up configuration...", "info");
        if let Err(e) = self.backup_manager.backup(&app).await {
            emit_log_internal(&app, &format!("Failed to backup config: {}", e), "error");
        }

        // Step 4: Uninstall existing version
        emit_log_internal(&app, "Step 3/5: Uninstalling existing version...", "info");
        self.uninstall_internal(&app, &installer_path).await?;

        // Step 5: Restore configuration
        emit_log_internal(&app, "Step 4/5: Restoring configuration...", "info");
        if let Err(e) = self.backup_manager.restore(&app).await {
            emit_log_internal(&app, &format!("Failed to restore config: {}", e), "error");
        }

        // Step 6: Install new version
        emit_log_internal(&app, "Step 5/5: Installing new version...", "info");
        self.install_internal(&app, &installer_path, &selected_features)
            .await?;

        // Get installed version
        let version = get_installed_version_with_app(Some(&app));

        // Clean up temp directory after successful offline installation
        self.remove_temp_dir(&app);

        emit_log_internal(&app, "Offline installation completed successfully!", "info");
        Ok(InstallResult {
            success: true,
            message: "Offline installation completed successfully!".to_string(),
            version: Some(version),
        })
    }

    pub async fn uninstall(
        &mut self,
        app: tauri::AppHandle,
        source: Option<String>,
    ) -> Result<InstallResult, String> {
        emit_log_internal(&app, "Starting uninstall process...", "info");

        // Download installer (needed for uninstall command)
        self.downloader.detect_region_with_app(&app, source.as_deref()).await?;
        self.prepare_temp_dir(&app);
        let installer_path = self
            .downloader
            .download_installer_with_app(&app, &self.temp_dir)
            .await?;

        // Uninstall (uninstall_internal now waits for the registry to reflect
        // the removal, so this applies to both install-time and standalone flows)
        self.uninstall_internal(&app, &installer_path).await?;

        let version = get_installed_version_with_app(Some(&app));

        // Clean up temp directory after successful uninstallation
        self.remove_temp_dir(&app);

        emit_log_internal(&app, "Uninstallation completed successfully!", "info");
        Ok(InstallResult {
            success: true,
            message: "Uninstallation completed successfully!".to_string(),
            version: Some(version),
        })
    }

    /// Remove the temporary working directory.
    /// Safe to call when the directory does not exist (skipped) or removal
    /// fails (logged as a warning, does not propagate).
    ///
    /// 下载的安装包被删除后，据此判定的安装参数支持状态一并失效，
    /// 通知前端重置（`installer-cache-cleared` 事件）。
    fn remove_temp_dir(&self, app: &tauri::AppHandle) {
        if !self.temp_dir.exists() {
            emit_log_internal(
                app,
                &format!(
                    "Temp directory not found, skipping cleanup: {}",
                    self.temp_dir.display()
                ),
                "debug",
            );
            return;
        }

        match std::fs::remove_dir_all(&self.temp_dir) {
            Ok(()) => {
                emit_log_internal(
                    app,
                    &format!(
                        "Temp directory cleaned up: {}",
                        self.temp_dir.display()
                    ),
                    "info",
                );
                // 安装包已删除，参数支持状态的判定依据消失，通知前端清除
                emit_installer_cache_cleared(app);
            }
            Err(e) => {
                emit_log_internal(
                    app,
                    &format!(
                        "Failed to clean up temp directory {}: {}",
                        self.temp_dir.display(),
                        e
                    ),
                    "warn",
                );
                // 清理失败安装包仍在磁盘上，保留已判定的参数支持状态
            }
        }
    }

    /// Clean (remove) the temp directory before downloading, then recreate it.
    /// This ensures stale files from previous runs don't interfere with the
    /// new download. Safe against a missing directory.
    fn prepare_temp_dir(&self, app: &tauri::AppHandle) {
        // Remove any stale temp directory from a previous run
        self.remove_temp_dir(app);

        // Recreate the temp directory for the upcoming download
        if let Err(e) = std::fs::create_dir_all(&self.temp_dir) {
            emit_log_internal(
                app,
                &format!(
                    "Failed to create temp directory {}: {}",
                    self.temp_dir.display(),
                    e
                ),
                "error",
            );
        }
    }

    async fn uninstall_internal(
        &self,
        app: &tauri::AppHandle,
        installer_path: &PathBuf,
    ) -> Result<(), String> {
        emit_log_internal(app, "Running uninstall command...", "info");

        // Run the installer with /uninstall argument
        let output = Command::new(installer_path)
            .arg("/uninstall")
            .output()
            .map_err(|e| format!("Failed to run uninstaller: {}", e))?;

        if !output.status.success() {
            let stderr = String::from_utf8_lossy(&output.stderr);
            emit_log_internal(app, &format!("Uninstall output: {}", stderr), "debug");
            // Note: Some uninstalls may return non-zero even when successful
            // We continue anyway
        }

        // Wait for the uninstaller to actually finish by polling the registry
        // until the application is no longer detected as installed.
        // This ensures both install-time and standalone uninstalls confirm
        // completion the same way.
        self.wait_for_uninstall_complete(app).await;

        Ok(())
    }

    /// Poll the registry (and filesystem) until the application is no longer
    /// detected as installed, confirming the uninstall process has finished.
    async fn wait_for_uninstall_complete(&self, app: &tauri::AppHandle) {
        const MAX_ATTEMPTS: u32 = 300; // up to ~300s
        const POLL_INTERVAL: std::time::Duration = std::time::Duration::from_secs(1);

        emit_log_internal(
            app,
            &format!(
                "Waiting for uninstall to complete (timeout: {}s)...",
                MAX_ATTEMPTS
            ),
            "info",
        );

        for _attempt in 1..=MAX_ATTEMPTS {
            tokio::time::sleep(POLL_INTERVAL).await;

            let status = get_installed_version_with_app(Some(app));
            if status == "not installed" {
                emit_log_internal(app, "Uninstall complete.", "info");
                // Extra wait after uninstall so files/registry are fully
                // released before any subsequent action (e.g. reinstall).
                tokio::time::sleep(std::time::Duration::from_secs(10)).await;
                return;
            }
        }

        emit_log_internal(
            app,
            &format!(
                "Uninstall wait timed out after {}s; continuing anyway.",
                MAX_ATTEMPTS
            ),
            "warn",
        );
    }

    async fn install_internal(
        &self,
        app: &tauri::AppHandle,
        installer_path: &PathBuf,
        features: &[(String, bool)],
    ) -> Result<(), String> {
        emit_log_internal(
            app,
            "Running install command with selected features...",
            "info",
        );

        // 根据下载的安装程序 exe 文件属性中的版本，计算各安装参数的支持状态
        //（在线安装和离线安装均经过此处；规则见 exe_version::PARAM_SUPPORT_RULES）
        let param_support = check_installer_param_support(app, installer_path);

        // 过滤掉当前安装程序版本不支持的参数，安装时不传递
        let unsupported_params: Vec<&str> = param_support
            .iter()
            .filter(|(_, supported)| !supported)
            .map(|(rule, _)| rule.param)
            .collect();
        let features: Vec<(String, bool)> = features
            .iter()
            .filter(|(id, _)| !unsupported_params.contains(&id.as_str()))
            .cloned()
            .collect();

        // Build arguments
        let mut args = Vec::new();

        for (feature_id, enabled) in &features {
            match feature_id.as_str() {
                "quiet" => {
                    if *enabled {
                        args.push("/quiet".to_string());
                    }
                }
                "analytics" => {
                    args.push("/analytics".to_string());
                    args.push(if *enabled {
                        "Yes".to_string()
                    } else {
                        "No".to_string()
                    });
                }
                "flow" => {
                    args.push("/flow".to_string());
                    args.push(if *enabled {
                        "Yes".to_string()
                    } else {
                        "No".to_string()
                    });
                }
                "sso" => {
                    args.push("/sso".to_string());
                    args.push(if *enabled {
                        "Yes".to_string()
                    } else {
                        "No".to_string()
                    });
                }
                "update" => {
                    args.push("/update".to_string());
                    args.push(if *enabled {
                        "Yes".to_string()
                    } else {
                        "No".to_string()
                    });
                }
                "dfu" => {
                    args.push("/dfu".to_string());
                    args.push(if *enabled {
                        "Yes".to_string()
                    } else {
                        "No".to_string()
                    });
                }
                "backlight" => {
                    args.push("/backlight".to_string());
                    args.push(if *enabled {
                        "Yes".to_string()
                    } else {
                        "No".to_string()
                    });
                }
                "logivoice" => {
                    args.push("/logivoice".to_string());
                    args.push(if *enabled {
                        "Yes".to_string()
                    } else {
                        "No".to_string()
                    });
                }
                "aipromptbuilder" => {
                    args.push("/aipromptbuilder".to_string());
                    args.push(if *enabled {
                        "Yes".to_string()
                    } else {
                        "No".to_string()
                    });
                }
                "device-recommendation" => {
                    args.push("/device-recommendation".to_string());
                    args.push(if *enabled {
                        "Yes".to_string()
                    } else {
                        "No".to_string()
                    });
                }
                "smartactions" => {
                    args.push("/smartactions".to_string());
                    args.push(if *enabled {
                        "Yes".to_string()
                    } else {
                        "No".to_string()
                    });
                }
                "actions-ring" => {
                    args.push("/actions-ring".to_string());
                    args.push(if *enabled {
                        "Yes".to_string()
                    } else {
                        "No".to_string()
                    });
                }
                _ => {}
            }
        }

        // Send install arguments to frontend as debug level
        emit_log_internal(
            app,
            &format!("Install arguments: {:?}", args),
            "debug",
        );

        // Run installer with elevated privileges
        let output = Command::new(installer_path)
            .args(&args)
            .output()
            .map_err(|e| format!("Failed to run installer: {}", e))?;

        if !output.status.success() {
            let stderr = String::from_utf8_lossy(&output.stderr);
            emit_log_internal(app, &format!("Install failed: {}", stderr), "error");
            return Err(format!(
                "Installation failed with exit code: {:?}",
                output.status.code()
            ));
        }

        emit_log_internal(app, "Installation command completed successfully", "info");
        Ok(())
    }

    pub async fn get_latest_version(&self) -> Result<String, String> {
        self.downloader.get_latest_version().await
    }
}

impl Default for Installer {
    fn default() -> Self {
        Self::new()
    }
}
