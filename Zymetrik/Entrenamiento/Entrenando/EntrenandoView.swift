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
                        registroView(for: ejercicio)
                    }

                    // BOTÓN PUBLICAR — integrado en el scroll
                    Button {
                        if hayContenidoReal { mostrarConfirmarPublicacion = true }
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
            Button("Publicar", role: .destructive) { confirmarYPublicar() }
            Button("Seguir entrenando", role: .cancel) { }
        } message: {
            Text(resumenPublicacion)
        }
        // Logro a pantalla completa si aplica
        .fullScreenCover(isPresented: $mostrarLogro) {
            if let logro = logroDesbloqueado {
                LogroDesbloqueadoView(logro: logro) {
                    // Cierra overlay y vista al continuar
                    mostrarLogro = false
                    dismiss()
                }
            }
        }
    }

    // MARK: - Subvistas

    /// Extrae el contenido de cada ejercicio para aliviar al compilador.
    private func registroView(for ejercicio: Ejercicio) -> some View {
        EjercicioRegistroView(
            ejercicio: ejercicio,
            sets: setsPorEjercicio[ejercicio.id] ?? [],
            onAddSet: {
                withSets(of: ejercicio.id) { lista in
                    let siguiente = (lista.last?.numero ?? 0) + 1
                    lista.append(SetRegistro(numero: siguiente, repeticiones: 10, peso: 0))
                }
            },
            onUpdateSet: { index, rep, peso in
                withSets(of: ejercicio.id) { lista in
                    guard lista.indices.contains(index) else { return }
                    lista[index].repeticiones = rep
                    lista[index].peso = peso
                }
            },
            onDeleteSet: { index in
                withSets(of: ejercicio.id) { lista in
                    guard lista.indices.contains(index) else { return }
                    lista.remove(at: index)
                    reindex(&lista)
                }
            },
            onDuplicateSet: { index in
                withSets(of: ejercicio.id) { lista in
                    guard lista.indices.contains(index) else { return }
                    let base = lista[index]
                    let dup = SetRegistro(
                        numero: base.numero + 1,
                        repeticiones: base.repeticiones,
                        peso: base.peso
                    )
                    lista.insert(dup, at: index + 1)
                    reindex(&lista)
                }
            }
        )
    }

    // MARK: - Publicación

    private func confirmarYPublicar() {
        temporizador?.invalidate()
        timerActivo = false
        publicando = true

        Task {
            do {
                // 1) Publicar el entrenamiento
                try await SupabaseService.shared.publicarEntrenamiento(
                    fecha: fecha,
                    ejercicios: ejercicios,
                    setsPorEjercicio: setsPorEjercicio
                )

                // 2) Premiar desde servidor (sincronizado por usuario)
                let nuevos = await SupabaseService.shared.awardAchievementsRPC()

                if !nuevos.isEmpty {
                    // 3) Cargar catálogo con estado y mostrar overlay del primero
                    let logros = try await SupabaseService.shared.fetchLogrosCompletos()
                    if let primeroID = nuevos.first,
                       let modelo = logros.first(where: { $0.id == primeroID }) {
                        await MainActor.run {
                            logroDesbloqueado = modelo
                            mostrarLogro = true
                            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                        }
                        publicando = false
                        // Importante: no hacemos dismiss aquí; se hará al cerrar el overlay
                        return
                    }
                }

                // 4) Si no hay logros nuevos, cerrar normalmente
                await MainActor.run {
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                    dismiss()
                }
            } catch {
                print("❌ Error al publicar entrenamiento:", error)
            }
            publicando = false
        }
    }

    // MARK: - Helpers de sets

    /// Obtiene y muta los sets de un ejercicio, reasignando al diccionario.
    private func withSets(of ejercicioID: UUID, mutate: (inout [SetRegistro]) -> Void) {
        var copia = setsPorEjercicio[ejercicioID] ?? []
        mutate(&copia)
        setsPorEjercicio[ejercicioID] = copia
    }

    /// Reindexa el campo `numero` de los sets tras insertar/borrar.
    private func reindex(_ lista: inout [SetRegistro]) {
        for i in lista.indices {
            lista[i].numero = i + 1
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
