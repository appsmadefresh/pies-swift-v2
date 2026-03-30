import StoreKit

final class StoreObserver {

    private let eventEmitter: EventEmitter

    init(eventEmitter: EventEmitter) {
        self.eventEmitter = eventEmitter
    }

    func listenForTransactions() async {
        for await result in Transaction.updates {
            guard case .verified(let transaction) = result else { continue }

            #if !DEBUG
            if transaction.environment == .sandbox { continue }
            #endif

            await trackPurchase(transaction)
            await transaction.finish()
        }
    }

    private func trackPurchase(_ transaction: Transaction) async {
        var info: [String: Any] = [
            "productIdentifier": transaction.productID,
            "transactionIdentifier": String(transaction.id),
            "transactionDate": transaction.purchaseDate.timeIntervalSince1970,
            "quantity": transaction.purchasedQuantity,
        ]

        if let product = try? await Product.products(for: [transaction.productID]).first {
            info["localizedTitle"] = product.displayName
            info["price"] = product.displayPrice
            info["currencyCode"] = product.priceFormatStyle.currencyCode

            switch product.type {
            case .autoRenewable:
                info["isSubscription"] = true
                if let sub = product.subscription {
                    info["subscriptionPeriodUnit"] = periodUnitString(sub.subscriptionPeriod.unit)
                    info["subscriptionPeriodValue"] = sub.subscriptionPeriod.value
                }
            default:
                info["isSubscription"] = false
            }
        }

        await eventEmitter.sendEvent(ofType: .inAppPurchase, userInfo: info)
    }

    private func periodUnitString(_ unit: Product.SubscriptionPeriod.Unit) -> String {
        switch unit {
        case .day: "day"
        case .week: "week"
        case .month: "month"
        case .year: "year"
        @unknown default: "unknown"
        }
    }
}
