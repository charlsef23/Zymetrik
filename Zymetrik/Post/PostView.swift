import SwiftUI

struct PostView: View {
    let post: EntrenamientoPost

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 40)
                    .overlay(Text("👤"))
                Text(post.usuario)
                    .fontWeight(.semibold)
                Spacer()
                Text(formatTime(post.fecha))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal)

            // Imagen o estadística
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
                    // Multimedia placeholder
                    Button {
                        // Acción multimedia
                    } label: {
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
                        .background(LinearGradient(colors: [.white, .gray.opacity(0.1)], startPoint: .top, endPoint: .bottom))
                        .cornerRadius(20)
                        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                    }

                    // Ejercicios
                    ForEach(post.ejercicios, id: \.self) { ejercicio in
                        Button {
                            // Acción al pulsar ejercicio
                        } label: {
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
                            .background(LinearGradient(colors: [.white, .gray.opacity(0.1)], startPoint: .top, endPoint: .bottom))
                            .cornerRadius(20)
                            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                        }
                    }
                }
                .padding(.horizontal)
            }

            // Botones sociales
            HStack(spacing: 20) {
                Button {
                    // Acción +X
                } label: {
                    Circle()
                        .frame(width: 28, height: 28)
                        .overlay(
                            Text("+4")
                                .font(.caption)
                        )
                }

                Button { } label: {
                    Image(systemName: "heart")
                }

                Button { } label: {
                    Image(systemName: "bubble.right")
                }

                Spacer()

                Button { } label: {
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

    func formatTime(_ date: Date) -> String {
        // Para ahora solo retorna "Hace 1min"
        return "Hace 1min"
    }
}

#Preview {
    PostView(post: EntrenamientoPost(
        usuario: "@carlos",
        fecha: Date(),
        titulo: "Espalda fuerte",
        ejercicios: ["Dominadas", "Remo con barra", "Jalón al pecho"]
    ))
}
