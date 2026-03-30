import Foundation

extension Date {

    var startOfDay: Int {
        let cal = Calendar(identifier: .iso8601)
        return Int(cal.startOfDay(for: self).timeIntervalSince1970)
    }
}
