import SwiftUI

struct EjerciciosAgrupadosView: View {
    let ejerciciosFiltradosPorTipo: [String: [Ejercicio]]
    let tipoSeleccionado: String
    @Binding var seleccionados: Set<UUID>

    var isFavorito: (UUID) -> Bool
    var onToggleFavorito: (UUID) -> Void
    var onToggleSeleccion: (UUID) -> Void   // ⬅️ nuevo: notifica para persistir

    var body: some View {
        LazyVStack(alignment: .leading, spacing: 28) {
            ForEach(ejerciciosFiltradosPorTipo.sorted(by: { $0.key < $1.key }), id: \.key) { categoria, items in
                VStack(alignment: .leading, spacing: 12) {
                    Text(categoria)
                        .font(.title2.bold())
                        .padding(.horizontal)

                    ForEach(items.sorted(by: { $0.nombre.localizedCaseInsensitiveCompare($1.nombre) == .orderedAscending })) { ejercicio in
                        EjercicioCardView(
                            ejercicio: ejercicio,
                            tipoSeleccionado: tipoSeleccionado,
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
                            onToggleSeleccion(ejercicio.id) // ⬅️ persistir
                        }
                    }
                }
            }
        }
    }
}
