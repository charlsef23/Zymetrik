import SwiftUI
import UIKit

struct PostHeader: View {
    let post: Post
    var onEliminar: (() -> Void)?
    var onCompartir: (() -> Void)?
    var preloadedAvatar: UIImage?

    init(
        post: Post,
        onEliminar: (() -> Void)? = nil,
        onCompartir: (() -> Void)? = nil,
        preloadedAvatar: UIImage? = nil
    ) {
        self.post = post
        self.onEliminar = onEliminar
        self.onCompartir = onCompartir
        self.preloadedAvatar = preloadedAvatar
    }

    var body: some View {
        HStack(spacing: 12) {
            AvatarAsyncImage(url: URL(string: post.avatar_url ?? ""), size: 40, preloaded: preloadedAvatar)

            NavigationLink(destination: UserProfileView(username: post.username)) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("@\(post.username)")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)
                    Text(post.fecha.timeAgoDisplay())
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Menu {
                Button { onCompartir?() } label: {
                    Label("Compartir", systemImage: "square.and.arrow.up")
                }
                Button(role: .destructive) { onEliminar?() } label: {
                    Label("Eliminar post", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .rotationEffect(.degrees(90))
                    .font(.subheadline)
                    .padding(.horizontal, 4)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel(Text("Más opciones"))
        }
    }
}
