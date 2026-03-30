import UIKit

enum EventBuilder {

    private static let appVersion: String = {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
    }()

    static func build(type: EventType, deviceId: String, userInfo: [String: Any]?) -> [String: Any] {
        var event: [String: Any] = [
            EventField.timestamp.rawValue: Date().timeIntervalSince1970,
            EventField.eventType.rawValue: type.rawValue,
            EventField.deviceId.rawValue: deviceId,
            EventField.deviceType.rawValue: UIDevice.modelIdentifier,
            EventField.appVersion.rawValue: appVersion,
            EventField.frameworkVersion.rawValue: "2.0.0",
            EventField.osVersion.rawValue: UIDevice.current.systemVersion,
            EventField.locale.rawValue: Locale.current.identifier,
        ]

        if let region = Locale.current.region?.identifier {
            event[EventField.regionCode.rawValue] = region
        }

        if let userInfo {
            for (key, value) in userInfo {
                event[key] = value
            }
        }

        return event
    }
}
