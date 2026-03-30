public enum EventType: String, Sendable {
    case newInstall
    case sessionStart
    case sessionEnd
    case inAppPurchase
    case deviceActiveToday
    case deviceActiveThisWeek
    case deviceActiveThisMonth
}
