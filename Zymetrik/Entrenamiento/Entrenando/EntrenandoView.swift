import SwiftUI

struct EntrenandoView: View {
    let ejercicios: [Ejercicio]
    let fecha: Date

    @State private var setsPorEjercicio: [UUID: [SetRegistro]] = [:]
    @State private var tiempo: Int = 0
    @State private var timerActivo = false
    @State private var temporizador: Timer?

    @State private var mostrarLogro = false
    @State private var logroDesbloqueado: LogroConEstado?

    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 16) {
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
                        Spacer(minLength: 120)
                    }
                    .padding(.top, 60)
                }

                CronometroView(tiempo: $tiempo, timerActivo: $timerActivo, temporizador: $temporizador)
            }

            Button(action: publicarEntrenamiento) {
                Image(systemName: "checkmark")
                    .font(.title)
                    .foregroundColor(.black)
                    .padding()
                    .background(Color.green.opacity(0.3))
                    .clipShape(Circle())
            }
            .padding()
        }
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $mostrarLogro) {
            if let logro = logroDesbloqueado {
                LogroDesbloqueadoView(logro: logro) {
                    mostrarLogro = false
                }
            }
        }
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

                await SupabaseService.shared.analizarYDesbloquearLogros()

                // Comprobar si se ha desbloqueado alguno recientemente
                let logros = try await SupabaseService.shared.fetchLogrosCompletos()
                if let nuevo = logros.filter({ $0.desbloqueado && ($0.fecha?.isInLast(seconds: 5) ?? false) }).first {
                    logroDesbloqueado = nuevo
                    mostrarLogro = true
                }

                dismiss()
            } catch {
                print("❌ Error al publicar entrenamiento:", error)
            }
        }
    }
}
