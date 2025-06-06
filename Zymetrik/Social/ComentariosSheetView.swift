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

    var body: some View {
        VStack(spacing: 0) {
            let topBar = Capsule()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 5)
                .padding(.top, 8)

            let title = Text("Comentarios")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.vertical, 12)

            let divider = Divider()

            let comentariosList = ScrollViewReader { proxy in
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

                                    Button("Responder") {}
                                        .font(.caption)
                                        .foregroundColor(.black)
                                }

                                VStack(spacing: 6) {
                                    Button {
                                        // Acción futura
                                    } label: {
                                        Image(systemName: "heart")
                                            .foregroundColor(.black)
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
                .onChange(of: comentariosInternos) { _, nuevosComentarios in
                    withAnimation {
                        if let ultimo = nuevosComentarios.last {
                            proxy.scrollTo(ultimo.id, anchor: .bottom)
                        }
                    }
                }
            }

            let inputField = HStack {
                TextField("Comentario...", text: $nuevoComentario)
                    .padding(10)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .focused($campoEnfocado)

                Button {
                    let nuevo = ComentarioMock(
                        username: "Tú",
                        avatarURL: nil,
                        content: nuevoComentario,
                        createdAt: Date(),
                        likes: 0
                    )
                    comentariosInternos.append(nuevo)
                    nuevoComentario = ""
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

            topBar
            title
            divider
            comentariosList
            inputField
        }
        .onAppear {
            comentariosInternos = comentarios
        }
        .background(Color.white)
        .cornerRadius(20)
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
