import Foundation

extension Date {

    private static let iso8601Calendar: Calendar = {
        Calendar(identifier: .iso8601)
    }()

    var startOfDay: Int {
        Int(Self.iso8601Calendar.startOfDay(for: self).timeIntervalSince1970)
    }
}
