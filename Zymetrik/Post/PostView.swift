import SwiftUI

struct PostView: View {
    let post: Post
    @State private var ejercicioSeleccionado: EjercicioPostContenido?
    @State private var leDioLike = false
    @State private var numLikes = 0
    @State private var guardado = false
    @State private var mostrarComentarios = false

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header
            HStack {
                Image(systemName: "person.crop.circle")
                    .resizable()
                    .frame(width: 36, height: 36)

                NavigationLink(destination: UserProfileView(username: post.username)) {
                    Text("@\(post.username)")
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }

                Spacer()
                Text(post.fecha.timeAgoDisplay())
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            // Estadísticas del ejercicio seleccionado
            if let ejercicio = ejercicioSeleccionado {
                RoundedRectangle(cornerRadius: 0)
                    .fill(Color(UIColor.systemGray6))
                    .frame(height: 180)
                    .overlay(
                        VStack(spacing: 16) {
                            Text(ejercicio.nombre)
                                .font(.title2.bold())
                            HStack(spacing: 32) {
                                statView(title: "Series", value: "\(ejercicio.totalSeries)")
                                statView(title: "Reps", value: "\(ejercicio.totalRepeticiones)")
                                statView(title: "Kg", value: String(format: "%.1f", ejercicio.totalPeso))
                            }
                        }
                    )
            }

            // Carrusel de ejercicios
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(post.contenido) { ejercicioItem in
                        Button {
                            withAnimation {
                                ejercicioSeleccionado = ejercicioItem
                            }
                        } label: {
                            VStack {
                                Image(systemName: "figure.strengthtraining.traditional")
                                    .font(.title2)
                                Text(ejercicioItem.nombre)
                                    .font(.caption)
                                    .lineLimit(1)
                            }
                            .padding()
                            .background(
                                ejercicioSeleccionado?.id == ejercicioItem.id ? Color(UIColor.systemGray5) : Color.white
                            )
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.3))
                            )
                        }
                    }
                }
                .padding(.horizontal)
            }

            postActions
        }
        .padding()
        .onAppear {
            ejercicioSeleccionado = post.contenido.first
            Task {
                await comprobarSiLeDioLike()
                await cargarNumeroDeLikes()
            }
        }
        .sheet(isPresented: $mostrarComentarios) {
            ComentariosView(postID: post.id)
        }
    }

    private var postActions: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 20) {
                Button { Task { await toggleLike() } } label: {
                    Image(systemName: leDioLike ? "heart.fill" : "heart")
                        .foregroundColor(leDioLike ? .red : .primary)
                }

                Button { mostrarComentarios = true } label: {
                    Image(systemName: "bubble.right")
                }

                Spacer()

                Button {
                    guardado.toggle()
                } label: {
                    Image(systemName: guardado ? "bookmark.fill" : "bookmark")
                }
            }
            .font(.title3)

            Text("\(numLikes) me gusta")
                .font(.subheadline.bold())
        }
    }

    func statView(title: String, value: String) -> some View {
        VStack {
            Text(value)
                .font(.title3.bold())
            Text(title)
                .font(.caption)
        }
    }

    private func comprobarSiLeDioLike() async {
        // Igual que antes
    }

    private func toggleLike() async {
        // Igual que antes
    }

    private func cargarNumeroDeLikes() async {
        // Igual que antes
    }
}
