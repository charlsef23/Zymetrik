import SwiftUI
import Supabase

struct PerfilEntrenamientosView: View {
    let profileID: String? // nil para el perfil actual
    
    @State private var posts: [Post] = []
    @State private var cargando = true
    @State private var error: String?
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if cargando {
                    ProgressView("Cargando entrenamientos…")
                        .padding(.vertical, 24)
                } else if let error {
                    Text("❌ \(error)").foregroundColor(.red).padding(.vertical, 16)
                } else if posts.isEmpty {
                    Text("Este usuario no ha subido entrenamientos aún.")
                        .foregroundColor(.secondary)
                        .padding(.vertical, 24)
                } else {
                    ForEach(posts) { post in
                        PostView(post: post)
                        // Sin padding extra → se respetará el estilo del post
                    }
                }
            }
            .padding(.vertical, 12)      // nada de padding horizontal → full-bleed
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .task { await cargarPosts() }
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
                .from("posts_enriched") // 👈 usamos la vista
                .select("""
                    id, fecha, autor_id, username, avatar_url, contenido, likes_count, comments_count
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
