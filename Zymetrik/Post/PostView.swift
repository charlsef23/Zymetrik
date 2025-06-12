import SwiftUI

struct PostView: View {
    let post: EntrenamientoPost
    @State private var isLiked = false
    @State private var likeCount = 4
    @State private var showComentarios = false
    @State private var isSaved = false
    @State private var comentarios: [String] = [
        "¡Muy buen entrenamiento!",
        "¿Cuántas repes hiciste?",
        "Inspirador 💪",
        "Voy a probar esta rutina",
        "🔥🔥🔥"
    ]

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
                        .background(.ultraThinMaterial)
                        .cornerRadius(20)
                        .shadow(radius: 2)
                    }

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
                            .background(.ultraThinMaterial)
                            .cornerRadius(20)
                            .shadow(radius: 2)
                        }
                    }
                }
                .padding(.horizontal)
            }

            // Botones sociales
            HStack(spacing: 16) {
                Button {
                    isLiked.toggle()
                    likeCount += isLiked ? 1 : -1
                } label: {
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                        .foregroundColor(isLiked ? .red : .primary)
                        .font(.system(size: 20))
                }

                Button {
                    showComentarios = true
                } label: {
                    Image(systemName: "bubble.right")
                        .font(.system(size: 20))
                }

                Spacer()

                Button {
                    isSaved.toggle()
                } label: {
                    Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 20))
                }
            }
            .padding(.horizontal)

            // Contador de me gusta
            if likeCount > 0 {
                Text("\(likeCount) me gusta")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .padding(.horizontal)
            }

            // Comentarios
            if !comentarios.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(comentarios.prefix(3), id: \.self) { comentario in
                        Text(comentario)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }

                    if comentarios.count > 3 {
                        Button("Ver todos los comentarios") {
                            showComentarios = true
                        }
                        .font(.caption)
                        .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal)
            }

            // Espacio final
            Spacer(minLength: 4)
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
        .padding(.horizontal)
        .sheet(isPresented: $showComentarios) {
            ComentariosView(post: post)
        }
    }

    func formatTime(_ date: Date) -> String {
        return "Hace 1min"
    }
}

