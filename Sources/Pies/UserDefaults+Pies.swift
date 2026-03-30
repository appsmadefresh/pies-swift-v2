import Foundation

enum PiesKey {
    static let deviceId = "pies-device-id"
    static let installDate = "pies-install-date"
    static let deviceActiveTodayDate = "pies-device-active-today-date"
    static let stopTrackingUntil = "pies-stop-tracking-until"
    static let stopTrackingReason = "pies-stop-tracking-reason"
    static let trackingStopped = "pies-tracking-stopped"
    static let stopTrackingCacheEnabled = "pies-stop-tracking-cache-enabled"
}

extension UserDefaults {
    static let pies = UserDefaults(suiteName: "com.pies.framework.v2")!
}
