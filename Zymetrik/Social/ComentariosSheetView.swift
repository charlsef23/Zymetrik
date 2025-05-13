import SwiftUI

struct ComentarioMock: Identifiable {
    let id = UUID()
    let username: String
    let avatarURL: String?
    let content: String
    let createdAt: Date
    var likes: Int
}

struct ComentariosSheetView: View {
    let comentarios: [ComentarioMock]
    @Binding var isPresented: Bool
    @State private var nuevoComentario: String = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Línea superior
            Capsule()
                .fill(Color.gray.opacity(0.4))
                .frame(width: 40, height: 6)
                .padding(.top, 8)

            Text("Comentarios")
                .font(.headline)
                .padding(.vertical, 12)

            Divider()

            // Lista de comentarios
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(comentarios) { comentario in
                        HStack(alignment: .top, spacing: 12) {
                            avatarView(url: comentario.avatarURL, username: comentario.username)

                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(comentario.username)
                                        .font(.subheadline).bold()
                                    Spacer()
                                    Text(relativeDate(from: comentario.createdAt))
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }

                                Text(comentario.content)
                                    .font(.subheadline)

                                Button("Responder") {}
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }

                            VStack {
                                Button {
                                    // acción futura
                                } label: {
                                    Image(systemName: "heart")
                                }
                                Text("\(comentario.likes)")
                                    .font(.caption)
                            }
                        }
                    }
                }
                .padding()
            }

            Divider()

            // Barra de emojis
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(["❤️", "🙌", "🔥", "👏", "😢", "😍", "😮", "😂"], id: \.self) { emoji in
                        Button {
                            nuevoComentario += emoji
                        } label: {
                            Text(emoji)
                                .font(.title2)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 6)
            }

            // Campo de comentario
            HStack(spacing: 12) {
                avatarView(url: nil, username: "Tú")

                HStack {
                    TextField("¿Qué opinas de esto?", text: $nuevoComentario)
                        .padding(10)

                    Button {
                        // lógica de enviar
                        nuevoComentario = ""
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 26))
                            .foregroundColor(nuevoComentario.isEmpty ? .gray : .blue)
                    }
                    .disabled(nuevoComentario.isEmpty)
                }
                .background(Color(.systemGray6))
                .clipShape(Capsule())
            }
            .padding(.horizontal)
            .padding(.bottom, 12)
        }
        .background(Color.white)
        .cornerRadius(20)
        .ignoresSafeArea(edges: .bottom)
    }

    func avatarView(url: String?, username: String) -> some View {
        Group {
            if let avatar = url, let imageURL = URL(string: avatar) {
                AsyncImage(url: imageURL) { phase in
                    if let image = phase.image {
                        image.resizable()
                    } else {
                        Color.gray
                    }
                }
                .frame(width: 36, height: 36)
                .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.blue)
                    .overlay(Text(String(username.prefix(1))).foregroundColor(.white).bold())
                    .frame(width: 36, height: 36)
            }
        }
    }

    func relativeDate(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "es_ES")
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    ComentariosSheetView(
        comentarios: [
            ComentarioMock(username: "Carlos", avatarURL: nil, content: "¡Increíble entrenamiento!", createdAt: Date().addingTimeInterval(-300), likes: 5),
            ComentarioMock(username: "Ana", avatarURL: nil, content: "🔥🔥🔥", createdAt: Date().addingTimeInterval(-600), likes: 3)
        ],
        isPresented: .constant(true)
    )
}
