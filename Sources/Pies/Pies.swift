import Foundation

public final class Pies: Sendable {

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
        precondition(!appId.isEmpty && !apiKey.isEmpty, "You must provide a valid appId and apiKey.")
        PiesManager.shared.configure(appId: appId, apiKey: apiKey, baseURL: baseURL, logLevel: logLevel)
    }

    /// The unique device identifier assigned by Pies.
    public static var deviceId: String? {
        PiesManager.shared.deviceId
    }
}
