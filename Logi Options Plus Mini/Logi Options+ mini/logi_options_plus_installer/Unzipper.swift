import Foundation
import ZipArchive
import Logging

class Unzipper {
    func unzipInstaller(type: DownloadType = .installer) async throws {
        let zipURL = FileUtils.temporaryFileURL(forFileName: type.fileName)
        let destinationFolder = type.extractionDirectoryName
        let destinationFolderURL = FileUtils.temporaryFileURL(forFileName: destinationFolder)
        
        let success = SSZipArchive.unzipFile(atPath: zipURL.path, toDestination: destinationFolderURL.path)
        guard success else {
            throw NSError(domain: "Unzipper", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Failed to extract \(zipURL.lastPathComponent)"
            ])
        }
        Logger.app.info("🗜️ \(String(localized: "File extracted to")): \(destinationFolderURL.path)")
    }
}
