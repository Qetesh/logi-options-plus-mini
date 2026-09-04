//
//  UpdaterManager.swift
//  Logi Options+ mini
//
//  Singleton for managing Sparkle updater across the app
//

import Foundation
import Sparkle
import Logging

enum logiOptionsPlusMiniServer: String, CaseIterable, Identifiable {
    case Automatic
    case Global
    case China

    static let userDefaultsKey = "selectedlogiOptionsPlusMiniServer"

    var id: Self { self }

    var description: String {
        switch self {
        case .Automatic:
            return String(localized: "Automatic")
        case .Global:
            return String(localized: "Global")
        case .China:
            return String(localized: "China")
        }
    }

    static var current: Self {
        guard let rawValue = UserDefaults.standard.string(forKey: userDefaultsKey) else {
            return .Global
        }
        return Self(rawValue: rawValue) ?? .Global
    }
}

private final class UpdateFeedURLProvider: NSObject, SPUUpdaterDelegate {
    var feedURLString: String?

    func feedURLString(for updater: SPUUpdater) -> String? {
        feedURLString
    }
}

final class UpdaterManager {
    static let shared = UpdaterManager()

    let controller: SPUStandardUpdaterController
    var updater: SPUUpdater { controller.updater }

    private let feedURLProvider: UpdateFeedURLProvider
    private let regionDetector = RegionDetector.shared
    private var updaterHasStarted = false
    private var updaterStartTask: Task<Void, Never>?
    private var appliedServer: logiOptionsPlusMiniServer?

    private let chinaFeedURLString = "https://v.qetesh.cc/d/Public/appcast.xml"

    private init() {
        let feedURLProvider = UpdateFeedURLProvider()
        self.feedURLProvider = feedURLProvider
        controller = SPUStandardUpdaterController(
            startingUpdater: false,
            updaterDelegate: feedURLProvider,
            userDriverDelegate: nil
        )

        // Keep the persisted fixed server available until the updater is started.
        // Legacy feed URL defaults are cleared on the main actor before Sparkle starts.
        if logiOptionsPlusMiniServer.current == .China {
            feedURLProvider.feedURLString = chinaFeedURLString
        }
    }

    /// Starts Sparkle after the initial server is resolved when automatic selection
    /// is enabled. This prevents Sparkle's first scheduled check from bypassing
    /// region detection.
    func start() {
        Task { @MainActor [weak self] in
            await self?.startUpdaterIfNeeded()
        }
    }

    /// Resolve the selected update server immediately before a user- or
    /// application-initiated update check.
    func checkForUpdates() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            await startUpdaterIfNeeded()
            await configureUpdateServer()
            updater.checkForUpdates()
        }
    }

    func checkForUpdatesInBackground() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            await startUpdaterIfNeeded()
            await configureUpdateServer()
            updater.checkForUpdatesInBackground()
        }
    }

    @MainActor
    func setUpdateServer(_ server: logiOptionsPlusMiniServer) {
        UserDefaults.standard.set(server.rawValue, forKey: logiOptionsPlusMiniServer.userDefaultsKey)
        if server != .Automatic {
            applyUpdateServer(server)
        }

        Logger.app.info("\(String(localized: "Update server changed to")): \(server.description)")

        guard updaterHasStarted else { return }

        if server == .Automatic {
            Task { @MainActor [weak self] in
                guard let self else { return }
                await configureUpdateServer()
                updater.resetUpdateCycle()
            }
        } else {
            updater.resetUpdateCycle()
        }
    }

    func setAutomaticallyChecksForUpdates(_ enabled: Bool) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            await startUpdaterIfNeeded()

            if enabled && logiOptionsPlusMiniServer.current == .Automatic {
                await configureUpdateServer()
            }

            updater.automaticallyChecksForUpdates = enabled
        }
    }

    @MainActor
    private func startUpdaterIfNeeded() async {
        guard !updaterHasStarted else { return }

        if let updaterStartTask {
            await updaterStartTask.value
            return
        }

        let task = Task { @MainActor [weak self] in
            guard let self else { return }

            let selectedServer = logiOptionsPlusMiniServer.current
            if updater.automaticallyChecksForUpdates && selectedServer == .Automatic {
                await configureUpdateServer()
            } else {
                applyUpdateServer(selectedServer)
            }

            controller.startUpdater()
            updaterHasStarted = true
        }

        updaterStartTask = task
        await task.value
        updaterStartTask = nil
    }

    @MainActor
    private func configureUpdateServer() async {
        let selectedServer = logiOptionsPlusMiniServer.current

        switch selectedServer {
        case .Automatic:
            let isInChina = await regionDetector.detectRegion()

            // The user may change the selection while the network request is in flight.
            // Do not let a stale automatic result override that newer choice.
            guard logiOptionsPlusMiniServer.current == .Automatic else {
                applyUpdateServer(logiOptionsPlusMiniServer.current)
                return
            }

            let resolvedServer: logiOptionsPlusMiniServer = isInChina ? .China : .Global
            applyUpdateServer(resolvedServer)
        case .Global, .China:
            applyUpdateServer(selectedServer)
        }
    }

    /// Updates the delegate and clears legacy Sparkle feed URL defaults.
    /// This method must be called on the main actor because Sparkle requires
    /// feed URL changes on the main thread.
    @MainActor
    private func applyUpdateServer(_ server: logiOptionsPlusMiniServer) {
        let resolvedServer: logiOptionsPlusMiniServer = server == .China ? .China : .Global
        guard appliedServer != resolvedServer else { return }

        _ = updater.clearFeedURLFromUserDefaults()
        feedURLProvider.feedURLString = resolvedServer == .China ? chinaFeedURLString : nil
        appliedServer = resolvedServer
        Logger.app.debug("🌐 \(String(localized: "Update server")): \(updateFeedURLString(for: resolvedServer))")
    }

    private func updateFeedURLString(for server: logiOptionsPlusMiniServer) -> String {
        switch server {
        case .Automatic, .Global:
            return Bundle.main.infoDictionary?["SUFeedURL"] as? String ?? ""
        case .China:
            return chinaFeedURLString
        }
    }
}
