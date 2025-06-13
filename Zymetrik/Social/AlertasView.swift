import SwiftUI

struct Alerta: Identifiable {
    let id = UUID()
    let tipo: TipoAlerta
    let usuario: String
    let mensaje: String
    let hora: String

    var fotoPerfilURL: String {
        "https://api.dicebear.com/7.x/initials/svg?seed=\(usuario)"
    }
}

enum TipoAlerta: String, CaseIterable {
    case solicitud, meGusta, comentario

    var icono: String {
        switch self {
        case .solicitud: return "person.crop.circle.badge.plus"
        case .meGusta: return "heart.fill"
        case .comentario: return "text.bubble.fill"
        }
    }

    var color: Color {
        switch self {
        case .solicitud: return .blue
        case .meGusta: return .red
        case .comentario: return .orange
        }
    }

    var titulo: String {
        switch self {
        case .solicitud: return "Solicitudes"
        case .meGusta: return "Me gustas"
        case .comentario: return "Comentarios"
        }
    }
}

struct AlertasView: View {
    @State private var alertas: [Alerta] = [
        Alerta(tipo: .solicitud, usuario: "luciafit", mensaje: "quiere seguirte", hora: "Hace 2 min"),
        Alerta(tipo: .meGusta, usuario: "alejandroGym", mensaje: "le dio me gusta a tu entrenamiento", hora: "Hace 10 min"),
        Alerta(tipo: .comentario, usuario: "marta.run", mensaje: "comentó: “brutal sesión 🔥”", hora: "Hace 20 min"),
        Alerta(tipo: .meGusta, usuario: "sara.power", mensaje: "le dio me gusta a tu foto", hora: "Hace 3 h")
    ]

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                ForEach(TipoAlerta.allCases, id: \.self) { tipo in
                    let alertasTipo = alertas.filter { $0.tipo == tipo }
                    if !alertasTipo.isEmpty {
                        Text(tipo.titulo)
                            .font(.headline)
                            .padding(.horizontal)

                        ForEach(alertasTipo) { alerta in
                            alertaRow(alerta)
                        }
                    }
                }
            }
            .padding(.top)
        }
        .navigationTitle("Alertas")
    }

    private func alertaRow(_ alerta: Alerta) -> some View {
        HStack(alignment: .top, spacing: 12) {
            AsyncImage(url: URL(string: alerta.fotoPerfilURL)) { image in
                image.resizable()
            } placeholder: {
                Circle().fill(Color.gray.opacity(0.3))
            }
            .frame(width: 48, height: 48)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: alerta.tipo.icono)
                        .foregroundColor(alerta.tipo.color)
                        .font(.subheadline)

                    Text("@\(alerta.usuario) \(alerta.mensaje)")
                        .font(.body)
                        .lineLimit(2)
                }

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
                .background(Color.blue)
                .foregroundColor(.white)
                .clipShape(Capsule())
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}
