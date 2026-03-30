import os

final class PiesLogger {
    static let shared = PiesLogger()

    var level: PiesLogLevel = .info

    private let logger = Logger(subsystem: "com.fresh.Pies", category: "Pies")

    func info(_ message: String) {
        guard level == .info || level == .error || level == .debug else { return }
        logger.info("Pies [Info] \(message)")
    }

    func error(_ message: String) {
        guard level == .error || level == .debug else { return }
        logger.error("Pies [Error] \(message)")
    }

    func debug(_ message: String) {
        guard level == .debug else { return }
        logger.debug("Pies [Debug] \(message)")
    }
}
