import Foundation

extension Date {

    var startOfDay: Int {
        let cal = Calendar(identifier: .iso8601)
        return Int(cal.startOfDay(for: self).timeIntervalSince1970)
    }

    var startOfWeek: Int {
        var cal = Calendar(identifier: .iso8601)
        cal.firstWeekday = 2 // Monday
        let components = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        let monday = cal.date(from: components)!
        return Int(monday.timeIntervalSince1970)
    }

    var startOfMonth: Int {
        let cal = Calendar(identifier: .iso8601)
        let components = cal.dateComponents([.year, .month], from: self)
        let firstOfMonth = cal.date(from: components)!
        return Int(firstOfMonth.timeIntervalSince1970)
    }
}
