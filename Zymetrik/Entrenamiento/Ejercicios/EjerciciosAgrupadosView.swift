import SwiftUI

struct EjerciciosAgrupadosView: View {
    let ejerciciosFiltradosPorTipo: [String: [Ejercicio]]
    let tipoSeleccionado: String
    @Binding var seleccionados: Set<UUID>

    var body: some View {
        LazyVStack(alignment: .leading, spacing: 32) {
            ForEach(ejerciciosFiltradosPorTipo.sorted(by: { $0.key < $1.key }), id: \.key) { categoria, items in
                VStack(alignment: .leading, spacing: 16) {
                    Text(categoria)
                        .font(.title2.bold())
                        .padding(.horizontal)

                    ForEach(items.sorted(by: { $0.nombre.localizedCaseInsensitiveCompare($1.nombre) == .orderedAscending })) { ejercicio in
                        EjercicioCardView(ejercicio: ejercicio, tipoSeleccionado: tipoSeleccionado, seleccionado: seleccionados.contains(ejercicio.id))
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
