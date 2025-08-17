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
            RoundedRectangle(cornerRadius: 20)
                .fill(fondoTarjeta(for: tipoSeleccionado))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(seleccionado ? Color.green : Color.black.opacity(0.05),
                                lineWidth: seleccionado ? 3 : 0.5)
                )
                .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 3)

            HStack(spacing: 14) {
                AsyncImage(url: URL(string: ejercicio.imagen_url ?? "")) { phase in
                    switch phase {
                    case .empty:
                        ProgressView().frame(width: 80, height: 80)
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .failure:
                        Image(systemName: "photo")
                            .resizable()
                            .scaledToFit()
                            .padding(20)
                            .foregroundColor(.gray)
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(width: 80, height: 80)
                .background(Color.gray.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.black.opacity(0.06), lineWidth: 0.5)
                )

                VStack(alignment: .leading, spacing: 6) {
                    Text(ejercicio.nombre)
                        .font(.headline)
                        .lineLimit(1)

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
