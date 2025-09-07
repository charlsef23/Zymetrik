import SwiftUI

struct PostActionsView: View {
    @Binding var leDioLike: Bool
    @Binding var numLikes: Int
    @Binding var guardado: Bool
    @Binding var mostrarComentarios: Bool

    let toggleLike: () async -> Void
    let toggleSave: () async -> Void

    init(
        leDioLike: Binding<Bool>,
        numLikes: Binding<Int>,
        guardado: Binding<Bool>,
        mostrarComentarios: Binding<Bool>,
        toggleLike: @escaping () async -> Void,
        toggleSave: @escaping () async -> Void
    ) {
        self._leDioLike = leDioLike
        self._numLikes = numLikes
        self._guardado = guardado
        self._mostrarComentarios = mostrarComentarios
        self.toggleLike = toggleLike
        self.toggleSave = toggleSave
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 20) {
                Button {
                    Task { await toggleLike() }
                } label: {
                    Image(systemName: leDioLike ? "heart.fill" : "heart")
                        .font(.title3)
                        .foregroundColor(leDioLike ? .red : .primary)
                        .accessibilityLabel(leDioLike ? "Quitar me gusta" : "Dar me gusta")
                }

                Button {
                    mostrarComentarios = true
                } label: {
                    Image(systemName: "bubble.right")
                        .font(.title3)
                        .accessibilityLabel("Abrir comentarios")
                }

                Spacer()

                Button {
                    Task { await toggleSave() }
                } label: {
                    Image(systemName: guardado ? "bookmark.fill" : "bookmark")
                        .font(.title3)
                        .accessibilityLabel(guardado ? "Quitar guardado" : "Guardar post")
                }
            }

            Text("\(numLikes) me gusta")
                .font(.subheadline.bold())
                .foregroundStyle(.primary)
                .accessibilityLabel(Text("\(numLikes) me gusta"))
        }
    }
}
