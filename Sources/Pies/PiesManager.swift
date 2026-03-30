import UIKit
import StoreKit

final class PiesManager {
    static let shared = PiesManager()

    private let defaults = UserDefaults.pies
    private var eventEmitter: EventEmitter?
    private var storeObserver: StoreObserver?
    private var transactionTask: Task<Void, Never>?
    private var isConfigured = false

    private static let lastBackgroundTimestampKey = "pies-last-background-timestamp"
    private static let continueSessionInterval: TimeInterval = 5

    private static let iso8601Calendar: Calendar = Calendar(identifier: .iso8601)

    var deviceId: String? {
        PiesKeychain.get(PiesKeychain.deviceIdKey)
    }

    func configure(appId: String, apiKey: String, baseURL: String, logLevel: PiesLogLevel) {
        if isConfigured {
            transactionTask?.cancel()
            NotificationCenter.default.removeObserver(self)
        }

        PiesLogger.shared.level = logLevel

        ensureDeviceId()

        NetworkMonitor.shared.start()

        let emitter = EventEmitter(
            appId: appId,
            apiKey: apiKey,
            baseURL: baseURL,
            deviceId: PiesKeychain.get(PiesKeychain.deviceIdKey) ?? "",
            defaults: defaults
        )
        self.eventEmitter = emitter

        // File I/O and keychain access happen off the main thread.
        Task(priority: .background) { [weak self] in
            self?.checkForNewInstall()
        }

        let observer = StoreObserver(eventEmitter: emitter)
        self.storeObserver = observer
        transactionTask = Task(priority: .background) {
            await observer.listenForTransactions()
        }

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
        if PiesKeychain.get(PiesKeychain.deviceIdKey) == nil {
            let id = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
            PiesKeychain.set(id, forKey: PiesKeychain.deviceIdKey)
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

        let isFirstInstall = PiesKeychain.get(PiesKeychain.firstInstallDateKey) == nil
        if isFirstInstall {
            PiesKeychain.set("\(installDate.timeIntervalSince1970)", forKey: PiesKeychain.firstInstallDateKey)
        }

        Task {
            var info: [String: Any]? = nil
            if isFirstInstall { info = ["isFirstInstall": true] }
            await eventEmitter?.sendEvent(ofType: .newInstall, userInfo: info)
        }
    }

    // MARK: - Active device tracking

    private func sendActiveDevice() {
        let now = Date()
        let startOfDay = Int(Self.iso8601Calendar.startOfDay(for: now).timeIntervalSince1970)
        let stored = defaults.string(forKey: PiesKey.deviceActiveTodayDate).flatMap { Int($0) }
        if stored == nil || stored != startOfDay {
            defaults.set("\(startOfDay)", forKey: PiesKey.deviceActiveTodayDate)
            Task { await eventEmitter?.sendEvent(ofType: .deviceActiveToday) }
        }
    }

    deinit {
        transactionTask?.cancel()
        NotificationCenter.default.removeObserver(self)
    }
}
