import SwiftUI

struct PostEntrenamientoView: View {
    let sesion: SesionEntrenamiento
    let username: String

    @State private var mostrarEstadistica = false
    @State private var pantallaCompleta = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Circle()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.gray.opacity(0.3))
                Text("@\(username)")
                    .fontWeight(.semibold)
                Spacer()
                Text(formatearHora(sesion.fecha))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal)

            // Multimedia o estadística
            ZStack {
                if pantallaCompleta {
                    Color.black.ignoresSafeArea()
                    Text(mostrarEstadistica ? "📊 Estadística del ejercicio" : "🎥 Multimedia")
                        .foregroundColor(.white)
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 250)
                        .onTapGesture {
                            pantallaCompleta = true
                        }
                        .overlay(
                            Text(mostrarEstadistica ? "📊 Estadística del ejercicio" : "🎥 Foto o video")
                                .foregroundColor(.black)
                        )
                }
            }

            // Lista horizontal de ejercicios
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    Button(action: {
                        mostrarEstadistica = false
                    }) {
                        iconCard(icon: "photo.stack", title: "Multimedia")
                    }

                    ForEach(sesion.ejercicios) { ejercicio in
                        Button(action: {
                            mostrarEstadistica = true
                        }) {
                            iconCard(icon: iconoParaTipo(ejercicio.tipo), title: ejercicio.nombre)
                        }
                    }
                }
                .padding(.horizontal)
            }

            // Botones sociales
            HStack(spacing: 20) {
                Button(action: {}) {
                    Circle()
                        .frame(width: 28, height: 28)
                        .overlay(
                            Text("+\(max(0, sesion.ejercicios.count - 3))")
                                .font(.caption)
                        )
                }
                Button(action: {}) {
                    Image(systemName: "heart")
                }
                Button(action: {}) {
                    Image(systemName: "bubble.right")
                }
                Spacer()
                Button(action: {}) {
                    Image(systemName: "bookmark")
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 10)
        }
        .fullScreenCover(isPresented: $pantallaCompleta) {
            VStack {
                HStack {
                    Button("X") {
                        pantallaCompleta = false
                    }
                    .padding()
                    Spacer()
                }
                Spacer()
                Text(mostrarEstadistica ? "📊 Estadística completa" : "🎥 Foto o video")
                    .foregroundColor(.white)
                    .font(.title2)
                Spacer()
            }
            .background(Color.black)
        }
    }

    private func iconCard(icon: String, title: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .resizable()
                .scaledToFit()
                .frame(width: 28, height: 28)
                .foregroundColor(.black.opacity(0.7))
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.black)
                .lineLimit(1)
        }
        .frame(width: 100, height: 80)
        .background(LinearGradient(
            colors: [Color.white, Color.gray.opacity(0.1)],
            startPoint: .top,
            endPoint: .bottom))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    private func iconoParaTipo(_ tipo: TipoEjercicio) -> String {
        switch tipo {
        case .fuerza:
            return "figure.strengthtraining.traditional"
        case .cardio:
            return "figure.run"
        }
    }

    private func formatearHora(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "es_ES")
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}


