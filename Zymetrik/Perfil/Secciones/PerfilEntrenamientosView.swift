import SwiftUI
import Supabase

struct PerfilEntrenamientosView: View {
    let profileID: String? // nil para el perfil actual

    @State private var posts: [UUID] = []
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
                    ForEach(posts, id: \.self) { postID in
                        PostView(postID: postID)
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
                .select("id")
                .eq("autor_id", value: currentID)
                .order("fecha", ascending: false)
                .execute()

            // 🔍 Manejo seguro del JSON para evitar errores de tipo
            guard let jsonArray = try JSONSerialization.jsonObject(with: response.data) as? [[String: Any]] else {
                self.error = "Error al leer los datos"
                self.cargando = false
                return
            }

            self.posts = jsonArray.compactMap { dict in
                if let idStr = dict["id"] as? String {
                    return UUID(uuidString: idStr)
                }
                return nil
            }

            self.cargando = false

        } catch {
            self.error = "Error al cargar posts: \(error.localizedDescription)"
            self.cargando = false
        }
    }
}
