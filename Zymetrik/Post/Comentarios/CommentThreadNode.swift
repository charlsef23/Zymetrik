import SwiftUI

struct CommentThreadNode: View {
    let comentario: Comentario
    let nivel: Int
    let childrenProvider: (UUID?) -> [Comentario]
    var onReply: (Comentario) -> Void

    @Environment(\.colorScheme) private var scheme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 10) {
                // Avatar del autor del comentario
                AvatarAsyncImage(url: comentario.avatarURL, size: 28)

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Text("@\(comentario.username)")
                            .font(.subheadline.weight(.semibold))
                        Text(comentario.creado_en.timeAgoDisplay())
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button("Responder") { onReply(comentario) }
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Text(comentario.contenido)
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(scheme == .dark
                                      ? Color.white.opacity(0.06)
                                      : Color(.secondarySystemBackground))
                        )
                }
            }

            // Hijos (respuestas)
            let hijos = childrenProvider(comentario.id)
            if !hijos.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(hijos) { child in
                        CommentThreadNode(
                            comentario: child,
                            nivel: nivel + 1,
                            childrenProvider: childrenProvider,
                            onReply: onReply
                        )
                        .padding(.leading, 24)
                    }
                }
            }
        }
    }
}
