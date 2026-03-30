import Foundation

/// Pies Analytics SDK — lightweight, automatic tracking for iOS apps.
@MainActor
public enum Pies {

    /// Configure Pies with your appId and apiKey.
    /// - Parameters:
    ///   - appId: Your app ID from the Pies dashboard.
    ///   - apiKey: Your API key from the Pies dashboard.
    ///   - baseURL: Override the default server URL (optional).
    ///   - logLevel: Logging verbosity (default: `.info`).
    public static func configure(
        appId: String,
        apiKey: String,
        baseURL: String = "https://pies-server-v2-production.up.railway.app",
        logLevel: PiesLogLevel = .info
    ) {
        guard !appId.isEmpty, !apiKey.isEmpty else {
            PiesLogger.shared.error("Pies.configure() requires non-empty appId and apiKey")
            return
        }
        guard baseURL.hasPrefix("https://"), URL(string: "\(baseURL)/trackEvent") != nil else {
            PiesLogger.shared.error("Pies.configure() requires a valid HTTPS base URL")
            return
        }
        PiesManager.shared.configure(appId: appId, apiKey: apiKey, baseURL: baseURL, logLevel: logLevel)
    }

    /// The unique device identifier assigned by Pies.
    public static var deviceId: String? {
        PiesManager.shared.deviceId
    }
}

public enum PiesLogLevel: Sendable {
    case none
    case info
    case error
    case debug
}
