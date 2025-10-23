import SwiftUI
import Supabase

struct PerfilEntrenamientosView: View {
    let profileID: String? // nil para el perfil actual
    
    @State private var posts: [Post] = []
    @State private var error: String?
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if let error {
                    Text("❌ \(error)").foregroundColor(.red).padding(.vertical, 16)
                } else if posts.isEmpty {
                    ForEach(0..<3, id: \.self) { _ in
                        PerfilPostSkeletonView()
                            .redacted(reason: .placeholder)
                    }
                } else {
                    ForEach(posts) { post in
                        PostView(post: post, feedKey: .paraTi)
                        // Sin padding extra → se respetará el estilo del post
                    }
                }
            }
            .padding(.vertical, 12)      // nada de padding horizontal → full-bleed
            .animation(.default, value: posts.count)
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .task { await cargarPosts() }
        .refreshable { await cargarPosts() }
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
            self.error = nil
            
        } catch {
            self.error = "Error al cargar posts: \(error.localizedDescription)"
        }
    }
}

private struct PerfilPostSkeletonView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Circle()
                    .fill(Color.secondary.opacity(0.2))
                    .frame(width: 40, height: 40)
                VStack(alignment: .leading, spacing: 6) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.secondary.opacity(0.2))
                        .frame(width: 120, height: 14)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.secondary.opacity(0.15))
                        .frame(width: 80, height: 12)
                }
                Spacer()
            }
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.secondary.opacity(0.15))
                .frame(height: 200)
        }
        .padding(.horizontal)
    }
}
