import SwiftUI
import Supabase

struct UsuarioRowView: View {
    let perfil: Perfil
    @Binding var seguidos: Set<UUID>
    let currentUserID: UUID?

    var body: some View {
        HStack(spacing: 14) {
            if let url = perfil.avatar_url, let imageURL = URL(string: url) {
                AsyncImage(url: imageURL) { image in
                    image.resizable()
                } placeholder: {
                    Color.gray.opacity(0.3)
                }
                .frame(width: 44, height: 44)
                .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 44, height: 44)
                    .foregroundColor(.gray)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(perfil.username)
                    .font(.headline)
                Text(perfil.nombre)
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()

            if perfil.id != currentUserID {
                Button {
                    Task {
                        await toggleFollow(for: perfil.id)
                    }
                } label: {
                    Text(seguidos.contains(perfil.id) ? "Siguiendo" : "Seguir")
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(seguidos.contains(perfil.id) ? Color(.systemGray5) : Color.black)
                        .foregroundColor(seguidos.contains(perfil.id) ? .black : .white)
                        .cornerRadius(20)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal)
        .task {
            await verificarSeguimiento()
        }
    }

    // Verifica si el usuario actual sigue a este perfil (en caso de cambio desde otra vista)
    func verificarSeguimiento() async {
        guard let currentUserID else { return }
        guard !seguidos.contains(perfil.id) else { return } // Si ya está marcado como seguido, no comprobamos

        do {
            let response = try await SupabaseManager.shared.client
                .from("followers")
                .select("followed_id")
                .eq("follower_id", value: currentUserID.uuidString)
                .eq("followed_id", value: perfil.id.uuidString)
                .limit(1)
                .execute()

            if let _ = try? response.decoded(to: [String: String].self) {
                seguidos.insert(perfil.id)
            }
        } catch {
            print("❌ Error verificando seguimiento:", error)
        }
    }

    func toggleFollow(for followedID: UUID) async {
        guard let session = try? await SupabaseManager.shared.client.auth.session else {
            print("❌ No hay sesión activa")
            return
        }

        let currentUserID = session.user.id.uuidString
        let followedIDString = followedID.uuidString

        do {
            if seguidos.contains(followedID) {
                try await SupabaseManager.shared.client
                    .from("followers")
                    .delete()
                    .eq("follower_id", value: currentUserID)
                    .eq("followed_id", value: followedIDString)
                    .execute()

                seguidos.remove(followedID)
            } else {
                let insertData: [String: String] = [
                    "follower_id": currentUserID,
                    "followed_id": followedIDString
                ]

                try await SupabaseManager.shared.client
                    .from("followers")
                    .insert(insertData)
                    .execute()

                seguidos.insert(followedID)
            }
        } catch {
            print("❌ Error al alternar seguimiento: \(error)")
        }
    }
}
