import SwiftUI
import StoreKit

struct PaywallViewPro: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var subs: SubscriptionStore

    @State private var monthly: Product?
    @State private var yearly: Product?
    @State private var loading = true
    @State private var errorText: String?

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {

                    // ===== Cabecera / benefits =====
                    VStack(spacing: 12) {
                        Image("LogoSinFondoNegro")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 44, height: 44)
                        Text("Desbloquea Zymetrik PRO").font(.title).bold()
                         Text("Planes personalizados, rutinas semanales y más")
                            .font(.subheadline).foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 8)

                    VStack(alignment: .leading, spacing: 10) {
                        label("Planes por nivel y objetivo")
                        label("Fuerza · Cardio · Híbrido")
                        label("Añade al calendario en 1 toque")
                        label("Mejoras PRO continuas")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // ===== Opciones de compra =====
                    if loading {
                        ProgressView().padding(.vertical, 12)
                    } else {
                        VStack(spacing: 12) {

                            // MENSUAL (recomendado)
                            planRow(
                                title: "Mensual",
                                price: monthly?.displayPrice ?? "2,99 €",
                                highlight: true
                            ) {
                                Task {
                                    if let p = monthly { await subs.purchase(p) }
                                    else { await subs.purchaseMonthly() }
                                }
                            }

                            // ANUAL (ahorro)
                            planRow(
                                title: "Anual (ahorra 16%)",
                                price: yearly?.displayPrice ?? "29,99 €",
                                highlight: false
                            ) {
                                Task {
                                    if let p = yearly { await subs.purchase(p) }
                                    else { await subs.purchaseYearly() }
                                }
                            }

                            if let e = errorText {
                                Text(e).font(.footnote).foregroundStyle(.secondary)
                            }

                            Button("Restaurar compras") { Task { await subs.restorePurchases() } }
                                .buttonStyle(.bordered)
                                .padding(.top, 4)

                            Text("Pago seguro con App Store. Cancela cuando quieras.")
                                .font(.footnote).foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.top, 2)
                        }
                    }
                }
                .padding()
            }
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Cerrar") { dismiss() } } }
            .task { await loadProducts() }
        }
    }

    // MARK: - UI helpers
    private func planRow(title: String, price: String, highlight: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(title).font(.headline)
                        if highlight {
                            Text("Recomendado")
                                .font(.caption2).bold()
                                .padding(.horizontal, 6).padding(.vertical, 3)
                                .background(Capsule().fill(Color.orange.opacity(0.2)))
                        }
                    }
                    Text(price).font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "arrow.right.circle.fill").imageScale(.large)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(highlight ? Color.orange.opacity(0.12) : Color(.secondarySystemBackground))
            )
        }
        .buttonStyle(.plain)
    }

    private func label(_ t: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.seal.fill").foregroundStyle(.green)
            Text(t).font(.subheadline).fontWeight(.semibold)
        }
    }

    // MARK: - Load
    private func loadProducts() async {
        loading = true
        defer { loading = false }

        await subs.loadProducts()
        monthly = subs.product(for: subs.monthlyID)
        yearly  = subs.product(for: subs.yearlyID)

        if monthly == nil && yearly == nil {
            // intento directo por ID (por si el store aún no los tenía cacheados)
            do {
                let prods = try await Product.products(for: [subs.monthlyID, subs.yearlyID])
                for p in prods {
                    if p.id == subs.monthlyID { monthly = p }
                    if p.id == subs.yearlyID  { yearly  = p }
                }
            } catch {
                errorText = "No se pudo cargar los productos (\(error.localizedDescription))"
            }
        }
    }
}
