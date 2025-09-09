import SwiftUI

struct EjerciciosAgrupadosView: View {
    let ejerciciosFiltradosPorTipo: [String: [Ejercicio]]
    let tipoSeleccionado: String
    @Binding var seleccionados: Set<UUID>

    var isFavorito: (UUID) -> Bool
    var onToggleFavorito: (UUID) -> Void
    var onToggleSeleccion: (UUID) -> Void = { _ in } // opcional

    var body: some View {
        // 1) Precalculamos las claves ordenadas (categorías)
        let categoriasOrdenadas: [String] = {
            let keys = Array(ejerciciosFiltradosPorTipo.keys)
            return keys.sorted { a, b in
                a.localizedCaseInsensitiveCompare(b) == .orderedAscending
            }
        }()

        return LazyVStack(alignment: .leading, spacing: 20) {
            ForEach(categoriasOrdenadas, id: \.self) { categoria in
                // 2) Obtenemos y ordenamos los items de esta categoría
                let items: [Ejercicio] = ejerciciosFiltradosPorTipo[categoria] ?? []
                let itemsOrdenados: [Ejercicio] = items.sorted { lhs, rhs in
                    lhs.nombre.localizedCaseInsensitiveCompare(rhs.nombre) == .orderedAscending
                }

                // Si no quieres mostrar el título de categoría, comenta el Text siguiente
                // Text(categoria).font(.title2.bold()).padding(.horizontal)

                // 3) Render de tarjetas
                VStack(spacing: 14) {
                    ForEach(itemsOrdenados) { ejercicio in
                        EjercicioCardView(
                            ejercicio: ejercicio,
                            seleccionado: seleccionados.contains(ejercicio.id),
                            esFavorito: isFavorito(ejercicio.id),
                            onToggleFavorito: { onToggleFavorito(ejercicio.id) }
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if seleccionados.contains(ejercicio.id) {
                                seleccionados.remove(ejercicio.id)
                            } else {
                                seleccionados.insert(ejercicio.id)
                            }
                            onToggleSeleccion(ejercicio.id)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}
