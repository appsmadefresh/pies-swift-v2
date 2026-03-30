import UIKit
import StoreKit
import os

final class PiesManager {
    static let shared = PiesManager()

    private let defaults = UserDefaults.pies
    private var eventEmitter: EventEmitter?
    private var storeObserver: StoreObserver?
    private var transactionTask: Task<Void, Never>?
    private var isConfigured = false

    private static let lastBackgroundTimestampKey = "last-app-background-timestamp"
    private static let continueSessionInterval: TimeInterval = 5

    var deviceId: String? {
        defaults.string(forKey: PiesKey.deviceId)
    }

    private let keychain: KeychainSwift = {
        let kc = KeychainSwift()
        kc.synchronizable = true
        return kc
    }()

    func configure(appId: String, apiKey: String, baseURL: String, logLevel: PiesLogLevel) {
        // Clean up if configure() is called more than once.
        if isConfigured {
            transactionTask?.cancel()
            NotificationCenter.default.removeObserver(self)
        }

        PiesLogger.shared.level = logLevel

        defaults.set(appId, forKey: PiesKey.appId)
        defaults.set(apiKey, forKey: PiesKey.apiKey)
        defaults.set(baseURL, forKey: PiesKey.baseURL)

        // Ensure device ID exists before creating the emitter.
        ensureDeviceId()

        NetworkMonitor.shared.start()

        let emitter = EventEmitter(
            appId: appId,
            apiKey: apiKey,
            baseURL: baseURL,
            deviceId: defaults.string(forKey: PiesKey.deviceId) ?? "",
            defaults: defaults
        )
        self.eventEmitter = emitter

        // File I/O and keychain access happen off the main thread.
        Task.detached { [weak self] in
            self?.checkForNewInstall()
        }

        let observer = StoreObserver(eventEmitter: emitter)
        self.storeObserver = observer
        transactionTask = Task.detached { await observer.listenForTransactions() }

        startListening()
        isConfigured = true

        PiesLogger.shared.info("Initialized Pies v2")
    }

    // MARK: - App lifecycle

    private func startListening() {
        NotificationCenter.default.addObserver(
            self, selector: #selector(didBecomeActive),
            name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(
            self, selector: #selector(didMoveToBackground),
            name: UIApplication.willResignActiveNotification, object: nil)
    }

    @objc private func didBecomeActive() {
        if let last = defaults.object(forKey: Self.lastBackgroundTimestampKey) as? TimeInterval {
            let elapsed = Date().timeIntervalSince1970 - last
            if elapsed <= Self.continueSessionInterval { return }
        }

        Task {
            await eventEmitter?.sendCachedEvents()
            await eventEmitter?.sendEvent(ofType: .sessionStart)
            sendActiveDevice()
        }
    }

    @objc private func didMoveToBackground() {
        defaults.set(Date().timeIntervalSince1970, forKey: Self.lastBackgroundTimestampKey)
    }

    // MARK: - Device ID

    private func ensureDeviceId() {
        if defaults.string(forKey: PiesKey.deviceId) == nil {
            let id = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
            defaults.set(id, forKey: PiesKey.deviceId)
        }
    }

    // MARK: - Install detection (runs off main thread)

    private func checkForNewInstall() {
        guard defaults.string(forKey: PiesKey.installDate) == nil else { return }

        guard let docsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last,
              let attrs = try? FileManager.default.attributesOfItem(atPath: docsURL.path),
              let installDate = attrs[.creationDate] as? Date else { return }

        defaults.set("\(installDate.timeIntervalSince1970)", forKey: PiesKey.installDate)

        let elapsed = Date().timeIntervalSince1970 - installDate.timeIntervalSince1970
        guard elapsed <= 86400 else { return }

        let isFirstInstall = keychain.get(KeychainKey.firstInstallDate) == nil
        if isFirstInstall {
            keychain.set("\(installDate.timeIntervalSince1970)", forKey: KeychainKey.firstInstallDate)
        }

        Task {
            var info: [String: Any]? = nil
            if isFirstInstall { info = [EventField.isFirstInstall.rawValue: true] }
            await eventEmitter?.sendEvent(ofType: .newInstall, userInfo: info)
        }
    }

    // MARK: - Active device tracking (daily only — WAU/MAU derived in Postgres)

    private func sendActiveDevice() {
        let now = Date()
        let stored = defaults.string(forKey: PiesKey.deviceActiveTodayDate).flatMap { Int($0) }
        if stored == nil || stored != now.startOfDay {
            defaults.set("\(now.startOfDay)", forKey: PiesKey.deviceActiveTodayDate)
            Task { await eventEmitter?.sendEvent(ofType: .deviceActiveToday) }
        }
    }

    deinit {
        transactionTask?.cancel()
        NotificationCenter.default.removeObserver(self)
    }
}
