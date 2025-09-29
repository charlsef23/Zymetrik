import SwiftUI

struct TipoChipsBar: View {
    let tipos: [String]
    @Binding var seleccionado: String
    var namespace: Namespace.ID

    func icon(for tipo: String) -> String {
        switch tipo {
        case "Fuerza": return "figure.strengthtraining.traditional"
        case "Favoritos": return "star.fill"
        default: return "circle"
        }
    }

    func color(for tipo: String) -> Color {
        if tipo == "Favoritos" {
            return .yellow   // 🎨 chip de Favoritos en amarillo
        }
        return .accentColor
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(tipos, id: \.self) { tipo in
                    let isOn = seleccionado == tipo
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                            seleccionado = tipo
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: icon(for: tipo))
                                .font(.subheadline.weight(.semibold))
                            Text(tipo)
                                .font(.subheadline.weight(.semibold))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            ZStack {
                                if isOn {
                                    RoundedRectangle(cornerRadius: 22)
                                        .fill(color(for: tipo))
                                        .matchedGeometryEffect(id: "tipo-bg-\(tipo)", in: namespace)
                                } else {
                                    RoundedRectangle(cornerRadius: 22)
                                        .stroke(Color.gray.opacity(0.35), lineWidth: 1)
                                        .background(Color(.systemGray6).cornerRadius(22))
                                }
                            }
                        )
                        .foregroundColor(isOn
                                         ? (tipo == "Favoritos" ? .black : .white) // texto negro en amarillo
                                         : .primary)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}
