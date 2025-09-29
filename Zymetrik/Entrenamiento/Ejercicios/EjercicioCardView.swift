import SwiftUI

struct EjercicioCardView: View {
    let ejercicio: Ejercicio
    let seleccionado: Bool
    let esFavorito: Bool
    let onToggleFavorito: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(seleccionado ? Color.green.opacity(0.7) : Color.black.opacity(0.06),
                                lineWidth: seleccionado ? 2 : 1)
                )
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)

            HStack(spacing: 14) {
                AsyncImage(url: URL(string: ejercicio.imagen_url ?? "")) { phase in
                    switch phase {
                    case .empty: ProgressView().frame(width: 70, height: 70)
                    case .success(let image): image.resizable().scaledToFill()
                    case .failure:
                        Image(systemName: "photo")
                            .resizable().scaledToFit().padding(16).foregroundColor(.gray)
                    @unknown default: EmptyView()
                    }
                }
                .frame(width: 70, height: 70)
                .background(Color.gray.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black.opacity(0.06), lineWidth: 1))

                VStack(alignment: .leading, spacing: 6) {
                    Text(ejercicio.nombre)
                        .font(.headline.weight(.semibold))
                        .lineLimit(1)

                    if !ejercicio.descripcion.isEmpty {
                        Text(ejercicio.descripcion)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }

                    // Chips internos: parte del cuerpo + tipo
                    HStack(spacing: 8) {
                        Chip(text: ejercicio.tipo)
                        Chip(text: ejercicio.categoria.isEmpty ? "General" : ejercicio.categoria)
                    }
                }
                Spacer()

                // Indicador selección
                ZStack {
                    Circle()
                        .fill(seleccionado ? Color.green.opacity(0.18) : Color.black.opacity(0.06))
                        .frame(width: 28, height: 28)
                    Image(systemName: seleccionado ? "checkmark" : "plus")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(seleccionado ? .green : .secondary)
                }
            }
            .padding(12)

            // ⭐
            Button(action: onToggleFavorito) {
                Image(systemName: esFavorito ? "star.fill" : "star")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(esFavorito ? .yellow : .gray)
                    .padding([.top, .trailing], 8)
            }
            .buttonStyle(.plain)
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: seleccionado)
    }
}

private struct Chip: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.caption.bold())
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Capsule().fill(Color.black.opacity(0.06)))
    }
}
