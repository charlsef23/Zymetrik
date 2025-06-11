import SwiftUI

struct Logro: Identifiable {
    let id = UUID()
    var titulo: String
    var descripcion: String
    var icono: String
}

struct PerfilLogrosView: View {
    let logros: [Logro] = [
        Logro(titulo: "Primer entrenamiento", descripcion: "Completaste tu primer día en Zymetrik", icono: "star.fill"),
        Logro(titulo: "5 entrenos", descripcion: "Has registrado 5 entrenamientos", icono: "flame.fill"),
        Logro(titulo: "Semana completa", descripcion: "Entrenaste 7 días seguidos", icono: "calendar.circle.fill")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(logros) { logro in
                HStack(spacing: 12) {
                    Image(systemName: logro.icono)
                        .foregroundColor(.yellow)
                        .frame(width: 32, height: 32)
                        .background(Color.yellow.opacity(0.2))
                        .clipShape(Circle())

                    VStack(alignment: .leading) {
                        Text(logro.titulo)
                            .font(.headline)
                        Text(logro.descripcion)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(.horizontal)
            }
        }
    }
}