import Foundation

enum PiesKey {
    static let installDate = "pies-install-date"
    static let deviceActiveTodayDate = "pies-device-active-today-date"
    static let stopTrackingUntil = "pies-stop-tracking-until"
    static let stopTrackingReason = "pies-stop-tracking-reason"
    static let trackingStopped = "pies-tracking-stopped"
    static let stopTrackingCacheEnabled = "pies-stop-tracking-cache-enabled"
}

extension UserDefaults {
    static let pies: UserDefaults = {
        guard let defaults = UserDefaults(suiteName: "com.pies.framework.v2") else {
            // This should never fail — non-group suite names always succeed.
            // Fall back to standard defaults so the SDK doesn't crash the host app.
            return UserDefaults.standard
        }
        return defaults
    }()
}
