import SwiftUI
import Supabase

struct PostView: View {
    let postID: UUID
    @State private var post: EntrenamientoPost?
    @State private var ejercicioSeleccionado: EjercicioPost?
    @State private var cargando = true
    @State private var leDioLike = false
    @State private var numLikes = 0
    @State private var guardado = false
    @State private var mostrarComentarios = false

    var body: some View {
        Group {
            if let post = post, let ejercicio = ejercicioSeleccionado {
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

                    // Estadísticas del ejercicio
                    RoundedRectangle(cornerRadius: 0)
                        .fill(Color(UIColor.systemGray6))
                        .frame(height: 180)
                        .overlay(
                            VStack(spacing: 16) {
                                Text(ejercicio.nombre)
                                    .font(.title2.bold())
                                HStack(spacing: 32) {
                                    statView(title: "Series", value: "\(ejercicio.series)")
                                    statView(title: "Reps", value: "\(ejercicio.repeticiones)")
                                    statView(title: "Kg", value: String(format: "%.1f", ejercicio.peso_total))
                                }
                            }
                        )

                    // Carrusel ejercicios
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
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

                    // Botones
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 20) {
                            Button {
                                Task { await toggleLike() }
                            } label: {
                                Image(systemName: leDioLike ? "heart.fill" : "heart")
                                    .foregroundColor(leDioLike ? .red : .primary)
                            }

                            Button {
                                mostrarComentarios = true
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

                        Text("\(numLikes) me gusta")
                            .font(.subheadline.bold())

                        Button("Ver todos los comentarios") {
                            mostrarComentarios = true
                        }
                        .font(.footnote)
                        .foregroundColor(.gray)
                    }

                    Spacer(minLength: 30)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .background(Color.white)
                .sheet(isPresented: $mostrarComentarios) {
                    ComentariosView(postID: postID)
                }
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
                await comprobarSiLeDioLike()
                await cargarNumeroDeLikes()
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

    func comprobarSiLeDioLike() async {
        do {
            let session = try await SupabaseManager.shared.client.auth.session
            let userId = session.user.id

            let response = try await SupabaseManager.shared.client
                .from("post_likes")
                .select("*")
                .eq("post_id", value: postID.uuidString)
                .eq("profile_id", value: userId.uuidString)
                .execute()

            let likes = try response.decodedList(to: PostLike.self)
            self.leDioLike = !likes.isEmpty
        } catch {
            print("❌ Error comprobando like: \(error.localizedDescription)")
            self.leDioLike = false
        }
    }

    func toggleLike() async {
        do {
            let session = try await SupabaseManager.shared.client.auth.session
            let userId = session.user.id

            if leDioLike {
                // ❌ Eliminar el like si existe
                _ = try await SupabaseManager.shared.client
                    .from("post_likes")
                    .delete()
                    .eq("post_id", value: postID.uuidString)
                    .eq("profile_id", value: userId.uuidString)
                    .execute()

                leDioLike = false
            } else {
                // ✅ Intentar insertar solo si no existe
                let nuevoLike = NuevoLike(post_id: postID, profile_id: userId)

                do {
                    _ = try await SupabaseManager.shared.client
                        .from("post_likes")
                        .insert(nuevoLike, returning: .minimal)
                        .execute()

                    leDioLike = true
                } catch {
                    print("⚠️ No se pudo insertar like (probablemente ya existe): \(error.localizedDescription)")
                }
            }

            await cargarNumeroDeLikes()

        } catch {
            print("❌ Error general toggleLike: \(error.localizedDescription)")
        }
    }
    
    func cargarNumeroDeLikes() async {
        do {
            let response = try await SupabaseManager.shared.client
                .from("post_likes")
                .select("post_id", count: .exact)
                .eq("post_id", value: postID)
                .execute()

            if let count = response.count {
                self.numLikes = count
            } else {
                self.numLikes = 0
            }
        } catch {
            print("❌ Error al cargar número de likes: \(error)")
            self.numLikes = 0
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


