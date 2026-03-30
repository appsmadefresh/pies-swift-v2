import UIKit
import Foundation

public enum EventType: String, Sendable {
    case newInstall
    case sessionStart
    case inAppPurchase
    case deviceActiveToday
}

final class EventEmitter {

    private let appId: String
    private let apiKey: String
    private let baseURL: String
    private let deviceId: String
    private let defaults: UserDefaults
    private let cache: EventCache
    private let logger = PiesLogger.shared

    private static let session: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        return URLSession(configuration: config)
    }()

    init(appId: String, apiKey: String, baseURL: String, deviceId: String, defaults: UserDefaults) {
        self.appId = appId
        self.apiKey = apiKey
        self.baseURL = baseURL
        self.deviceId = deviceId
        self.defaults = defaults
        self.cache = EventCache(defaults: defaults)
    }

    func sendEvent(ofType type: EventType, userInfo: [String: Any]? = nil) async {
        guard !deviceId.isEmpty else { return }
        let event = buildEvent(type: type, userInfo: userInfo)
        await sendEvent(event)
    }

    func sendEvent(_ event: [String: Any]) async {
        switch trackingStatus {
        case .active: break
        case .paused:
            if defaults.bool(forKey: PiesKey.stopTrackingCacheEnabled) {
                await cache.push(event)
            }
            return
        case .stopped:
            return
        }

        guard NetworkMonitor.shared.isOnline else {
            await cache.push(event)
            return
        }

        guard let request = buildRequest(event: event) else { return }

        let eventType = event["eventType"] as? String ?? "unknown"
        logger.debug("Sending event: \(eventType)")

        do {
            let (data, response) = try await Self.session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else { return }

            switch httpResponse.statusCode {
            case 200:
                handleResponse(data: data, event: event)
            case 400, 401, 403:
                logger.error("Server rejected event (\(httpResponse.statusCode))")
            default:
                await cache.putBack(event)
            }
        } catch {
            logger.debug("Network error: \(error.localizedDescription)")
            await cache.putBack(event)
        }
    }

    func sendCachedEvents() async {
        guard !defaults.bool(forKey: PiesKey.trackingStopped) else { return }
        guard NetworkMonitor.shared.isOnline else { return }

        let events = await cache.drainAll()
        for event in events {
            await sendEvent(event)
        }
    }

    // MARK: - Event building

    private static let appVersion: String = {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
    }()

    private func buildEvent(type: EventType, userInfo: [String: Any]?) -> [String: Any] {
        var event: [String: Any] = [
            "timestamp": Date().timeIntervalSince1970,
            "eventType": type.rawValue,
            "deviceId": deviceId,
            "deviceType": UIDevice.modelIdentifier,
            "appVersion": Self.appVersion,
            "frameworkVersion": "2.0.0",
            "osVersion": UIDevice.current.systemVersion,
            "locale": Locale.current.identifier,
        ]

        if let region = Locale.current.region?.identifier {
            event["regionCode"] = region
        }

        if let userInfo {
            for (key, value) in userInfo {
                event[key] = value
            }
        }

        return event
    }

    // MARK: - Request building

    private func buildRequest(event: [String: Any]) -> URLRequest? {
        guard let url = URL(string: "\(baseURL)/trackEvent") else {
            logger.error("Invalid base URL")
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Pies-iOS/2.0.0", forHTTPHeaderField: "User-Agent")

        let body: [String: Any] = [
            "appId": appId,
            "apiKey": apiKey,
            "event": event,
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            logger.error("Failed to serialize event")
            return nil
        }

        return request
    }

    // MARK: - Response handling

    private func handleResponse(data: Data, event: [String: Any]) {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let stop = json["stopTracking"] as? Bool, stop,
              let reason = json["stopTrackingReason"] as? String else { return }

        let duration = json["stopTrackingDuration"] as? Int ?? 0
        let cacheEnabled = json["stopTrackingCacheEnabled"] as? Bool ?? false
        let until = duration > 0 ? Date().timeIntervalSince1970 + TimeInterval(duration) : 0

        defaults.set(until, forKey: PiesKey.stopTrackingUntil)
        defaults.set(reason, forKey: PiesKey.stopTrackingReason)
        defaults.set(cacheEnabled, forKey: PiesKey.stopTrackingCacheEnabled)
        defaults.set(true, forKey: PiesKey.trackingStopped)

        if duration == 0 {
            logger.debug("Tracking stopped. Reason: \(reason)")
        } else {
            logger.debug("Tracking paused for \(duration)s. Reason: \(reason)")
            if cacheEnabled {
                Task { await cache.push(event) }
            }
        }
    }

    // MARK: - Tracking status

    private enum TrackingStatus {
        case active, paused, stopped
    }

    private var trackingStatus: TrackingStatus {
        let stopped = defaults.bool(forKey: PiesKey.trackingStopped)
        guard stopped else { return .active }

        let until = defaults.double(forKey: PiesKey.stopTrackingUntil)
        if until == 0 { return .stopped }

        if Date().timeIntervalSince1970 < until {
            return .paused
        } else {
            defaults.set(false, forKey: PiesKey.trackingStopped)
            return .active
        }
    }
}
