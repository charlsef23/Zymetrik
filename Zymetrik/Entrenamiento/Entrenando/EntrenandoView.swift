import SwiftUI

struct EntrenandoView: View {
    let ejercicios: [Ejercicio]
    let fecha: Date

    @State private var setsPorEjercicio: [UUID: [SetRegistro]] = [:]
    @State private var tiempo: Int = 0
    @State private var timerActivo = false
    @State private var temporizador: Timer?

    @Environment(\.dismiss) var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                CronometroView(tiempo: $tiempo, timerActivo: $timerActivo, temporizador: $temporizador)

                ForEach(ejercicios) { ejercicio in
                    EjercicioRegistroView(
                        ejercicio: ejercicio,
                        sets: setsPorEjercicio[ejercicio.id] ?? [],
                        onAddSet: {
                            var nuevosSets = setsPorEjercicio[ejercicio.id] ?? []
                            let nuevoSet = SetRegistro(numero: nuevosSets.count + 1, repeticiones: 10, peso: 0)
                            nuevosSets.append(nuevoSet)
                            setsPorEjercicio[ejercicio.id] = nuevosSets
                        },
                        onUpdateSet: { index, repeticiones, peso in
                            setsPorEjercicio[ejercicio.id]?[index].repeticiones = repeticiones
                            setsPorEjercicio[ejercicio.id]?[index].peso = peso
                        }
                    )
                }

                Button(action: publicarEntrenamiento) {
                    Text("Publicar entrenamiento")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.black)
                        .cornerRadius(16)
                        .shadow(radius: 4)
                        .padding(.horizontal)
                        .padding(.top, 20)
                        .padding(.bottom, 40)
                }
            }
            .padding(.top)
        }
        .navigationTitle("Entrenando")
    }

    private func publicarEntrenamiento() {
        temporizador?.invalidate()
        timerActivo = false

        Task {
            do {
                try await SupabaseService.shared.publicarEntrenamiento(
                    fecha: fecha,
                    ejercicios: ejercicios,
                    setsPorEjercicio: setsPorEjercicio
                )
                dismiss()
            } catch {
                print("❌ Error al publicar entrenamiento:", error)
            }
        }
    }
}
