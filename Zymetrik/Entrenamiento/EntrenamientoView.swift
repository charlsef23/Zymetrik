import SwiftUI

struct EntrenamientoView: View {
    @State private var fechaSeleccionada = Date()
    @State private var mostrarFormulario = false

    // Sesiones de entrenamiento organizadas por fecha
    @State private var sesionesPorFecha: [Date: [SesionEntrenamiento]] = [:]

    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(spacing: 24) {
                        // Selector de calendario (mensual ↔ horizontal)
                        CalendarioSelectorView(
                            selectedDate: $fechaSeleccionada,
                            fechasConEntrenamiento: Set(sesionesPorFecha.keys.map { $0.stripTime() })
                        )
                        .padding(.horizontal)

                        // Sesiones del día seleccionado
                        let fechaKey = fechaSeleccionada.stripTime()
                        let sesiones = sesionesPorFecha[fechaKey] ?? []

                        if sesiones.isEmpty {
                            Text("No tienes entrenamientos para este día.")
                                .foregroundColor(.gray)
                                .padding(.horizontal)
                        } else {
                            ForEach(sesiones) { sesion in
                                SesionCardView(sesion: sesion)
                            }
                        }

                        Spacer(minLength: 120)
                    }
                    .padding(.top)
                }

                // Botón flotante
                FloatingAddButton {
                    mostrarFormulario = true
                }
            }
            .sheet(isPresented: $mostrarFormulario) {
                FormularioSesionView { nuevaSesion in
                    let key = nuevaSesion.fecha
                    sesionesPorFecha[key, default: []].append(nuevaSesion)
                }
            }
            .navigationTitle("Toca Entrenar")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(.systemGroupedBackground))
        }
    }

    // MARK: - Helpers

    private func formatearFechaCompleta(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_ES")
        formatter.dateStyle = .full
        return formatter.string(from: date)
    }
}

#Preview {
    EntrenamientoView()
}
