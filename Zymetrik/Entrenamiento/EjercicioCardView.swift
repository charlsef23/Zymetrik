import SwiftUI

struct EjercicioCardView: View {
    @Binding var ejercicio: EjercicioEntrenamiento
    @State private var expandido = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(ejercicio.nombre)
                    .font(.headline)
                Spacer()
                Text(ejercicio.tipo == .fuerza ? "Fuerza" : "Cardio")
                    .font(.caption2)
                    .padding(6)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(6)
            }

            if expandido {
                ForEach($ejercicio.sets) { $set in
                    if ejercicio.tipo == .fuerza {
                        fuerzaFields(set: $set)
                    } else {
                        cardioFields(set: $set)
                    }
                }

                Button(action: {
                    ejercicio.sets.append(SetEjercicio())
                }) {
                    Label("Añadir set", systemImage: "plus")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
                .padding(.top, 4)
            }

            HStack {
                Spacer()
                Button {
                    withAnimation(.easeInOut) {
                        expandido.toggle()
                    }
                } label: {
                    Image(systemName: expandido ? "chevron.up" : "chevron.down")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)
    }

    @ViewBuilder
    private func fuerzaFields(set: Binding<SetEjercicio>) -> some View {
        HStack(spacing: 12) {
            TextField("Peso (kg)", text: set.peso)
                .keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder)
            TextField("Reps", text: set.repeticiones)
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
        }
    }

    @ViewBuilder
    private func cardioFields(set: Binding<SetEjercicio>) -> some View {
        HStack(spacing: 12) {
            TextField("Tiempo (min)", text: set.tiempo)
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
            TextField("Distancia (km)", text: set.distancia)
                .keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder)
        }
    }
}
