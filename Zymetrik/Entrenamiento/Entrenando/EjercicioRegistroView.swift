import SwiftUI

struct EjercicioRegistroView: View {
    let ejercicio: Ejercicio
    let sets: [SetRegistro]

    // Callbacks
    let onAddSet: () -> Void
    let onUpdateSet: (Int, Int, Double) -> Void
    var onDeleteSet: ((Int) -> Void)? = nil
    var onDuplicateSet: ((Int) -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Cabecera limpia
            HStack(spacing: 12) {
                AsyncImage(url: URL(string: ejercicio.imagen_url ?? "")) { phase in
                    switch phase {
                    case .empty:
                        Color(.secondarySystemBackground)
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .failure:
                        ZStack {
                            Color(.secondarySystemBackground)
                            Image(systemName: "photo")
                                .foregroundStyle(.secondary)
                        }
                    @unknown default:
                        Color(.secondarySystemBackground)
                    }
                }
                .frame(width: 48, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 2) {
                    Text(ejercicio.nombre)
                        .font(.system(.headline, design: .rounded))
                    if !ejercicio.descripcion.isEmpty {
                        Text(ejercicio.descripcion)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 2)

            // Sección de series (Ultra-Clean)
            SetsSectionCard(
                titulo: "Series",
                sets: sets,
                onAddSet: onAddSet,
                onUpdateSet: onUpdateSet,
                onDeleteSet: { i in onDeleteSet?(i) },
                onDuplicateSet: { i in onDuplicateSet?(i) }
            )
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.secondary.opacity(0.10), lineWidth: 1)
        )
        .padding(.horizontal)
    }
}
