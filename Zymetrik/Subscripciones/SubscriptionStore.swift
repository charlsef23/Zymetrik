import Foundation
import StoreKit
import SwiftUI

@MainActor
final class SubscriptionStore: ObservableObject {
    static let shared = SubscriptionStore()

    // Estado público para la UI
    @Published private(set) var isPro: Bool = false
    @Published private(set) var currentProductId: String?
    @Published var statusText: String = ""
    @Published var products: [Product] = []

    // Mantener info adicional para sincronizar con backend
    private var lastExpiresAt: Date?
    private var lastOriginalTxId: String?

    // IDs de tus productos (App Store Connect)
    private let productIds = [
        "com.zymetrik.pro.monthly",
        "com.zymetrik.pro.yearly"
    ]

    private init() {}

    // MARK: - Carga de productos

    func loadProducts() async {
        do {
            products = try await Product.products(for: productIds)
        } catch {
            print("❌ Error cargando productos:", error)
        }
    }

    // MARK: - Comprar

    func purchase(_ product: Product) async {
        do {
            // appAccountToken = UUID del usuario (Supabase)
            guard let session = try? await SupabaseManager.shared.client.auth.session,
                  let uid = UUID(uuidString: session.user.id.uuidString) else {
                statusText = "Inicia sesión para suscribirte"
                return
            }

            let result = try await product.purchase(options: [.appAccountToken(uid)])

            switch result {
            case .success(let verification):
                let tx = try checkVerified(verification)
                await tx.finish()
                try await updateFromStoreKit(trigger: "SUBSCRIBED")
                await syncWithBackend(trigger: "SUBSCRIBED")
            case .userCancelled:
                statusText = "Compra cancelada"
            case .pending:
                statusText = "Compra pendiente…"
            @unknown default:
                statusText = "Compra desconocida"
            }
        } catch {
            statusText = "Error en la compra"
            print("❌ Purchase error:", error)
        }
    }

    // MARK: - Restaurar

    func restorePurchases() async {
        do {
            try await AppStore.sync()
            try await updateFromStoreKit(trigger: "RESTORE")
            await syncWithBackend(trigger: "RESTORE")
        } catch {
            statusText = "No se pudo restaurar"
            print("❌ Restore error:", error)
        }
    }

    // MARK: - Refresh (usa en launch y al volver a foreground)

    func refresh() async {
        do {
            try await updateFromStoreKit(trigger: "REFRESH")
            await syncWithBackend(trigger: "REFRESH")
        } catch {
            print("❌ Refresh error:", error)
        }
    }

    // MARK: - StoreKit helpers

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let err): throw err
        case .verified(let signed): return signed
        }
    }

    /// Lee entitlements actuales y actualiza estado local
    private func updateFromStoreKit(trigger: String) async throws {
        var active = false
        var product: String?
        var expires: Date?
        var originalId: String?

        for await result in Transaction.currentEntitlements {
            guard let tx = try? checkVerified(result) else { continue }
            guard tx.productType == .autoRenewable else { continue }

            active = true
            product = tx.productID
            expires = tx.expirationDate
            originalId = String(tx.originalID) // UInt64 -> String
        }

        self.isPro = active
        self.currentProductId = product
        self.lastExpiresAt = expires
        self.lastOriginalTxId = originalId

        self.statusText = active ? "PRO activo" : "No PRO"
    }

    // MARK: - Backend sync (Supabase RPC api_assn_upsert)

    private func snapshot(trigger: String) -> SubscriptionSnapshot {
        SubscriptionSnapshot(
            isPro: isPro,
            productId: currentProductId,
            environment: Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt" ? "Sandbox" : "Production",
            status: isPro ? "active" : "expired",
            willRenew: nil,                           // puedes calcularlo con RenewalInfo si quieres
            originalTransactionId: lastOriginalTxId,  // opcional
            expiresAt: lastExpiresAt,                 // opcional
            lastEvent: trigger
        )
    }

    private func syncWithBackend(trigger: String) async {
        do {
            try await SupabaseSubscriptionService.shared.upsert(snapshot: snapshot(trigger: trigger))
        } catch {
            print("ℹ️ No se pudo sincronizar con backend:", error)
        }
    }
}
