import SwiftUI

struct ChatTopBar: View {
    let user: PerfilLite?
    let isTyping: Bool
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                AvatarAsyncImage(url: URL(string: user?.avatar_url ?? ""), size: 34)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(user?.username ?? "Usuario")
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .lineLimit(1)

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Text(isTyping ? "Escribiendo…" : "Ver perfil")
                        .font(.caption)
                        .foregroundStyle(isTyping ? .blue : .secondary)
                        .lineLimit(1)
                        .transition(.opacity)
                }
            }
            .padding(.vertical, 4)
            .padding(.top, 2) // 👈 lo bajamos un poquito
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
