import SwiftUI

struct PostActionsView: View {
    @Binding var leDioLike: Bool
    @Binding var numLikes: Int
    @Binding var guardado: Bool
    @Binding var mostrarComentarios: Bool

    let toggleLike: () async -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 20) {
                Button {
                    Task { await toggleLike() }
                } label: {
                    Image(systemName: leDioLike ? "heart.fill" : "heart")
                        .foregroundColor(leDioLike ? .red : .primary)
                }

                Button {
                    mostrarComentarios = true
                } label: {
                    Image(systemName: "bubble.right")
                }

                Spacer()

                Button {
                    guardado.toggle()
                } label: {
                    Image(systemName: guardado ? "bookmark.fill" : "bookmark")
                }
            }
            .font(.title3)

            Text("\(numLikes) me gusta")
                .font(.subheadline.bold())
        }
    }
}
