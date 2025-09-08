import SwiftUI

struct EjercicioCardView: View {
    let ejercicio: Ejercicio
    let tipoSeleccionado: String
    let seleccionado: Bool

    let esFavorito: Bool
    let onToggleFavorito: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Fondo + borde (verde si seleccionado)
            RoundedRectangle(cornerRadius: 18)
                .fill(fondoTarjeta(for: tipoSeleccionado))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(seleccionado ? Color.green.opacity(0.7) : Color.black.opacity(0.06),
                                lineWidth: seleccionado ? 2.5 : 1)
                )
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)

            HStack(spacing: 14) {
                AsyncImage(url: URL(string: ejercicio.imagen_url ?? "")) { phase in
                    switch phase {
                    case .empty:
                        ProgressView().frame(width: 76, height: 76)
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .failure:
                        Image(systemName: "photo")
                            .resizable()
                            .scaledToFit()
                            .padding(18)
                            .foregroundColor(.gray)
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(width: 76, height: 76)
                .background(Color.gray.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.black.opacity(0.06), lineWidth: 1)
                )

                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(ejercicio.nombre)
                            .font(.system(.headline, design: .rounded)).bold()
                            .lineLimit(1)
                        Spacer(minLength: 0)
                    }

                    Text(ejercicio.descripcion)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)

                    HStack(spacing: 8) {
                        Chip(text: ejercicio.categoria)
                        Chip(text: ejercicio.tipo)
                    }
                }
                Spacer()

                // Check visual de selección
                ZStack {
                    Circle()
                        .fill(seleccionado ? Color.green.opacity(0.15) : Color.black.opacity(0.06))
                        .frame(width: 28, height: 28)
                    Image(systemName: seleccionado ? "checkmark" : "plus")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(seleccionado ? .green : .secondary)
                }
                .accessibilityLabel(seleccionado ? "Seleccionado" : "No seleccionado")
            }
            .padding(12)

            // ⭐ Pequeña sin fondo
            Button(action: onToggleFavorito) {
                Image(systemName: esFavorito ? "star.fill" : "star")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(esFavorito ? .yellow : .gray)
                    .padding([.top, .trailing], 8)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal)
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: seleccionado)
    }

    func fondoTarjeta(for tipo: String) -> LinearGradient {
        let start: Color, end: Color
        switch tipo {
        case "Gimnasio":
            start = Color.blue.opacity(0.10); end = Color.purple.opacity(0.08)
        case "Cardio":
            start = Color.red.opacity(0.10); end = Color.orange.opacity(0.08)
        case "Funcional":
            start = Color.green.opacity(0.10); end = Color.teal.opacity(0.08)
        case "Favoritos":
            start = Color.yellow.opacity(0.12); end = Color.orange.opacity(0.08)
        default:
            start = Color.gray.opacity(0.08); end = Color.gray.opacity(0.05)
        }
        return LinearGradient(colors: [start, end], startPoint: .topLeading, endPoint: .bottomTrailing)
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
