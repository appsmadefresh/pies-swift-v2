import Foundation

enum PiesKey {
    static let appId = "pies-app-id"
    static let apiKey = "pies-api-key"
    static let baseURL = "pies-base-url"
    static let deviceId = "pies-device-id"
    static let installDate = "pies-install-date"
    static let deviceActiveTodayDate = "pies-device-active-today-date"
    static let stopTrackingUntil = "pies-stop-tracking-until"
    static let stopTrackingReason = "pies-stop-tracking-reason"
    static let trackingStopped = "pies-tracking-stopped"
    static let stopTrackingCacheEnabled = "pies-stop-tracking-cache-enabled"
}

extension UserDefaults {
    static var pies: UserDefaults {
        UserDefaults(suiteName: "group.pies.framework.v2")!
    }
}
