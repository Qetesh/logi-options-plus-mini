import Foundation
import Logging

/// Download type enumeration
enum DownloadType {
    case installer
    case offlineInstaller
    case patch
    
    var fileName: String {
        switch self {
        case .installer:
            return "logioptionsplus_installer.zip"
        case .offlineInstaller:
            return "logioptionsplus_installer_offline.zip"
        case .patch:
            return "logioptionsplus_installer_patch.zip"
        }
    }

    var extractionDirectoryName: String {
        switch self {
        case .installer:
            return "logioptionsplus_installer"
        case .offlineInstaller:
            return "logioptionsplus_installer_offline"
        case .patch:
            return "logioptionsplus_installer_patch"
        }
    }

    var installerAppBundleName: String {
        switch self {
        case .installer:
            return "logioptionsplus_installer.app"
        case .offlineInstaller:
            return "logioptionsplus_installer_offline.app"
        case .patch:
            return "logioptionsplus_installer.app"
        }
    }

    var supportsRegionalDownloadSource: Bool {
        switch self {
        case .installer, .offlineInstaller:
            return true
        case .patch:
            return false
        }
    }

    func downloadURLString(isInChina: Bool) -> String {
        switch self {
        case .installer:
            return isInChina
                ? "https://download.logitech.com.cn/web/ftp/pub/techsupport/optionsplus/logioptionsplus_installer.zip"
                : "https://download01.logi.com/web/ftp/pub/techsupport/optionsplus/logioptionsplus_installer.zip"
        case .offlineInstaller:
            return isInChina
                ? "https://download.logitech.com.cn/web/ftp/pub/techsupport/optionsplus/logioptionsplus_installer_offline.zip"
                : "https://download01.logi.com/web/ftp/pub/techsupport/optionsplus/logioptionsplus_installer_offline.zip"
        case .patch:
            return "https://download01.logi.com/web/ftp/pub/techsupport/optionsplus/logioptionsplus_installer_patch.zip"
        }
    }
}

class Downloader: NSObject, URLSessionDownloadDelegate {
    private let regionDetector = RegionDetector.shared
    private var progressHandler: (@Sendable (Double) -> Void)?
    private var downloadContinuation: CheckedContinuation<Void, Error>?
    private var destinationURL: URL?
    private var fileMoveError: Error?
    private var lastLoggedPercent = -1

    func downloadInstaller(
        type: DownloadType = .installer,
        progressHandler: @escaping @Sendable (Double) -> Void = { _ in }
    ) async throws {
        let isInChina: Bool

        if type.supportsRegionalDownloadSource {
            switch InstallerDownloadSource.current {
            case .automatic:
                isInChina = await regionDetector.detectRegion()
            case .global:
                isInChina = false
                Logger.app.info("🌐 \(String(localized: "Download source")): \(String(localized: "Global"))")
            case .china:
                isInChina = true
                Logger.app.info("🌐 \(String(localized: "Download source")): \(String(localized: "China"))")
            }
        } else {
            isInChina = false
        }

        let urlString = type.downloadURLString(isInChina: isInChina)
        
        guard let url = URL(string: urlString) else {
            Logger.app.error("\(String(localized: "Invalid download URL")): \(urlString)")
            throw NSError(domain: "DownloadError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid download URL"])
        }
        
        Logger.app.info("⏬ \(String(localized: "Downloading installer from")) \(urlString)")
        
        let destinationURL = FileUtils.temporaryFileURL(forFileName: type.fileName)
        
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = URLCache(memoryCapacity: 4 * 1024 * 1024, diskCapacity: 20 * 1024 * 1024, directory: nil)
        configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        
        self.progressHandler = progressHandler
        self.destinationURL = destinationURL
        self.fileMoveError = nil
        self.lastLoggedPercent = -1
        progressHandler(0)

        let delegateQueue = OperationQueue()
        delegateQueue.maxConcurrentOperationCount = 1
        let session = URLSession(configuration: configuration, delegate: self, delegateQueue: delegateQueue)
        defer {
            self.progressHandler = nil
            self.destinationURL = nil
            self.fileMoveError = nil
            session.finishTasksAndInvalidate()
        }
        
        do {
            try await withCheckedThrowingContinuation { continuation in
                self.downloadContinuation = continuation
                session.downloadTask(with: url).resume()
            }

            progressHandler(1)
        
            Logger.app.debug("✅ \(String(localized: "Download complete to")) \(destinationURL.path)")
        } catch {
            Logger.app.error("\(String(localized: "Download failed")): \(error.localizedDescription)")
            throw error
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard totalBytesExpectedToWrite > 0 else { return }

        let progress = min(max(Double(totalBytesWritten) / Double(totalBytesExpectedToWrite), 0), 1)
        progressHandler?(progress)

        let percent = Int(progress * 100)
        if percent != lastLoggedPercent {
            lastLoggedPercent = percent
            Logger.app.debug("⏬ \(percent)%")
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        Logger.app.debug("\(String(localized: "Downloaded file to")): \(location.path)")

        guard let destinationURL else {
            fileMoveError = NSError(
                domain: "DownloadError",
                code: 4,
                userInfo: [NSLocalizedDescriptionKey: "Missing download destination"]
            )
            return
        }

        do {
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            try FileManager.default.moveItem(at: location, to: destinationURL)
        } catch {
            fileMoveError = error
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let continuation = downloadContinuation else { return }
        downloadContinuation = nil

        if let error {
            continuation.resume(throwing: error)
            return
        }

        if let fileMoveError {
            continuation.resume(throwing: fileMoveError)
            return
        }

        guard let httpResponse = task.response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            let statusCode = (task.response as? HTTPURLResponse)?.statusCode ?? -1
            Logger.app.error("\(String(localized: "Download failed")): \(String(localized: "Server returned error code")) \(statusCode)")
            continuation.resume(
                throwing: NSError(
                    domain: "DownloadError",
                    code: 3,
                    userInfo: [NSLocalizedDescriptionKey: "invalid response status code"]
                )
            )
            return
        }

        continuation.resume()
    }
}
