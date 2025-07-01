import SwiftUI

struct PostView: View {
    let postID: UUID
    @State private var post: EntrenamientoPost?
    @State private var ejercicioSeleccionado: EjercicioPost?
    @State private var cargando = true
    @State private var leDioLike = false
    @State private var guardado = false

    var body: some View {
        Group {
            if let post = post, let ejercicio = ejercicioSeleccionado {
                VStack(alignment: .leading, spacing: 16) {

                    // Header con navegación a perfil
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

                    // Cuadro grande con estadísticas
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(UIColor.systemGray6))
                        .frame(height: 160)
                        .overlay(
                            VStack(spacing: 12) {
                                Text(ejercicio.nombre)
                                    .font(.title3.bold())
                                HStack(spacing: 24) {
                                    statView(title: "Series", value: "\(ejercicio.series)")
                                    statView(title: "Reps", value: "\(ejercicio.repeticiones)")
                                    statView(title: "Kg", value: String(format: "%.1f", ejercicio.peso_total))
                                }
                            }
                        )

                    // Carrusel ejercicios
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(post.ejercicios) { ejercicioItem in
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
                                        ejercicioItem.id == ejercicio.id ?
                                            Color(UIColor.systemGray5) : Color.white
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

                    // Acciones estilo Instagram
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 20) {
                            Button {
                                leDioLike.toggle()
                            } label: {
                                Image(systemName: leDioLike ? "heart.fill" : "heart")
                                    .foregroundColor(leDioLike ? .red : .primary)
                            }

                            Button {
                                print("Abrir comentarios")
                            } label: {
                                Image(systemName: "bubble.right")
                            }

                            Button {
                                print("Compartir")
                            } label: {
                                Image(systemName: "square.and.arrow.up")
                            }

                            Spacer()

                            Button {
                                guardado.toggle()
                            } label: {
                                Image(systemName: guardado ? "bookmark.fill" : "bookmark")
                            }
                        }
                        .font(.title3)

                        Text("\(leDioLike ? 1 : 0) me gusta")
                            .font(.subheadline.bold())

                        Button("Ver todos los comentarios") {
                            // Abrir sección de comentarios
                        }
                        .font(.footnote)
                        .foregroundColor(.gray)
                    }

                }
                .padding()
                .background(Color.white)
                .cornerRadius(20)
                .shadow(radius: 2)
                .padding(.horizontal)
            } else if cargando {
                ProgressView()
            } else {
                Text("Error al cargar post")
            }
        }
        .task {
            do {
                let resultado = try await SupabaseService.shared.fetchEntrenamientoPost(id: postID)
                self.post = resultado
                self.ejercicioSeleccionado = resultado.ejercicios.first
                self.cargando = false
            } catch {
                print("Error al cargar post \(postID): \(error)")
                self.cargando = false
            }
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
}
