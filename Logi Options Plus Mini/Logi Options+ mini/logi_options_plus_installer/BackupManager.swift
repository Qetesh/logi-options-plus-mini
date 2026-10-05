import Foundation
import Logging

class BackupManager {
    private let sourceDirectoryName = "LogiOptionsPlus"
    private let backupDirectoryName = "LogiOptionsPlus_bak"

    private static func directoryURL(named name: String) -> URL? {
        return FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?.appendingPathComponent(name)
    }

    func performOperation(operation: String) throws {
        guard let sourceURL = BackupManager.directoryURL(named: sourceDirectoryName),
              let backupURL = BackupManager.directoryURL(named: backupDirectoryName) else {
            Logger.app.error("\(String(localized: "Failed to get Application Support directory"))")
            throw NSError(domain: "BackupManager", code: 1, userInfo: [
                NSLocalizedDescriptionKey: String(localized: "Failed to get Application Support directory")
            ])
        }

        let fileManager = FileManager.default
        do {
            switch operation {
            case "backup":
                Logger.app.debug("\(String(localized: "Backing up configuration file..."))")
                let sourceExists = fileManager.fileExists(atPath: sourceURL.path)
                let backupExists = fileManager.fileExists(atPath: backupURL.path)
                if backupExists {
                    if sourceExists {
                        // Stale backup from an interrupted run; the live config is newer.
                        Logger.app.warning("⚠️ \(String(localized: "Found leftover configuration backup, removing it")): \(backupURL.path)")
                        try fileManager.removeItem(at: backupURL)
                    } else {
                        // No live config: keep the backup for the restore step after uninstall.
                        Logger.app.info("ℹ️ \(String(localized: "No configuration to back up, keeping existing backup")): \(backupURL.path)")
                        return
                    }
                }
                try fileManager.moveItem(at: sourceURL, to: backupURL)
                Logger.app.info("💾 \(String(localized: "Configuration file backed up to")): \(backupURL.path)")
            case "restore":
                try fileManager.moveItem(at: backupURL, to: sourceURL)
                Logger.app.info("💾 \(String(localized: "Configuration file restored to")): \(sourceURL.path)")
            default:
                throw NSError(domain: "BackupManager", code: 2, userInfo: [
                    NSLocalizedDescriptionKey: "\(String(localized: "Unknown backup operation")): \(operation)"
                ])
            }
        } catch {
            Logger.app.error("\(String(localized: "Configuration file")) \(operation) \(String(localized: "failed")): \(error.localizedDescription)")
            throw error
        }
    }
}
