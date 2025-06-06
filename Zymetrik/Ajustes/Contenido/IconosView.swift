import SwiftUI

struct IconosView: View {
    @State private var selectedStyle: String = "Sistema"
    
    // Simulación del plan actual
    @State private var currentPlan: String = "Gratuito" // Cambia a "Zymetrik Pro" o "Zymetrik Premium"

    let iconosGratis = [
        ("Sistema", "square.grid.2x2.fill"),
        ("Minimalista", "circle.grid.cross")
    ]

    let iconosPro = [
        ("Colorido", "paintpalette.fill"),
        ("Gradientes", "drop.fill")
    ]

    let iconosPremium = [
        ("Lineal premium", "scribble.variable"),
        ("Animado", "sparkles")
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                Text("Estilo de iconos")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)

                // Gratis
                SectionView(title: "Gratis", iconos: iconosGratis, planDisponible: true)

                // Pro
                SectionView(title: "Pro 🟡", iconos: iconosPro, planDisponible: currentPlan == "Zymetrik Pro" || currentPlan == "Zymetrik Premium")

                // Premium
                SectionView(title: "Premium 🔒", iconos: iconosPremium, planDisponible: currentPlan == "Zymetrik Premium")
            }
            .padding()
        }
        .navigationTitle("Iconos")
    }

    // MARK: - Subvista
    @ViewBuilder
    private func SectionView(title: String, iconos: [(String, String)], planDisponible: Bool) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .padding(.horizontal, 4)

            ForEach(iconos, id: \.0) { estilo, icono in
                Button {
                    if planDisponible {
                        selectedStyle = estilo
                    }
                } label: {
                    HStack {
                        Image(systemName: icono)
                            .font(.title2)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(Color.gray.opacity(0.15)))

                        Text(estilo)
                            .font(.body)
                            .foregroundColor(.primary)

                        Spacer()

                        if selectedStyle == estilo && planDisponible {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.blue)
                        } else if !planDisponible {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.gray)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(
                                selectedStyle == estilo && planDisponible
                                ? Color.blue.opacity(0.1)
                                : Color(.systemGray6)
                            )
                    )
                }
                .disabled(!planDisponible)
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

