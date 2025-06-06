import SwiftUI

struct EntrenandoView: View {
    let entrenamiento: Entrenamiento

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                
                // Título y fecha
                Text(entrenamiento.nombre)
                    .font(.title.bold())

                Text(formatearFecha(entrenamiento.fecha))
                    .font(.subheadline)
                    .foregroundColor(.gray)

                Divider()

                // Lista de ejercicios
                if entrenamiento.ejercicios.isEmpty {
                    Text("No hay ejercicios asignados.")
                        .foregroundColor(.gray)
                } else {
                    ForEach(entrenamiento.ejercicios) { ejercicio in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(ejercicio.nombre)
                                .font(.headline)

                            // Detalles del ejercicio
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Series: \(ejercicio.series)")
                                Text("Repeticiones: \(ejercicio.repeticiones)")
                                Text("Peso: \(ejercicio.peso) kg")
                            }
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                }

                Spacer(minLength: 100)
            }
            .padding()
        }
        .navigationTitle("Entrenando")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func formatearFecha(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.locale = Locale(identifier: "es_ES")
        return formatter.string(from: date)
    }
}
