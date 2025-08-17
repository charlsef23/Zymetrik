import SwiftUI

struct EjerciciosAgrupadosView: View {
    let ejerciciosFiltradosPorTipo: [String: [Ejercicio]]
    let tipoSeleccionado: String
    @Binding var seleccionados: Set<UUID>

    var isFavorito: (UUID) -> Bool
    var onToggleFavorito: (UUID) -> Void

    var body: some View {
        LazyVStack(alignment: .leading, spacing: 32) {
            ForEach(ejerciciosFiltradosPorTipo.sorted(by: { $0.key < $1.key }), id: \.key) { categoria, items in
                VStack(alignment: .leading, spacing: 16) {
                    Text(categoria)
                        .font(.title2.bold())
                        .padding(.horizontal)

                    ForEach(items.sorted(by: { $0.nombre.localizedCaseInsensitiveCompare($1.nombre) == .orderedAscending })) { ejercicio in
                        EjercicioCardView(
                            ejercicio: ejercicio,
                            tipoSeleccionado: tipoSeleccionado, // si es "Favoritos" aplicará su estilo
                            seleccionado: seleccionados.contains(ejercicio.id),
                            esFavorito: isFavorito(ejercicio.id),
                            onToggleFavorito: { onToggleFavorito(ejercicio.id) }
                        )
                        .onTapGesture {
                            if seleccionados.contains(ejercicio.id) {
                                seleccionados.remove(ejercicio.id)
                            } else {
                                seleccionados.insert(ejercicio.id)
                            }
                        }
                    }
                }
            }
        }
    }
}
