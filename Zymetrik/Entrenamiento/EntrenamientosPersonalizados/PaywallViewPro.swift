import SwiftUI
import StoreKit

struct PaywallViewPro: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var subs: SubscriptionStore

    @State private var monthly: Product?
    @State private var loading = true
    @State private var errorText: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 42))
                    .symbolRenderingMode(.hierarchical)
                    .padding(14)
                    .background(Circle().fill(Color.yellow.opacity(0.25)))

                Text("Desbloquea Zymetrik PRO")
                    .font(.title3).bold()

                VStack(alignment: .leading, spacing: 10) {
                    label("Planes personalizados por nivel y objetivo")
                    label("Rutinas semanales (fuerza · cardio · híbrido)")
                    label("Añadir al calendario en 1 toque")
                    label("Mejoras PRO continuas")
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if loading {
                    ProgressView().padding(.top, 8)
                } else if let p = monthly {
                    Button {
                        Task { await subs.purchase(p) }
                    } label: {
                        Text("Continuar por \(p.displayPrice)/mes")
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                } else {
                    Text(errorText ?? "No se pudo cargar el precio")
                        .foregroundStyle(.secondary)
                }

                Button("Restaurar compras") {
                    Task { await subs.restorePurchases() }
                }
                .buttonStyle(.bordered)

                Text("Cancela cuando quieras. Los pagos y la gestión se realizan con App Store.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 6)

                Spacer()
            }
            .padding()
            .navigationTitle("Zymetrik PRO")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cerrar") { dismiss() }
                }
            }
            .task {
                await loadMonthly()
            }
        }
    }

    private func loadMonthly() async {
        loading = true
        defer { loading = false }
        await subs.loadProducts()
        if let prod = subs.products.first(where: { $0.id.contains(".monthly") }) {
            self.monthly = prod
        } else {
            self.errorText = "Producto mensual no disponible"
        }
    }

    private func label(_ t: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.seal.fill")
            Text(t).font(.subheadline)
        }
    }
}
