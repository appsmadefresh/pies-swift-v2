import Foundation

/// Thread-safe event cache backed by UserDefaults.
actor EventCache {

    private let defaults: UserDefaults
    private static let key = "pies-cached-events"
    private static let maxSize = 500

    init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    func push(_ event: [String: Any]) {
        var events = loadEvents()
        if events.count >= Self.maxSize {
            events.removeFirst()
        }
        events.append(event)
        save(events)
    }

    func putBack(_ event: [String: Any]) {
        var events = loadEvents()
        events.insert(event, at: 0)
        if events.count > Self.maxSize {
            events.removeLast()
        }
        save(events)
    }

    /// Drain all cached events in one UserDefaults round-trip.
    func drainAll() -> [[String: Any]] {
        let events = loadEvents()
        if !events.isEmpty {
            save([])
        }
        return events.compactMap { $0 as? [String: Any] }
    }

    var count: Int {
        loadEvents().count
    }

    private func loadEvents() -> [Any] {
        defaults.array(forKey: Self.key) ?? []
    }

    private func save(_ events: [Any]) {
        defaults.set(events, forKey: Self.key)
    }
}
