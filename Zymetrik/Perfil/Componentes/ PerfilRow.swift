import SwiftUI
import Supabase

public struct PerfilRow: View {
    public let perfil: PerfilResumen
    public let showFollowButton: Bool
    @Environment(\.colorScheme) private var colorScheme

    @State private var isFollowing = false
    @State private var working = false
    @State private var myUserID: String = ""

    public init(perfil: PerfilResumen, showFollowButton: Bool) {
        self.perfil = perfil
        self.showFollowButton = showFollowButton
    }

    public var body: some View {
        HStack(spacing: 12) {
            avatar(perfil.avatar_url)
                .frame(width: 48, height: 48)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(perfil.nombre)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text("@\(perfil.username)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()

            if showFollowButton, !myUserID.isEmpty, myUserID != perfil.id {
                Button(action: { Task { await toggleFollow() } }) {
                    Text(isFollowing ? "Siguiendo" : "Seguir")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(isFollowing ? Color(.systemGray5) : (colorScheme == .dark ? .white : .black))
                        .foregroundColor(isFollowing ? (colorScheme == .dark ? .white : .black) : (colorScheme == .dark ? .black : .white))
                        .clipShape(Capsule())
                }
                .disabled(working)
            }
        }
        .padding(.horizontal)
        .frame(maxWidth: .infinity, alignment: .leading)
        .task { await cargarEstadoInicial() }
    }

    private func cargarEstadoInicial() async {
        do {
            myUserID = try await SupabaseManager.shared.client.auth.session.user.id.uuidString
            isFollowing = try await FollowersService.shared.isFollowing(
                currentUserID: myUserID,
                targetUserID: perfil.id
            )
        } catch {
            isFollowing = false
        }
    }

    private func toggleFollow() async {
        guard !myUserID.isEmpty, myUserID != perfil.id else { return }
        working = true
        let was = isFollowing
        isFollowing.toggle()

        do {
            if was {
                _ = try await FollowersService.shared.unfollow(targetUserID: perfil.id)
            } else {
                _ = try await FollowersService.shared.follow(targetUserID: perfil.id)
            }
        } catch {
            // revertir si falla
            isFollowing = was
            print("❌ PerfilRow toggleFollow:", error)
        }
        working = false
    }

    @ViewBuilder
    private func avatar(_ urlString: String?) -> some View {
        if let urlString, let url = URL(string: urlString) {
            AsyncImage(url: url) { img in
                img.resizable()
            } placeholder: { Color(.systemGray5) }
        } else {
            Image(systemName: "person.circle.fill")
                .resizable()
                .foregroundColor(.gray)
        }
    }
}
