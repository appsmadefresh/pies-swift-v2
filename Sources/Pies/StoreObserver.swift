import StoreKit
import os

final class StoreObserver {

    private let eventEmitter: EventEmitter
    private let logger = PiesLogger.shared

    init(eventEmitter: EventEmitter) {
        self.eventEmitter = eventEmitter
    }

    /// Listen for StoreKit 2 verified transactions.
    func listenForTransactions() async {
        for await result in Transaction.updates {
            guard case .verified(let transaction) = result else { continue }

            // Skip sandbox transactions in production builds.
            #if !DEBUG
            if transaction.environment == .sandbox { continue }
            #endif

            await trackPurchase(transaction)
        }
    }

    private func trackPurchase(_ transaction: Transaction) async {
        var info: [String: Any] = [
            "productIdentifier": transaction.productID,
            "transactionIdentifier": String(transaction.id),
            "transactionDate": transaction.purchaseDate.timeIntervalSince1970,
            "quantity": transaction.purchasedQuantity,
        ]

        // Fetch product details for price info.
        if let product = try? await Product.products(for: [transaction.productID]).first {
            info["localizedTitle"] = product.displayName
            info["price"] = product.displayPrice
            info["currencyCode"] = product.priceFormatStyle.currencyCode

            switch product.type {
            case .autoRenewable:
                info["isSubscription"] = true
                if let sub = product.subscription {
                    info["subscriptionPeriodUnit"] = String(describing: sub.subscriptionPeriod.unit)
                    info["subscriptionPeriodValue"] = sub.subscriptionPeriod.value
                }
            default:
                info["isSubscription"] = false
            }
        }

        await eventEmitter.sendEvent(ofType: .inAppPurchase, userInfo: info)
    }
}
