import SwiftUI

struct PostActionsView: View {
    @Binding var leDioLike: Bool
    @Binding var numLikes: Int
    @Binding var guardado: Bool
    @Binding var mostrarComentarios: Bool

    let toggleLike: () async -> Void
    let toggleSave: () async -> Void
    let onShowLikers: () -> Void

    var body: some View {
        HStack {
            // ❤️ Like + contador pegados
            HStack(spacing: 4) {
                Button {
                    Task { await toggleLike() }
                } label: {
                    Image(systemName: leDioLike ? "heart.fill" : "heart")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(leDioLike ? .red : .primary)
                        .symbolEffect(.bounce, value: leDioLike)
                }
                .buttonStyle(.plain)

                Button(action: onShowLikers) {
                    Text("\(max(0, numLikes))")
                        .font(.system(.subheadline, design: .rounded))
                        .fontWeight(.semibold)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Usuarios a los que les gusta")
            }

            // 💬 Comentarios al lado de los likes
            Button { mostrarComentarios = true } label: {
                Image(systemName: "message")
                    .font(.system(size: 18, weight: .semibold))
            }
            .buttonStyle(.plain)
            .padding(.leading, 16)

            Spacer()

            // 🔖 Guardar a la derecha
            Button {
                Task { await toggleSave() }
            } label: {
                Image(systemName: guardado ? "bookmark.fill" : "bookmark")
                    .font(.system(size: 18, weight: .semibold))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 6)
    }
}
