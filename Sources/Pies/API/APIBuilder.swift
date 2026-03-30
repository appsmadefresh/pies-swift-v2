import Foundation

enum APIBuilder {

    static func request(event: [String: Any], appId: String, apiKey: String, baseURL: String) -> URLRequest? {
        guard let url = URL(string: "\(baseURL)/trackEvent") else {
            PiesLogger.shared.error("Invalid base URL: \(baseURL)")
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "appId": appId,
            "apiKey": apiKey,
            "event": event,
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            PiesLogger.shared.error("Failed to serialize event: \(error.localizedDescription)")
            return nil
        }

        return request
    }
}
