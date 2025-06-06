import SwiftUI

struct FormularioEjercicioView: View {
    @Environment(\.dismiss) var dismiss
    var onGuardar: (EjercicioEntrenamiento) -> Void

    @State private var nombre = ""
    @State private var tipo: TipoEjercicio = .fuerza

    var body: some View {
        NavigationStack {
            Form {
                Section("Ejercicio") {
                    TextField("Nombre", text: $nombre)
                    Picker("Tipo", selection: $tipo) {
                        Text("Fuerza").tag(TipoEjercicio.fuerza)
                        Text("Cardio").tag(TipoEjercicio.cardio)
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("Nuevo Ejercicio")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        let nuevo = EjercicioEntrenamiento(
                            nombre: nombre,
                            tipo: tipo,
                            sets: [SetEjercicio()]
                        )
                        onGuardar(nuevo)
                        dismiss()
                    }
                }

                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
            }
        }
    }
}
