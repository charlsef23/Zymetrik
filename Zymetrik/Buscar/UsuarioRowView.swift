import SwiftUI
import Supabase

// Helper local para silenciar cancelaciones de red (-999)
private func isCancelled(_ error: Error) -> Bool {
    if let urlErr = error as? URLError, urlErr.code == .cancelled { return true }
    if let nsErr = error as NSError?, nsErr.domain == NSURLErrorDomain && nsErr.code == NSURLErrorCancelled { return true }
    return (error as? CancellationError) != nil
}

// MARK: - Fila de usuario (resultados)

struct UsuarioRowView: View {
    let perfil: Perfil
    @Binding var seguidos: Set<UUID>
    let currentUserID: UUID?

    var body: some View {
        HStack(spacing: 12) {
            if let url = perfil.avatar_url, let imageURL = URL(string: url) {
                AsyncImage(url: imageURL) { image in
                    image.resizable()
                } placeholder: {
                    Color.gray.opacity(0.3)
                }
                .frame(width: 56, height: 56)
                .clipShape(Circle())
                .accessibilityHidden(true)
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 56, height: 56)
                    .foregroundColor(.gray)
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(perfil.username)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                    .accessibilityLabel("Usuario \(perfil.username)")

                if !perfil.nombre.isEmpty {
                    Text(perfil.nombre)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .accessibilityLabel("Nombre \(perfil.nombre)")
                }
            }

            Spacer()

            if perfil.id != currentUserID {
                Button {
                    Task { await toggleFollow(for: perfil.id) }
                } label: {
                    Text(seguidos.contains(perfil.id) ? "Siguiendo" : "Seguir")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(seguidos.contains(perfil.id) ? Color(.systemGray5) : Color.black)
                        .foregroundColor(seguidos.contains(perfil.id) ? .primary : .white)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("usuario.seguir")
                .accessibilityLabel(seguidos.contains(perfil.id) ? "Dejar de seguir" : "Seguir usuario")
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal)
        .accessibilityIdentifier("usuario.row.\(perfil.id.uuidString)")
        .task { await verificarSeguimiento() }
    }

    // Verifica si el usuario actual sigue a este perfil (por si cambió en otra vista)
    @MainActor
    private func verificarSeguimiento() async {
        guard let currentUserID else { return }
        guard !seguidos.contains(perfil.id) else { return }

        do {
            let response = try await SupabaseManager.shared.client
                .from("followers")
                .select("followed_id")
                .eq("follower_id", value: currentUserID.uuidString)
                .eq("followed_id", value: perfil.id.uuidString)
                .limit(1)
                .execute()

            if let dict = try? JSONSerialization.jsonObject(with: response.data) as? [[String: String]],
               dict.first?["followed_id"] != nil {
                _ = await MainActor.run { seguidos.insert(perfil.id) }
            }
        } catch {
            if !isCancelled(error) {
                print("❌ Error verificando seguimiento (real): \(error)")
            }
        }
    }

    private func toggleFollow(for followedID: UUID) async {
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

                _ = await MainActor.run { seguidos.remove(followedID) }
            } else {
                let insertData: [String: String] = [
                    "follower_id": currentUserID,
                    "followed_id": followedIDString
                ]

                try await SupabaseManager.shared.client
                    .from("followers")
                    .insert(insertData)
                    .execute()

                _ = await MainActor.run { seguidos.insert(followedID) }
            }
        } catch {
            if !isCancelled(error) {
                print("❌ Error al alternar seguimiento (real): \(error)")
            }
        }
    }
}

