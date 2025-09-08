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

    // Confirmación de publicación
    @State private var mostrarConfirmarPublicacion = false
    @State private var publicando = false

    @Environment(\.dismiss) var dismiss

    // ¿Hay contenido real para publicar?
    private var hayContenidoReal: Bool {
        for (_, sets) in setsPorEjercicio {
            if sets.contains(where: { $0.repeticiones > 0 || $0.peso > 0 }) { return true }
        }
        return false
    }

    // Resumen para el mensaje del alert
    private var resumenPublicacion: String {
        let (series, repes, kilos) = totales()
        let dur = formatearTiempo(segundos: tiempo)
        return "Vas a publicar \(series) series · \(repes) reps · \(Int(kilos)) kg · \(dur)"
    }

    var body: some View {
        VStack(spacing: 0) {
            // LISTA + BOTÓN (el botón está dentro del scroll, al final)
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(ejercicios) { ejercicio in
                        EjercicioRegistroView(
                            ejercicio: ejercicio,
                            sets: setsPorEjercicio[ejercicio.id] ?? [],
                            onAddSet: {
                                var nuevos = setsPorEjercicio[ejercicio.id] ?? []
                                let nuevo = SetRegistro(
                                    numero: (nuevos.last?.numero ?? 0) + 1,
                                    repeticiones: 10,
                                    peso: 0
                                )
                                nuevos.append(nuevo)
                                setsPorEjercicio[ejercicio.id] = nuevos
                            },
                            onUpdateSet: { index, rep, peso in
                                guard let lista = setsPorEjercicio[ejercicio.id],
                                      lista.indices.contains(index) else { return }
                                lista[index].repeticiones = rep
                                lista[index].peso = peso
                                setsPorEjercicio[ejercicio.id] = lista
                            },
                            onDeleteSet: { index in
                                guard var lista = setsPorEjercicio[ejercicio.id],
                                      lista.indices.contains(index) else { return }
                                lista.remove(at: index)
                                for (i, s) in lista.enumerated() { s.numero = i + 1 }
                                setsPorEjercicio[ejercicio.id] = lista
                            },
                            onDuplicateSet: { index in
                                guard var lista = setsPorEjercicio[ejercicio.id],
                                      lista.indices.contains(index) else { return }
                                let base = lista[index]
                                let dup = SetRegistro(
                                    numero: base.numero + 1,
                                    repeticiones: base.repeticiones,
                                    peso: base.peso
                                )
                                lista.insert(dup, at: index + 1)
                                for (i, s) in lista.enumerated() { s.numero = i + 1 }
                                setsPorEjercicio[ejercicio.id] = lista
                            }
                        )
                    }

                    // BOTÓN PUBLICAR — integrado en el scroll
                    Button {
                        if hayContenidoReal {
                            mostrarConfirmarPublicacion = true
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "paperplane.fill")
                                .font(.headline)
                            Text("Publicar entrenamiento")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(hayContenidoReal ? Color.black : Color.gray)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .padding(.horizontal)
                    }
                    .disabled(!hayContenidoReal || publicando)
                    .opacity(publicando ? 0.7 : 1)

                    // Espacio para respirar antes del cronómetro
                    Spacer(minLength: 12)
                }
                .padding(.top, 8)
            }

            // CRONÓMETRO (se mantiene fuera del scroll)
            CronometroView(tiempo: $tiempo, timerActivo: $timerActivo, temporizador: $temporizador)
        }
        .navigationBarHidden(true)
        .onAppear {
            // Inicializa estructura para cada ejercicio (si no existiera)
            if setsPorEjercicio.isEmpty {
                setsPorEjercicio = Dictionary(uniqueKeysWithValues: ejercicios.map { ($0.id, []) })
            }
        }
        .onDisappear {
            temporizador?.invalidate()
            timerActivo = false
        }
        // Alert de confirmación
        .alert("¿Publicar entrenamiento?", isPresented: $mostrarConfirmarPublicacion) {
            Button("Publicar", role: .destructive) {
                confirmarYPublicar()
            }
            Button("Seguir entrenando", role: .cancel) { }
        } message: {
            Text(resumenPublicacion)
        }
        // Logro a pantalla completa si aplica
        .fullScreenCover(isPresented: $mostrarLogro) {
            if let logro = logroDesbloqueado {
                LogroDesbloqueadoView(logro: logro) { mostrarLogro = false }
            }
        }
    }

    // MARK: - Publicación

    private func confirmarYPublicar() {
        temporizador?.invalidate()
        timerActivo = false
        publicando = true

        Task {
            do {
                try await SupabaseService.shared.publicarEntrenamiento(
                    fecha: fecha,
                    ejercicios: ejercicios,
                    setsPorEjercicio: setsPorEjercicio
                )

                // Analiza y posibles logros
                await SupabaseService.shared.analizarYDesbloquearLogros()

                let logros = try await SupabaseService.shared.fetchLogrosCompletos()
                if let nuevo = logros.first(where: { $0.desbloqueado && ($0.fecha?.isInLast(seconds: 8) ?? false) }) {
                    logroDesbloqueado = nuevo
                    mostrarLogro = true
                }

                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                dismiss()
            } catch {
                print("❌ Error al publicar entrenamiento:", error)
            }
            publicando = false
        }
    }

    // MARK: - Utilidades

    private func totales() -> (series: Int, repeticiones: Int, kilos: Double) {
        var series = 0
        var repes = 0
        var kilos: Double = 0
        for (_, sets) in setsPorEjercicio {
            for s in sets where (s.repeticiones > 0 || s.peso > 0) {
                series += 1
                repes += s.repeticiones
                kilos += s.peso
            }
        }
        return (series, repes, kilos)
    }

    private func formatearTiempo(segundos: Int) -> String {
        let horas = segundos / 3600
        let minutos = (segundos % 3600) / 60
        let segundosRestantes = segundos % 60
        return String(format: "%d:%02d:%02d", horas, minutos, segundosRestantes)
    }
}
