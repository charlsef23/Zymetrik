import SwiftUI
import Supabase

struct PerfilEntrenamientosView: View {
    let profileID: String? // nil para el perfil actual

    @State private var posts: [Post] = []
    @State private var cargando = true
    @State private var error: String?

    var body: some View {
        VStack {
            if cargando {
                ProgressView("Cargando entrenamientos...")
                    .padding()
            } else if let error = error {
                Text("❌ \(error)").foregroundColor(.red)
            } else if posts.isEmpty {
                Text("Este usuario no ha subido entrenamientos aún.")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                LazyVStack(spacing: 24) {
                    ForEach(posts) { post in
                        PostView(post: post)
                    }
                }
                .padding(.horizontal)
            }
        }
        .task {
            await cargarPosts()
        }
    }

    func cargarPosts() async {
        do {
            let currentID: String
            if let profileID = profileID {
                currentID = profileID
            } else {
                currentID = try await SupabaseManager.shared.client.auth.session.user.id.uuidString
            }

            let response = try await SupabaseManager.shared.client
                .from("posts")
                .select("""
                    id, fecha, autor_id, avatar_url, username, contenido
                """)
                .eq("autor_id", value: currentID)
                .order("fecha", ascending: false)
                .execute()

            self.posts = try response.decodedList(to: Post.self)
            self.cargando = false

        } catch {
            self.error = "Error al cargar posts: \(error.localizedDescription)"
            self.cargando = false
        }
    }
}
