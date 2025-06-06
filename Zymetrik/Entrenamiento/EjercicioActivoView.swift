import SwiftUI

struct EjercicioActivoView: View {
    @Binding var ejercicio: EjercicioEntrenamiento

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(ejercicio.nombre)
                .font(.headline)

            ForEach($ejercicio.sets) { $set in
                if ejercicio.tipo == .fuerza {
                    // Vista para fuerza
                    HStack(spacing: 12) {
                        TextField("Peso (kg)", text: $set.peso)
                            .keyboardType(.decimalPad)
                            .padding(8)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(8)

                        TextField("Reps", text: $set.repeticiones)
                            .keyboardType(.numberPad)
                            .padding(8)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(8)
                    }
                } else {
                    // Vista para cardio
                    HStack(spacing: 12) {
                        TextField("Tiempo (min)", text: $set.tiempo)
                            .keyboardType(.numberPad)
                            .padding(8)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(8)

                        TextField("Distancia (km)", text: $set.distancia)
                            .keyboardType(.decimalPad)
                            .padding(8)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(8)
                    }
                }
            }

            Button(action: {
                ejercicio.sets.append(SetEjercicio())
            }) {
                Label("Añadir set", systemImage: "plus")
                    .font(.subheadline)
            }
            .padding(.top, 4)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}
