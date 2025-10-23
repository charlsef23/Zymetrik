import SwiftUI
import Supabase
import Combine

struct ListaEjerciciosView: View {
    let fecha: Date
    var onGuardar: ([Ejercicio]) -> Void
    @Binding var isPresented: Bool

    init(
        fecha: Date,
        onGuardar: @escaping ([Ejercicio]) -> Void,
        isPresented: Binding<Bool>,
        exercisesStore: ExercisesStore = ExercisesStore.shared
    ) {
        self.fecha = fecha
        self.onGuardar = onGuardar
        self._isPresented = isPresented
        self._exercisesStore = ObservedObject(initialValue: exercisesStore)
    }

    @EnvironmentObject var planStore: TrainingPlanStore   // 👈 NUEVO
    @ObservedObject var exercisesStore: ExercisesStore // Preloaded exercises + image cache

    private var ejercicios: [Ejercicio] { exercisesStore.ejercicios }
    @State private var tipoSeleccionado: String = "Fuerza"
    @State private var filtroPartes: Set<String> = []      // categoría
    @State private var filtroSubtipos: Set<String> = []    // subtipo
    @State private var soloFavoritos: Bool = false
    @State private var seleccionados: Set<UUID> = []       // persistencia por día

    // Rutinas / Fechas exactas
    @State private var mostrarRutinaSheet = false

    // Toast
    @State private var showToast = false
    @State private var toastText = "Listo ✅"

    private let tipos = ["Fuerza"]
    @Namespace private var tipoAnimacion
    @State private var pendingUpsertTask: Task<Void, Never>? = nil

    // Partes disponibles según tipo y favorito
    var partesDisponibles: [String] {
        let base: [Ejercicio] = ejercicios
            .filter { $0.tipo == tipoSeleccionado }
            .filter { !soloFavoritos || $0.esFavorito }
        let set = Set<String>(base.map { $0.categoria.isEmpty ? "General" : $0.categoria })
        return set.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    // Subtipos disponibles según tipo y favorito
    var subtiposDisponibles: [String] {
        let base: [Ejercicio] = ejercicios
            .filter { $0.tipo == tipoSeleccionado }
            .filter { !soloFavoritos || $0.esFavorito }
        let set = Set<String>(base.compactMap { e in
            guard let s = e.subtipo?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty else { return nil }
            return s
        })
        return set.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    // Lista final: respeta tipo + favoritos + categoría + subtipo
    var ejerciciosFiltradosYOrdenados: [Ejercicio] {
        var base: [Ejercicio] = ejercicios
            .filter { $0.tipo == tipoSeleccionado }
            .filter { !soloFavoritos || $0.esFavorito }

        if !filtroPartes.isEmpty {
            base = base.filter { filtroPartes.contains($0.categoria.isEmpty ? "General" : $0.categoria) }
        }
        if !filtroSubtipos.isEmpty {
            base = base.filter { e in
                guard let st = e.subtipo, !st.isEmpty else { return false }
                return filtroSubtipos.contains(st)
            }
        }
        return base.sorted { $0.nombre.localizedCaseInsensitiveCompare($1.nombre) == .orderedAscending }
    }

    var ejerciciosSeleccionadosHoy: [Ejercicio] {
        ejercicios.filter { seleccionados.contains($0.id) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {

                    // PANEL DE FILTROS (incluye Favoritos)
                    FilterPanel(
                        tipoSeleccionado: $tipoSeleccionado,
                        filtroCategorias: $filtroPartes,
                        filtroSubtipos: $filtroSubtipos,
                        soloFavoritos: $soloFavoritos,
                        tipos: tipos,
                        categoriasDisponibles: partesDisponibles,
                        subtiposDisponibles: subtiposDisponibles
                    )
                    .padding(.horizontal)

                    // Estado selección hoy
                    if !seleccionados.isEmpty {
                        SeleccionResumen(count: seleccionados.count) {
                            seleccionados.removeAll()
                            persistPlanDebounced()
                        }
                        .padding(.horizontal)
                    }

                    // Lista
                    if ejercicios.isEmpty && exercisesStore.isPreloading {
                        ProgressView("Cargando ejercicios...")
                            .frame(maxWidth: .infinity)
                            .padding(.top, 24)
                    } else {
                        LazyVStack(spacing: 14) {
                            ForEach(ejerciciosFiltradosYOrdenados) { ejercicio in
                                EjercicioCardView(
                                    ejercicio: ejercicio,
                                    seleccionado: seleccionados.contains(ejercicio.id),
                                    esFavorito: ejercicio.esFavorito,
                                    onToggleFavorito: { toggleFavorito(ejercicioID: ejercicio.id) }
                                )
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    if seleccionados.contains(ejercicio.id) {
                                        seleccionados.remove(ejercicio.id)
                                    } else {
                                        seleccionados.insert(ejercicio.id)
                                    }
                                    persistPlanDebounced()
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 4)
                    }

                    Spacer(minLength: 8)
                }
                .padding(.bottom, 40)
            }
            .background(Color(.systemGroupedBackground))
            .ignoresSafeArea(edges: .bottom)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        let elegidos = ejerciciosSeleccionadosHoy
                        guard !elegidos.isEmpty else { return }
                        onGuardar(elegidos)   // merge + persist desde EntrenamientoView
                        isPresented = false
                    } label: {
                        Text("Añadir").fontWeight(.semibold)
                    }
                    .disabled(seleccionados.isEmpty)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        mostrarRutinaSheet = true
                    } label: {
                        Label("Rutina / Fechas", systemImage: "calendar.badge.plus")
                    }
                    .disabled(seleccionados.isEmpty)
                }
            }
            .onAppear {
                exercisesStore.ensurePreloaded()
                preloadPlanDelDia()
            }
            // Recalcular plan al cambiar de fecha
            .onChangeCompat(of: fecha) { _, _ in
                persistPlanDebounced()
                preloadPlanDelDia()
            }
            // Reset de filtros al cambiar Tipo / Favoritos
            .onChangeCompat(of: tipoSeleccionado) { _, _ in
                withAnimation { filtroPartes.removeAll(); filtroSubtipos.removeAll() }
            }
            .onChangeCompat(of: soloFavoritos) { _, _ in
                withAnimation { filtroPartes.removeAll(); filtroSubtipos.removeAll() }
            }
        }
        // Hoja de rutina
        .sheet(isPresented: $mostrarRutinaSheet) {
            RoutineDaysSheet { choice in
                let ejerciciosElegidos = ejerciciosSeleccionadosHoy
                guard !ejerciciosElegidos.isEmpty else { return }

                Task {
                    do {
                        switch choice {
                        case .weekdays(let selectedWeekdays, let weeksCount):
                            let affected = try await TrainingRoutineScheduler.scheduleRoutine(
                                startFrom: fecha,
                                weekdays: selectedWeekdays,
                                weeks: weeksCount,
                                ejercicios: ejerciciosElegidos
                            )
                            await MainActor.run {
                                planStore.refresh(days: affected)   // 👈 refresca días afectados
                                toastText = "Aplicada rutina: \(weekdaySummary(selectedWeekdays)) · \(weeksCount) semanas ✅"
                            }
                        case .exactDates(let dates):
                            let affected = try await TrainingRoutineScheduler.scheduleOnExactDates(
                                dates: dates,
                                ejercicios: ejerciciosElegidos
                            )
                            let df = DateFormatter()
                            df.locale = Locale(identifier: "es_ES")
                            df.dateStyle = .medium
                            let resumen = dates.sorted().prefix(4).map { df.string(from: $0) }.joined(separator: ", ")
                            await MainActor.run {
                                planStore.refresh(days: affected)   // 👈 refresca días afectados
                                toastText = dates.count > 4
                                    ? "Aplicado en \(dates.count) fechas: \(resumen)…"
                                    : "Aplicado en: \(resumen)"
                            }
                        }
                        await MainActor.run {
                            showToast = true
                            mostrarRutinaSheet = false
                            isPresented = false
                        }
                    } catch {
                        print("❌ Error programando:", error)
                    }
                }
            }
        }
        .toast($showToast, text: toastText)
    }

    func preloadPlanDelDia() {
        Task {
            do {
                let guardados = try await SupabaseService.shared.fetchPlan(fecha: fecha)
                let ids = Set(guardados.map(\.id))
                await MainActor.run { self.seleccionados = ids }
            } catch {
                print("ℹ️ Sin plan previo para el día o error:", error)
            }
        }
    }

    // MARK: - Persistencia (debounce)
    func persistPlanDebounced() {
        pendingUpsertTask?.cancel()
        let selected = ejerciciosSeleccionadosHoy
        pendingUpsertTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 450_000_000)
            do {
                try await SupabaseService.shared.upsertPlan(fecha: fecha, ejercicios: selected)
                // Mantén el store consistente para el día actual:
                planStore.set(ejercicios: selected, para: fecha)
            } catch {
                print("❌ Error al upsert del plan:", error)
            }
        }
    }

    // MARK: - Favoritos
    func toggleFavorito(ejercicioID: UUID) {
        guard let idx = exercisesStore.ejercicios.firstIndex(where: { $0.id == ejercicioID }) else { return }
        // Optimistic update
        let newValue = !exercisesStore.ejercicios[idx].esFavorito
        exercisesStore.ejercicios[idx].esFavorito = newValue
        Task {
            do {
                try await SupabaseService.shared.setFavorito(ejercicioID: ejercicioID, favorito: newValue)
            } catch {
                await MainActor.run {
                    exercisesStore.ejercicios[idx].esFavorito.toggle()
                }
                print("❌ Error al togglear favorito:", error)
            }
        }
    }

    // MARK: - Summaries
    private func weekdaySummary(_ set: Set<Int>) -> String {
        // 1=Dom...7=Sáb
        let order: [Int] = [2,3,4,5,6,7,1] // L M X J V S D
        let map: [Int:String] = [1:"D",2:"L",3:"M",4:"X",5:"J",6:"V",7:"S"]
        return order.filter { set.contains($0) }.compactMap { map[$0] }.joined(separator: ", ")
    }
}

// MARK: - Helper iOS 16/17 para onChange
extension View {
    @ViewBuilder
    func onChangeCompat<T: Equatable>(
        of value: T,
        perform action: @escaping (_ oldValue: T, _ newValue: T) -> Void
    ) -> some View {
        if #available(iOS 17.0, *) {
            self.onChange(of: value) { oldValue, newValue in action(oldValue, newValue) }
        } else {
            self.onChange(of: value) { newValue in action(newValue, newValue) }
        }
    }
}
