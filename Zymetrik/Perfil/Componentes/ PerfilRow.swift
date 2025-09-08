import SwiftUI

public struct PerfilRow: View {
    public let perfil: PerfilResumen
    public var showFollowButton: Bool = true

    @State private var isFollowing: Bool = false
    @State private var loading = false
    @State private var isMe = false

    public init(perfil: PerfilResumen, showFollowButton: Bool = true) {
        self.perfil = perfil
        self.showFollowButton = showFollowButton
    }

    public var body: some View {
        HStack(spacing: 14) {
            avatar(perfil.avatar_url)
            VStack(alignment: .leading, spacing: 2) {
                Text(perfil.nombre).font(.headline)
                Text("@\(perfil.username)").font(.caption).foregroundColor(.gray)
            }
            Spacer()

            if showFollowButton && !isMe {
                Button(action: { Task { await toggleFollow() } }) {
                    Text(isFollowing ? "Siguiendo" : "Seguir")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(isFollowing ? Color(.systemGray5) : Color.black)
                        .foregroundColor(isFollowing ? .black : .white)
                        .clipShape(Capsule())
                }
                .disabled(loading)
            }

            NavigationLink(destination: destinoPerfil(perfil)) {
                Image(systemName: "chevron.right").foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal)
        .task { await prepare() }
    }

    private func prepare() async {
        do {
            let me = try await SupabaseManager.shared.client.auth.session.user.id.uuidString
            isMe = (me == perfil.id)
            isFollowing = try await FollowersService.shared.isFollowing(currentUserID: me, targetUserID: perfil.id)
        } catch {
            isFollowing = false
        }
    }

    private func toggleFollow() async {
        guard !loading else { return }
        loading = true
        let prev = isFollowing
        isFollowing.toggle()
        do {
            if prev {
                _ = try await FollowersService.shared.unfollow(targetUserID: perfil.id)
                FollowNotification.post(targetUserID: perfil.id, didFollow: false)
            } else {
                _ = try await FollowersService.shared.follow(targetUserID: perfil.id)
                FollowNotification.post(targetUserID: perfil.id, didFollow: true)
            }
        } catch {
            isFollowing = prev
            print("❌ toggleFollow error: \(error)")
        }
        loading = false
    }

    @ViewBuilder
    private func destinoPerfil(_ p: PerfilResumen) -> some View {
        if isMe { PerfilView() } else { UserProfileView(username: p.username) }
    }

    @ViewBuilder
    private func avatar(_ urlString: String?) -> some View {
        if let urlString, let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty: ProgressView().frame(width: 44, height: 44)
                case .success(let img): img.resizable().frame(width: 44, height: 44).clipShape(Circle())
                case .failure: fallbackAvatar
                @unknown default: fallbackAvatar
                }
            }
        } else {
            fallbackAvatar
        }
    }

    private var fallbackAvatar: some View {
        Image(systemName: "person.circle.fill")
            .resizable().frame(width: 44, height: 44)
            .foregroundColor(.gray)
    }
}
