//
//  RegionDetector.swift
//  Logi Options Plus Mini
//
//  Created by Qetesh Wong on 21/1/2025.
//

import SwiftUI
import Foundation
import Logging

enum InstallerDownloadSource: String, CaseIterable, Identifiable {
    case automatic
    case global
    case china

    static let userDefaultsKey = "installerDownloadSource"

    var id: Self { self }

    var title: String {
        switch self {
        case .automatic:
            return String(localized: "Automatic")
        case .global:
            return String(localized: "Global")
        case .china:
            return String(localized: "China")
        }
    }

    static var current: InstallerDownloadSource {
        guard let rawValue = UserDefaults.standard.string(forKey: userDefaultsKey) else {
            return .automatic
        }
        return InstallerDownloadSource(rawValue: rawValue) ?? .automatic
    }
}

/// Region detector for determining if user is in mainland China
class RegionDetector: ObservableObject {
    static let shared = RegionDetector()

    @Published var isInChina: Bool = false
    @Published var isDetecting: Bool = false
    @Published var errorMessage: String? = nil
    
    private static let traceURL = "https://cloudflare.com/cdn-cgi/trace"
    private let cacheDuration: TimeInterval
    private let fetchRegion: @MainActor () async throws -> Bool
    private var lastDetectionDate: Date?
    private var detectionTask: Task<Bool, Never>?

    init(
        cacheDuration: TimeInterval = 2 * 60,
        fetchRegion: @escaping @MainActor () async throws -> Bool = { try await RegionDetector.fetchRegionInfo() }
    ) {
        self.cacheDuration = cacheDuration
        self.fetchRegion = fetchRegion
    }
    
    /// Share concurrent requests and briefly reuse both successful results and the fallback.
    @MainActor
    @discardableResult
    func detectRegion() async -> Bool {
        if let detectionTask {
            return await detectionTask.value
        }
        if let lastDetectionDate, Date().timeIntervalSince(lastDetectionDate) < cacheDuration {
            return isInChina
        }

        isDetecting = true
        errorMessage = nil

        let task = Task { @MainActor in
            defer {
                self.lastDetectionDate = Date()
                self.isDetecting = false
                self.detectionTask = nil
            }

            do {
                Logger.app.info("🗺️ \(String(localized: "Region detection via")) \(Self.traceURL)")
                self.isInChina = try await self.fetchRegion()
                Logger.app.info("🗺️ \(String(localized: "Region")): \(self.isInChina ? String(localized: "China") : String(localized: "Global"))")
            } catch {
                self.errorMessage = "Detection failed: \(error.localizedDescription)"
                self.isInChina = false
                Logger.app.warning("\(String(localized: "Unable to detect location. Using the Global source.")) \(error.localizedDescription)")
            }
            return self.isInChina
        }

        detectionTask = task
        return await task.value
    }
    
    /// Fetch region information from Cloudflare
    private static func fetchRegionInfo() async throws -> Bool {
        guard let url = URL(string: traceURL) else {
            throw RegionError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.timeoutInterval = 10.0
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw RegionError.networkFailed
        }
        
        guard let responseText = String(data: data, encoding: .utf8) else {
            throw RegionError.invalidData
        }
        
        return responseText.contains("loc=CN")
    }
}

/// Region detection errors
enum RegionError: LocalizedError {
    case invalidURL
    case networkFailed
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .networkFailed: return "Network request failed"
        case .invalidData: return "Invalid response data"
        }
    }
}

extension RegionDetector {
    /// Region status description
    var statusDescription: String {
        if isDetecting { return "Detecting..." }
        if errorMessage != nil { return "Error" }
        return regionCode
    }
    
    /// Region code (CN or GLOBAL)
    var regionCode: String {
        isInChina ? "China" : "Global"
    }
}
