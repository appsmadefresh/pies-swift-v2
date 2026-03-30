import Foundation
import os

final class EventEmitter {

    private let defaults: UserDefaults
    private let cache: EventCache
    private let logger = PiesLogger.shared

    init(defaults: UserDefaults) {
        self.defaults = defaults
        self.cache = EventCache(defaults: defaults)
    }

    func sendEvent(ofType type: EventType, userInfo: [String: Any]? = nil) async {
        guard let deviceId = defaults.string(forKey: PiesKey.deviceId) else { return }

        if type == .sessionEnd {
            logger.debug("Session End events are not currently supported.")
            return
        }

        let event = EventBuilder.build(type: type, deviceId: deviceId, userInfo: userInfo)
        await sendEvent(event)
    }

    func sendEvent(_ event: [String: Any]) async {
        guard let appId = defaults.string(forKey: PiesKey.appId),
              let apiKey = defaults.string(forKey: PiesKey.apiKey) else { return }

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

        let baseURL = defaults.string(forKey: PiesKey.baseURL)
            ?? "https://pies-server-v2-production.up.railway.app"

        guard let request = APIBuilder.request(
            event: event, appId: appId, apiKey: apiKey, baseURL: baseURL
        ) else { return }

        let eventType = event[EventField.eventType.rawValue] as? String ?? "unknown"
        logger.debug("Sending event: \(eventType)")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else { return }

            switch httpResponse.statusCode {
            case 200:
                handleResponse(data: data, event: event)
            case 400:
                logger.error("Invalid request (400)")
            case 401:
                logger.error("Unauthorized (401)")
            case 403:
                logger.error("Forbidden (403)")
            default:
                // Retryable — cache the event.
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

        let count = await cache.count
        for _ in 0..<count {
            if let event = await cache.pop() {
                await sendEvent(event)
            }
        }
    }

    // MARK: - Private

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
