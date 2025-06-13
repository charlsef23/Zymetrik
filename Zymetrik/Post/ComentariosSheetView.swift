import SwiftUI

struct ComentarioMock: Identifiable, Equatable {
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
    @FocusState private var campoEnfocado: Bool

    @State private var comentariosInternos: [ComentarioMock] = []
    @State private var likedComentarios: Set<UUID> = []
    @State private var respuestaA: ComentarioMock?

    var body: some View {
        VStack(spacing: 0) {
            // Top bar
            Capsule()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 5)
                .padding(.top, 8)

            Text("Comentarios")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.vertical, 12)

            Divider()

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 20) {
                        ForEach(comentariosInternos) { comentario in
                            HStack(alignment: .top, spacing: 12) {
                                avatarView(url: comentario.avatarURL, username: comentario.username)

                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text(comentario.username)
                                            .font(.subheadline).bold()
                                        Spacer()
                                        Text(relativeDate(from: comentario.createdAt))
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }

                                    Text(comentario.content)
                                        .font(.body)
                                        .foregroundColor(.primary)

                                    Button("Responder") {
                                        respuestaA = comentario
                                        campoEnfocado = true
                                    }
                                    .font(.caption)
                                    .foregroundColor(.black)
                                }

                                VStack(spacing: 6) {
                                    Button {
                                        toggleLike(for: comentario)
                                    } label: {
                                        Image(systemName: likedComentarios.contains(comentario.id) ? "heart.fill" : "heart")
                                            .foregroundColor(likedComentarios.contains(comentario.id) ? .red : .black)
                                    }

                                    Text("\(comentario.likes)")
                                        .font(.caption2)
                                        .foregroundColor(.black)
                                }
                            }
                            .padding(.horizontal)
                            .id(comentario.id)
                        }
                    }
                    .padding(.top, 4)
                }
                .onChange(of: comentariosInternos) { _, nuevos in
                    withAnimation {
                        if let ultimo = nuevos.last {
                            proxy.scrollTo(ultimo.id, anchor: .bottom)
                        }
                    }
                }
            }

            HStack {
                TextField(respuestaA != nil ? "Responder a @\(respuestaA!.username)..." : "Comentario...", text: $nuevoComentario)
                    .padding(10)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .focused($campoEnfocado)

                Button {
                    let contenidoFinal = respuestaA != nil ? "@\(respuestaA!.username) \(nuevoComentario)" : nuevoComentario
                    let nuevo = ComentarioMock(
                        username: "Tú",
                        avatarURL: nil,
                        content: contenidoFinal,
                        createdAt: Date(),
                        likes: 0
                    )
                    comentariosInternos.append(nuevo)
                    nuevoComentario = ""
                    respuestaA = nil
                    campoEnfocado = false
                } label: {
                    Image(systemName: "paperplane.fill")
                        .rotationEffect(.degrees(45))
                        .font(.title3)
                        .padding(10)
                        .background(Color.black)
                        .foregroundColor(.white)
                        .clipShape(Circle())
                }
                .disabled(nuevoComentario.isEmpty)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(Color.white)
        }
        .onAppear {
            comentariosInternos = comentarios
        }
        .background(Color.white)
        .cornerRadius(20)
    }

    func toggleLike(for comentario: ComentarioMock) {
        guard let index = comentariosInternos.firstIndex(where: { $0.id == comentario.id }) else { return }
        if likedComentarios.contains(comentario.id) {
            likedComentarios.remove(comentario.id)
            comentariosInternos[index].likes -= 1
        } else {
            likedComentarios.insert(comentario.id)
            comentariosInternos[index].likes += 1
        }
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
                    .fill(Color.black)
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
