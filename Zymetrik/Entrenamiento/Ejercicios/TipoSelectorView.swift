import SwiftUI

struct TipoSelectorView: View {
    let tipos: [String]
    @Binding var tipoSeleccionado: String
    var tipoAnimacion: Namespace.ID

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(tipos, id: \.self) { tipo in
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            tipoSeleccionado = tipo
                        }
                    }) {
                        ZStack {
                            if tipoSeleccionado == tipo {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(gradient(for: tipo))
                                    .matchedGeometryEffect(id: "selector", in: tipoAnimacion)
                                    .frame(height: 38)
                            } else {
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                                    .background(Color(.systemGray6).cornerRadius(20))
                                    .frame(height: 38)
                            }

                            Text(tipo)
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(tipoSeleccionado == tipo ? .white : .black)
                                .padding(.horizontal, 20)
                                .frame(height: 38)
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    func gradient(for tipo: String) -> LinearGradient {
        switch tipo {
        case "Fuerza":
            return LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "Favoritos":
            return LinearGradient(colors: [.yellow, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
        default:
            return LinearGradient(colors: [.gray, .gray.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}
