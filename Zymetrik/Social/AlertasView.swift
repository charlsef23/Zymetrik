import SwiftUI

struct Alerta: Identifiable {
    let id = UUID()
    let tipo: TipoAlerta
    let usuario: String
    let mensaje: String
    let hora: String
}

enum TipoAlerta {
    case solicitud, meGusta, comentario, compartido

    var icono: String {
        switch self {
        case .solicitud: return "person.crop.circle.badge.plus"
        case .meGusta: return "hand.thumbsup.fill"
        case .comentario: return "text.bubble.fill"
        case .compartido: return "arrowshape.turn.up.right.fill"
        }
    }

    var color: Color {
        switch self {
        case .solicitud: return .blue
        case .meGusta: return .green
        case .comentario: return .orange
        case .compartido: return .purple
        }
    }
}

struct AlertasView: View {
    // Ejemplo de notificaciones (luego se conectará a Supabase)
    @State private var alertas: [Alerta] = [
        Alerta(tipo: .solicitud, usuario: "luciafit", mensaje: "quiere seguirte", hora: "Hace 2 min"),
        Alerta(tipo: .meGusta, usuario: "alejandroGym", mensaje: "le dio fuerza a tu entrenamiento", hora: "Hace 10 min"),
        Alerta(tipo: .comentario, usuario: "marta.run", mensaje: "comentó: “brutal sesión 🔥”", hora: "Hace 20 min"),
        Alerta(tipo: .compartido, usuario: "davidpro", mensaje: "compartió tu entrenamiento", hora: "Hace 1 h")
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(alertas) { alerta in
                    alertaRow(alerta)
                    Divider()
                        .padding(.leading, 60)
                }
            }
        }
        .navigationTitle("Alertas")
    }

    @ViewBuilder
    private func alertaRow(_ alerta: Alerta) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(alerta.tipo.color.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: alerta.tipo.icono)
                        .foregroundColor(alerta.tipo.color)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text("@\(alerta.usuario) \(alerta.mensaje)")
                    .font(.body)
                Text(alerta.hora)
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()

            if alerta.tipo == .solicitud {
                Button("Aceptar") {
                    // Acción para aceptar solicitud
                }
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.blue)
                .foregroundColor(.white)
                .clipShape(Capsule())
            }
        }
        .padding()
    }
}
