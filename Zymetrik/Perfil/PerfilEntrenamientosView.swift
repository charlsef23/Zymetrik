import SwiftUI

struct EntrenamientoPost: Identifiable, Hashable {
    let id = UUID()
    var usuario: String
    var fecha: Date
    var titulo: String
    var ejercicios: [String]
}

struct PerfilEntrenamientosView: View {
    // Simulación de posts sincronizados del usuario actual
    let entrenamientos: [EntrenamientoPost] = [
        EntrenamientoPost(usuario: "@Usuario", fecha: Date(), titulo: "Pecho y tríceps", ejercicios: ["Press banca", "Aperturas", "Fondos"]),
        EntrenamientoPost(usuario: "@Usuario", fecha: Date(), titulo: "Pierna completa", ejercicios: ["Sentadilla", "Prensa", "Extensión de cuádriceps"]),
        EntrenamientoPost(usuario: "@Usuario", fecha: Date(), titulo: "Cardio", ejercicios: ["Cinta", "Elíptica"])
    ]

    var body: some View {
        VStack(spacing: 20) {
            ForEach(entrenamientos) { post in
                VStack(alignment: .leading, spacing: 12) {
                    // Header
                    HStack {
                        Circle()
                            .frame(width: 40, height: 40)
                            .foregroundColor(.gray.opacity(0.3))
                        Text(post.usuario)
                            .fontWeight(.semibold)
                        Spacer()
                        Text("Hace 1min") // Temporal
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal)

                    // Media (imagen o estadística dummy)
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 250)
                        .overlay(
                            Text("Ejercicio: \(post.titulo)")
                                .foregroundColor(.black)
                        )

                    // Scroll horizontal multimedia + ejercicios
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            Button(action: {}) {
                                VStack(spacing: 8) {
                                    Image(systemName: "photo.stack")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 28, height: 28)
                                        .foregroundColor(.black.opacity(0.7))
                                    Text("Multimedia")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.black)
                                }
                                .frame(width: 100, height: 80)
                                .background(LinearGradient(
                                    colors: [Color.white, Color.gray.opacity(0.1)],
                                    startPoint: .top,
                                    endPoint: .bottom))
                                .cornerRadius(20)
                                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                            }

                            ForEach(post.ejercicios, id: \.self) { ejercicio in
                                Button(action: {}) {
                                    VStack(spacing: 8) {
                                        Image(systemName: "figure.strengthtraining.traditional")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 28, height: 28)
                                            .foregroundColor(.black.opacity(0.7))
                                        Text(ejercicio)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(.black)
                                    }
                                    .frame(width: 100, height: 80)
                                    .background(LinearGradient(
                                        colors: [Color.white, Color.gray.opacity(0.1)],
                                        startPoint: .top,
                                        endPoint: .bottom))
                                    .cornerRadius(20)
                                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Botones de acción
                    HStack(spacing: 20) {
                        Button(action: {}) {
                            Circle()
                                .frame(width: 28, height: 28)
                                .overlay(
                                    Text("+4")
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
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
                .padding(.horizontal)
            }
        }
    }
}

#Preview {
    PerfilEntrenamientosView()
}
