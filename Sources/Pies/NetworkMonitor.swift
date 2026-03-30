import Network

final class NetworkMonitor {
    static let shared = NetworkMonitor()

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.fresh.Pies.NetworkMonitor")

    var isOnline: Bool {
        monitor.currentPath.status == .satisfied
    }

    func start() {
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}
