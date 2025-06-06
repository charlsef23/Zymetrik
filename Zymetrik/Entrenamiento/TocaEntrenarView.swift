import SwiftUI

struct TocaEntrenarView: View {
    @Environment(\.dismiss) var dismiss

    @State var ejercicios: [EjercicioEntrenamiento] = [
        EjercicioEntrenamiento(nombre: "Press Banca", tipo: .fuerza, sets: [SetEjercicio()]),
        EjercicioEntrenamiento(nombre: "Cinta de correr", tipo: .cardio, sets: [SetEjercicio()])
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    ForEach(ejercicios.indices, id: \.self) { i in
                        EjercicioActivoView(ejercicio: $ejercicios[i])
                    }

                    Button("Finalizar Entrenamiento") {
                        // Aquí se puede añadir lógica para guardar los resultados
                        dismiss()
                    }
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.black)
                    .clipShape(Capsule())
                    .padding(.top, 30)
                }
                .padding()
            }
            .navigationTitle("Toca Entrenar")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
