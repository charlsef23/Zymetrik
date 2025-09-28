import Foundation
import StoreKit
import Supabase

@MainActor
final class SubscriptionStore: ObservableObject {
    static let shared = SubscriptionStore()

    // ✅ IDs EXACTOS (App Store Connect)
    let monthlyID = "ZymetrikPro"
    let yearlyID  = "ZymetrikProYear"

    // Estado público para la UI
    @Published private(set) var isPro: Bool = false
    @Published private(set) var currentProductId: String?
    @Published var products: [Product] = []
    @Published var statusText: String = ""

    // Cache para sincronía backend
    private var lastExpiresAt: Date?
    private var lastOriginalTxId: String?

    // Escucha de updates
    private var updatesTask: Task<Void, Never>?

    private init() {
        // 🔊 Empieza a escuchar actualizaciones de transacciones (recomendación StoreKit 2)
        updatesTask = Task { await listenForTransactions() }
    }

    deinit {
        updatesTask?.cancel()
    }

    // MARK: - Productos
    func loadProducts() async {
        do {
            let ids = [monthlyID, yearlyID]
            let fetched = try await Product.products(for: ids)
            // Ordena mensual primero
            self.products = fetched.sorted { a, b in
                (a.id == monthlyID ? 0 : 1) < (b.id == monthlyID ? 0 : 1)
            }
        } catch {
            print("❌ loadProducts:", error)
            self.products = []
        }
    }

    func product(for id: String) -> Product? {
        products.first(where: { $0.id == id })
    }

    // MARK: - Comprar
    func purchase(_ product: Product) async {
        do {
            // Vincula la compra a tu usuario (Supabase) con appAccountToken
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
            print("❌ purchase error:", error)
        }
    }

    func purchaseMonthly() async {
        if let p = product(for: monthlyID) {
            await purchase(p)
        } else {
            do {
                if let p = try await Product.products(for: [monthlyID]).first {
                    await purchase(p)
                }
            } catch { print("❌ purchaseMonthly fallback:", error) }
        }
    }

    func purchaseYearly() async {
        if let p = product(for: yearlyID) {
            await purchase(p)
        } else {
            do {
                if let p = try await Product.products(for: [yearlyID]).first {
                    await purchase(p)
                }
            } catch { print("❌ purchaseYearly fallback:", error) }
        }
    }

    // MARK: - Restaurar / Refresh
    func restorePurchases() async {
        do {
            try await AppStore.sync()
            try await updateFromStoreKit(trigger: "RESTORE")
            await syncWithBackend(trigger: "RESTORE")
        } catch {
            statusText = "No se pudo restaurar"
            print("❌ restore:", error)
        }
    }

    func refresh() async {
        do {
            try await updateFromStoreKit(trigger: "REFRESH")
            await syncWithBackend(trigger: "REFRESH")
        } catch {
            print("❌ refresh:", error)
        }
    }

    // MARK: - StoreKit helpers
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let err): throw err
        case .verified(let signed):   return signed
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

    /// Mantén un stream de updates para no perder compras
    private func listenForTransactions() async {
        for await result in Transaction.updates {
            do {
                let tx = try checkVerified(result)
                await tx.finish()
                try await updateFromStoreKit(trigger: "UPDATE_STREAM")
                await syncWithBackend(trigger: "UPDATE_STREAM")
            } catch {
                print("❌ Transaction.updates:", error)
            }
        }
    }

    // MARK: - Backend (Supabase)
    private func snapshot(trigger: String) -> SubscriptionSnapshot {
        SubscriptionSnapshot(
            isPro: isPro,
            productId: currentProductId,
            environment: (Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt") ? "Sandbox" : "Production",
            status: isPro ? "active" : "expired",
            willRenew: nil,                    // puedes calcularlo con RenewalInfo si lo necesitas
            originalTransactionId: lastOriginalTxId,
            expiresAt: lastExpiresAt,
            lastEvent: trigger
        )
    }

    private func syncWithBackend(trigger: String) async {
        do {
            try await SupabaseSubscriptionService.shared.upsert(snapshot: snapshot(trigger: trigger))
        } catch {
            print("ℹ️ backend sync:", error)
        }
    }
}
