import SwiftUI
import Supabase

struct PerfilEntrenamientosView: View {
    let profileID: String? // nil para el perfil actual

    @State private var posts: [Post] = []
    @State private var error: String?
    @State private var hasLoaded: Bool = false   // ← para saber si ya terminó la primera carga

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if let error {
                    Text("❌ \(error)")
                        .foregroundColor(.red)
                        .padding(.vertical, 16)
                } else if hasLoaded && posts.isEmpty {
                    // Sin skeleton: solo mostramos vacío cuando ya sabemos que no hay posts
                    Text("Aún no hay publicaciones.")
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 16)
                } else {
                    ForEach(posts) { post in
                        PostView(post: post, feedKey: .paraTi)
                    }
                }
            }
            .padding(.vertical, 12) // sin padding horizontal → full-bleed
            .animation(.default, value: posts.count)
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .task { await cargarPosts() }          // Sigue cargando datos, pero sin UI de carga
        .refreshable { await cargarPosts() }   // Pull-to-refresh rehace la carga completa
    }

    func cargarPosts() async {
        do {
            let currentID: String
            if let profileID = profileID {
                currentID = profileID
            } else {
                // Sesión actual → id del usuario logueado
                currentID = try await SupabaseManager.shared.client.auth.session.user.id.uuidString
            }

            let response = try await SupabaseManager.shared.client
                .from("posts_enriched") // vista con datos del post + autor
                .select("""
                    id, fecha, autor_id, username, avatar_url, contenido, likes_count, comments_count
                """)
                .eq("autor_id", value: currentID)
                .order("fecha", ascending: false)
                .execute()

            let list = try response.decodedList(to: Post.self)

            await MainActor.run {
                self.posts = list
                self.error = nil
                self.hasLoaded = true
            }
        } catch {
            await MainActor.run {
                self.error = "Error al cargar posts: \(error.localizedDescription)"
                self.hasLoaded = true
            }
        }
    }
}
