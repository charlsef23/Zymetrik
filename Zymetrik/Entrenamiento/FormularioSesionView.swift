import SwiftUI

struct FormularioSesionView: View {
    @Environment(\.dismiss) var dismiss
    var onGuardar: (SesionEntrenamiento) -> Void

    @State private var titulo = ""
    @State private var fecha = Date()
    @State private var ejercicios: [EjercicioEntrenamiento] = []

    var body: some View {
        NavigationStack {
            Form {
                Section("Detalles de la sesión") {
                    TextField("Título del entrenamiento", text: $titulo)
                    DatePicker("Fecha", selection: $fecha, displayedComponents: .date)
                }

                Section("Ejercicios") {
                    if ejercicios.isEmpty {
                        Text("Añade al menos un ejercicio")
                            .foregroundColor(.gray)
                    } else {
                        ForEach(ejercicios.indices, id: \.self) { i in
                            HStack {
                                Text(ejercicios[i].nombre)
                                Spacer()
                                Text(ejercicios[i].tipo == .fuerza ? "💪" : "🏃")
                            }
                        }
                    }

                    Button(action: {
                        mostrarFormularioEjercicio()
                    }) {
                        Label("Añadir ejercicio", systemImage: "plus.circle")
                    }
                }
            }
            .navigationTitle("Nueva sesión")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        let sesion = SesionEntrenamiento(
                            titulo: titulo.isEmpty ? "Sin título" : titulo,
                            fecha: fecha.stripTime(),
                            ejercicios: ejercicios
                        )
                        onGuardar(sesion)
                        dismiss()
                    }
                    .disabled(ejercicios.isEmpty)
                }

                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
            }
        }
    }

    // Simulador temporal de ejercicios
    func mostrarFormularioEjercicio() {
        let nuevo = EjercicioEntrenamiento(
            nombre: "Ejercicio \(ejercicios.count + 1)",
            tipo: ejercicios.count % 2 == 0 ? .fuerza : .cardio,
            sets: [SetEjercicio()]
        )
        ejercicios.append(nuevo)
    }
}
