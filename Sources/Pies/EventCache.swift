import Foundation

/// Thread-safe event cache backed by UserDefaults.
actor EventCache {

    private let defaults: UserDefaults
    private static let key = "pies-cached-events"

    init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    func push(_ event: [String: Any]) {
        var events = loadEvents()
        events.append(event)
        save(events)
    }

    func pop() -> [String: Any]? {
        var events = loadEvents()
        guard !events.isEmpty else { return nil }
        let event = events.removeFirst() as? [String: Any]
        save(events)
        return event
    }

    func putBack(_ event: [String: Any]) {
        var events = loadEvents()
        events.insert(event, at: 0)
        save(events)
    }

    var count: Int {
        loadEvents().count
    }

    var isEmpty: Bool {
        loadEvents().isEmpty
    }

    private func loadEvents() -> [Any] {
        defaults.array(forKey: Self.key) ?? []
    }

    private func save(_ events: [Any]) {
        defaults.set(events, forKey: Self.key)
    }
}
