import SwiftUI
import Combine

struct EntrenandoView: View {
    let ejercicios: [Ejercicio]
    let fecha: Date

    @SceneStorage("training.draft.v1") private var draftData: Data?
    @State private var setsPorEjercicio: [UUID: [SetRegistro]] = [:]

    @State private var tiempo: Int = 0
    @State private var timerActivo = false
    @State private var temporizador: Timer?

    @State private var mostrandoPublicando = false
    @State private var mostrarLogro = false
    @State private var logroDesbloqueado: LogroConEstado?

    @Environment(\.dismiss) var dismiss

    private var hayContenidoReal: Bool {
        for (_, sets) in setsPorEjercicio {
            if sets.contains(where: { $0.repeticiones > 0 || $0.peso > 0 }) { return true }
        }
        return false
    }

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
                                    var nuevos = setsPorEjercicio[ejercicio.id] ?? []
                                    let nuevo = SetRegistro(numero: (nuevos.last?.numero ?? 0) + 1, repeticiones: 10, peso: 0)
                                    nuevos.append(nuevo)
                                    setsPorEjercicio[ejercicio.id] = nuevos
                                    persistDraft()
                                },
                                // onUpdateSet
                                onUpdateSet: { index, rep, peso in
                                    guard var lista = setsPorEjercicio[ejercicio.id], lista.indices.contains(index) else { return }
                                    lista[index].repeticiones = rep
                                    lista[index].peso = peso
                                    setsPorEjercicio[ejercicio.id] = lista
                                    persistDraft()
                                },

                                // onDeleteSet
                                onDeleteSet: { index in
                                    guard var lista = setsPorEjercicio[ejercicio.id], lista.indices.contains(index) else { return }
                                    lista.remove(at: index)
                                    for (i, s) in lista.enumerated() { s.numero = i + 1 }
                                    setsPorEjercicio[ejercicio.id] = lista
                                    persistDraft()
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
                    .foregroundStyle(.white)
                    .padding()
                    .background(hayContenidoReal ? Color.green : Color.gray)
                    .clipShape(Circle())
            }
            .padding()
            .disabled(!hayContenidoReal || mostrandoPublicando)
            .opacity(mostrandoPublicando ? 0.6 : 1)
            .accessibilityLabel("Publicar entrenamiento")
        }
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $mostrarLogro) {
            if let logro = logroDesbloqueado {
                LogroDesbloqueadoView(logro: logro) { mostrarLogro = false }
            }
        }
        .onAppear {
            // Carga draft si existe
            if let data = draftData,
               let restored = try? JSONDecoder().decode([UUID: [SetRegistroCodable]].self, from: data) {
                setsPorEjercicio = restored.mapValues { $0.map { $0.toModel() } }
            } else {
                // Arranca vacío (no forzamos sets iniciales)
                setsPorEjercicio = Dictionary(uniqueKeysWithValues: ejercicios.map { ($0.id, []) })
            }
        }
        .onDisappear {
            temporizador?.invalidate()
            timerActivo = false
        }
    }

    private func publicarEntrenamiento() {
        guard hayContenidoReal else { return }

        temporizador?.invalidate()
        timerActivo = false
        mostrandoPublicando = true

        Task {
            do {
                try await SupabaseService.shared.publicarEntrenamiento(
                    fecha: fecha,
                    ejercicios: ejercicios,
                    setsPorEjercicio: setsPorEjercicio
                )

                await SupabaseService.shared.analizarYDesbloquearLogros()

                // Revisa si hay logro muy reciente (últimos 8s)
                let logros = try await SupabaseService.shared.fetchLogrosCompletos()
                if let nuevo = logros.first(where: { $0.desbloqueado && ($0.fecha?.isInLast(seconds: 8) ?? false) }) {
                    logroDesbloqueado = nuevo
                    mostrarLogro = true
                }

                // Limpia draft y cierra
                draftData = nil
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                dismiss()
            } catch {
                print("❌ Error al publicar entrenamiento:", error)
            }
            mostrandoPublicando = false
        }
    }

    // MARK: - Draft persistence
    private func persistDraft() {
        let codable: [UUID: [SetRegistroCodable]] = setsPorEjercicio.mapValues { $0.map(SetRegistroCodable.init) }
        if let data = try? JSONEncoder().encode(codable) {
            draftData = data
        }
    }
}

// Wrapper codable para SetRegistro (que es class)
private struct SetRegistroCodable: Codable {
    var id: UUID
    var numero: Int
    var repeticiones: Int
    var peso: Double

    init(_ s: SetRegistro) {
        id = s.id; numero = s.numero; repeticiones = s.repeticiones; peso = s.peso
    }
    func toModel() -> SetRegistro { SetRegistro(id: id, numero: numero, repeticiones: repeticiones, peso: peso) }
}
