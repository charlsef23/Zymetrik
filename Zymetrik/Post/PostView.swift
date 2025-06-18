import SwiftUI

struct PostView: View {
    let postID: UUID
    @State private var post: EntrenamientoPost?
    @State private var ejercicioSeleccionado: EjercicioPost?
    @State private var cargando = true

    var body: some View {
        Group {
            if let post = post, let ejercicio = ejercicioSeleccionado {
                VStack(alignment: .leading, spacing: 16) {

                    // Header
                    HStack {
                        Image(systemName: "person.crop.circle")
                            .resizable()
                            .frame(width: 36, height: 36)
                        Text("@\(post.username)")
                            .fontWeight(.semibold)
                        Spacer()
                        Text(post.fecha.timeAgoDisplay())
                            .font(.caption)
                            .foregroundColor(.gray)
                    }

                    // Cuadro grande
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(UIColor.systemGray6))
                        .frame(height: 160)
                        .overlay(
                            VStack(spacing: 12) {
                                Text(ejercicio.nombre)
                                    .font(.title3.bold())
                                HStack(spacing: 24) {
                                    VStack {
                                        Text("\(ejercicio.series)")
                                            .font(.title3.bold())
                                        Text("Series").font(.caption)
                                    }
                                    VStack {
                                        Text("\(ejercicio.repeticiones)")
                                            .font(.title3.bold())
                                        Text("Reps").font(.caption)
                                    }
                                    VStack {
                                        Text(String(format: "%.1f", ejercicio.peso_total))
                                            .font(.title3.bold())
                                        Text("Kg").font(.caption)
                                    }
                                }
                            }
                        )

                    // Carrusel
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

                    // Acciones
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 16) {
                            Image(systemName: "heart")
                            Image(systemName: "bubble.right")
                            Image(systemName: "square.and.arrow.up")
                            Spacer()
                            Image(systemName: "bookmark")
                        }
                        .font(.title3)

                        Text("0 me gusta")
                            .font(.subheadline.bold())

                        Button("Ver todos los comentarios") {}
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
}
