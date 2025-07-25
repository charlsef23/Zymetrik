import SwiftUI

struct EstadisticaEjercicioCard: View {
    let ejercicio: EjercicioPostContenido
    let sesiones: [SesionEjercicio]
    @Binding var ejerciciosAbiertos: Set<UUID>

    var body: some View {
        DisclosureGroup(
            isExpanded: Binding(
                get: { ejerciciosAbiertos.contains(ejercicio.id) },
                set: { expanded in
                    if expanded {
                        ejerciciosAbiertos.insert(ejercicio.id)
                    } else {
                        ejerciciosAbiertos.remove(ejercicio.id)
                    }
                }
            )
        ) {
            GraficaPesoView(sesiones: sesiones)
                .padding(.top, 8)
        } label: {
            HStack {
                Text(ejercicio.nombre)
                    .font(.headline)

                Spacer()

                let estado = compararProgreso(sesiones)
                ProgresoCirculoView(estado: estado)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
    }
}
