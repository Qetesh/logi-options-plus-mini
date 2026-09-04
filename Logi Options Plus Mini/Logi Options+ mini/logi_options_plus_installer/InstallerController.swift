import Foundation
import Logging
import SwiftUI

/// Operation mode enumeration
enum OperationMode {
    case install
    case uninstall
    case fix
    case idle
}

@MainActor
class InstallerController: NSObject, ObservableObject {
    @Published var features: [Feature] = Feature.allCases
    @Published var selectedFeatures: Set<Feature> = []
    @Published private(set) var unsupportedFeatures: Set<Feature> = []
    @Published var confirmation: Bool = false
    @Published var systemLog: String = ""
    @Published var installedVersion: String = ""
    @Published var currentStep: InstallationStep = .idle
    @Published var downloadProgress: Double = 0
    @Published var failedAtStep: InstallationStep? = nil  // Track which step failed
    @Published var showActivityLog: Bool = false
    @Published var operationMode: OperationMode = .idle
    @Published var filesToDelete: [URL] = []  // JavaScript error fix - files pending deletion
    @Published var showDeleteFilesConfirmation: Bool = false  // JavaScript error fix confirmation
    @Published var showNoFilesToDeleteAlert: Bool = false  // No files to delete alert
    
    private let featureToArgumentMap: [Feature: String] = [
        .quiet: "--quiet",
        .analytics: "--analytics",
        .flow: "--flow",
        .sso: "--sso",
        .update: "--update",
        .dfu: "--dfu",
        .backlight: "--backlight",
        .logivoice: "--logivoice",
        .aipromptbuilder: "--aipromptbuilder",
        .deviceRecommendation: "--device-recommendation",
        .smartactions: "--smartactions",
        .actionsRing: "--actions-ring",
        .installAdobePlugins: "--install-adobe-plugins"
    ]
    
    private let downloader = Downloader()
    private let unzipper = Unzipper()
    private let installerRunner = InstallerRunner()
    private let backupManager = BackupManager()
    private let jsErrorFixer = JavaScriptErrorFixer()
    
    override init() {
        super.init()
        updateInstalledVersion()
    }

    func install() async {
        await install(using: .installer)
    }

    func installOffline() async {
        await install(using: .offlineInstaller)
    }

    private func install(using downloadType: DownloadType) async {
        // Set operation mode
        operationMode = .install
        failedAtStep = nil
        downloadProgress = 0
        unsupportedFeatures = []
        
        do {
            // Step 1: Download the installer
            currentStep = .downloading
            try await downloadInstaller(type: downloadType)
            
            // Step 2: Unzip the installer
            currentStep = .extracting
            try await unzipper.unzipInstaller(type: downloadType)

            // Check this installer's capabilities before uninstalling the current version.
            let supportedArguments = try await installerRunner.supportedArguments(
                for: Array(featureToArgumentMap.values), type: downloadType
            )
            updateFeatureAvailability(supportedArguments: supportedArguments)
            let selectedFeaturesString = generateFeatureArgumentString(supportedArguments: supportedArguments)
            Logger.app.debug("\(String(localized: "Selected features string")): \(selectedFeaturesString)")
            
            // Step 3: Backup configuration files
            currentStep = .backup
            backupManager.performOperation(operation: "backup")
            
            // Step 4: Uninstall
            currentStep = .uninstalling
            try await installerRunner.runInstaller(selectedFeatures: "--uninstall", type: downloadType)
            updateInstalledVersion()
            
            // Step 5: Restore configuration
            currentStep = .restoring
            backupManager.performOperation(operation: "restore")
            
            // Step 6: Install
            currentStep = .installing
            try await installerRunner.runInstaller(selectedFeatures: selectedFeaturesString, type: downloadType)
            updateInstalledVersion()
            
            // Step 7: Verify installation and complete
            if installedVersion == "not installed" {
                failedAtStep = .installing
                currentStep = .failed
                Logger.app.error("❌ \(String(localized: "Installation verification failed"))")
                return
            }
            currentStep = .completed
        } catch {
            failedAtStep = currentStep
            currentStep = .failed
            Logger.app.error("\(String(localized: "Installation failed")): \(error.localizedDescription)\n")

            if isPermissionDenied(error) {
                Logger.app.error("❌ \(String(localized: "The application requires App Management permissions. Please go to System Settings -> Privacy & Security -> App Management, and grant the necessary permissions."))")
                // 自动打开权限检查器窗口
                PermissionChecker.shared.showPermissionWindow()
            }
            return
        }
        
        Logger.app.info("🎉\(String(localized: "Installation completed"))\n")
    }
    
    func uninstall() async {
        await uninstall(using: .installer)
    }

    private func uninstall(using downloadType: DownloadType) async {
        // Set operation mode
        operationMode = .uninstall
        failedAtStep = nil
        downloadProgress = 0
        
        Logger.app.info("\(String(localized: "Starting uninstallation..."))")
        
        do {
            // Step 1: Download the installer (needed for uninstall command)
            currentStep = .downloading
            try await downloadInstaller(type: downloadType)
            
            // Step 2: Unzip the installer
            currentStep = .extracting
            try await unzipper.unzipInstaller(type: downloadType)
            
            // Step 3: Uninstall without backup
            currentStep = .uninstalling
            try await installerRunner.runInstaller(selectedFeatures: "--uninstall", type: downloadType)
            updateInstalledVersion()
            
            // Completed
            currentStep = .completed
        } catch {
            failedAtStep = currentStep
            currentStep = .failed
            Logger.app.error("\(String(localized: "Uninstallation failed")): \(error.localizedDescription)\n")
            if isPermissionDenied(error) {
                Logger.app.error("❌ \(String(localized: "The application requires App Management permissions. Please go to System Settings -> Privacy & Security -> App Management, and grant the necessary permissions."))")
                // 自动打开权限检查器窗口
                PermissionChecker.shared.showPermissionWindow()
            }
            return
        }
        
        Logger.app.info("🎉\(String(localized: "Uninstallation completed"))\n")
    }
    
    func fix() async {
        // Set operation mode
        operationMode = .fix
        failedAtStep = nil
        downloadProgress = 0
        
        Logger.app.info("\(String(localized: "Starting fix..."))")
        
        do {
            // Step 1: Download the patch
            currentStep = .downloading
            try await downloadInstaller(type: .patch)
            
            // Step 2: Unzip the patch
            currentStep = .extracting
            try await unzipper.unzipInstaller(type: .patch)
            
            // Step 3: Run the patch (without arguments)
            currentStep = .installing
            try await installerRunner.runPatch()
            
            // Completed
            currentStep = .completed
        } catch {
            failedAtStep = currentStep
            currentStep = .failed
            Logger.app.error("\(String(localized: "Fix failed")): \(error.localizedDescription)\n")
            if isPermissionDenied(error) {
                Logger.app.error("❌ \(String(localized: "The application requires App Management permissions. Please go to System Settings -> Privacy & Security -> App Management, and grant the necessary permissions."))")
                // 自动打开权限检查器窗口
                PermissionChecker.shared.showPermissionWindow()
            }
            return
        }
        
        Logger.app.info("🎉\(String(localized: "Fix completed"))\n")
    }

    private func downloadInstaller(type: DownloadType) async throws {
        try await downloader.downloadInstaller(type: type) { [weak self] progress in
            Task { @MainActor in
                self?.downloadProgress = progress
            }
        }
        downloadProgress = 1
    }
    
    func saveSelectedFeatures() {
        let featureNames = selectedFeatures.map { $0.rawValue }
        UserDefaults.standard.set(featureNames, forKey: "selectedFeatures")
    }
    
    func loadSelectedFeatures() {
        if let savedFeatureNames = UserDefaults.standard.array(forKey: "selectedFeatures") as? [String] {
            selectedFeatures = Set(savedFeatureNames.compactMap { Feature(rawValue: $0) })
        }
    }
    
    /// 更新已安装版本号信息
    func updateInstalledVersion() {
        installedVersion = getLogiOptionsPlusVersion()
    }
    
    /// 扫描 JavaScript 错误相关的损坏配置文件
    func scanJavaScriptErrorFiles() async {
        Logger.app.info("\(String(localized: "Starting JavaScript error fix..."))")
        
        do {
            filesToDelete = try await jsErrorFixer.scan()
            if filesToDelete.isEmpty {
                Logger.app.info("\(String(localized: "No files need to be deleted."))")
                showNoFilesToDeleteAlert = true
            } else {
                showDeleteFilesConfirmation = true
            }
        } catch {
            Logger.app.error("\(String(localized: "Scan failed")): \(error.localizedDescription)")
            if isPermissionDenied(error) {
                PermissionChecker.shared.showPermissionWindow()
            }
        }
    }
    
    /// 确认删除扫描到的文件
    func confirmDeleteFiles() async {
        operationMode = .fix
        currentStep = .installing
        
        do {
            let deletedCount = try jsErrorFixer.deleteFiles(filesToDelete)
            if deletedCount > 0 {
                Logger.app.info("🎉 \(String(localized: "Deleted")) \(deletedCount) \(String(localized: "corrupted config backup file(s)."))")
            }
            currentStep = .completed
            filesToDelete = []
        } catch {
            failedAtStep = currentStep
            currentStep = .failed
            Logger.app.error("\(String(localized: "JavaScript error fix failed")): \(error.localizedDescription)")
            if isPermissionDenied(error) {
                PermissionChecker.shared.showPermissionWindow()
            }
            return
        }
        
        Logger.app.info("🎉\(String(localized: "JavaScript error fix completed"))\n")
    }
    
    /// 每次安装使用当前安装器的检测结果更新列表，不改变用户保存的功能选择。
    func updateFeatureAvailability(supportedArguments: Set<String>) {
        unsupportedFeatures = Set(featureToArgumentMap.compactMap { feature, argument in
            supportedArguments.contains(argument) ? nil : feature
        })
    }

    func helpText(for feature: Feature) -> String {
        guard unsupportedFeatures.contains(feature) else { return feature.help }
        return "\(String(localized: "The current installer does not support this option. It will be skipped during installation."))\n\n\(feature.help)"
    }

    /// 生成功能参数字符串
    func generateFeatureArgumentString(supportedArguments: Set<String>) -> String {
        return features.compactMap { feature -> String? in
            guard let argument = featureToArgumentMap[feature] else { return nil }
            guard supportedArguments.contains(argument) else {
                Logger.app.info("\(String(localized: "Skipping unsupported installer argument")): \(argument)")
                return nil
            }
            return buildFeatureArgument(feature: feature, argument: argument)
        }.joined(separator: " ")
    }
    
    /// 为单个功能构建参数字符串
    private func buildFeatureArgument(feature: Feature, argument: String) -> String? {
        // 无取值参数：只在选中时传入，不附加 Yes/No。
        if feature == .quiet || feature == .installAdobePlugins {
            return selectedFeatures.contains(feature) ? argument : nil
        }
        
        // 其他功能：返回参数 + 状态
        let status = selectedFeatures.contains(feature) ? "Yes" : "No"
        return "\(argument) \(status)"
    }
    
    private func isPermissionDenied(_ error: Error) -> Bool {
        let nsError = error as NSError
        
        // 1) Cocoa 写入/读取无权限
        if nsError.domain == NSCocoaErrorDomain {
            if nsError.code == NSFileWriteNoPermissionError ||
                nsError.code == NSFileReadNoPermissionError {
                return true
            }
        }
        
        // 2) POSIX 无权限：EPERM(1) / EACCES(13)
        if nsError.domain == NSPOSIXErrorDomain {
            if nsError.code == 1 /* EPERM */ || nsError.code == 13 /* EACCES */ {
                return true
            }
        }
        
        // 3) 递归检查 underlying error
        if let underlying = nsError.userInfo[NSUnderlyingErrorKey] as? NSError {
            return isPermissionDenied(underlying)
        }
        
        return false
    }
}
