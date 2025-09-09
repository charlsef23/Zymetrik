import SwiftUI
import Supabase

struct ListaEjerciciosView: View {
    let fecha: Date
    var onGuardar: ([Ejercicio]) -> Void
    @Binding var isPresented: Bool

    @State private var ejercicios: [Ejercicio] = []
    @State private var tipoSeleccionado: String = "Gimnasio"
    @State private var filtroPartes: Set<String> = []      // filtro por partes del cuerpo (categoria)
    @State private var seleccionados: Set<UUID> = []       // persistencia por día
    @State private var cargando = false

    // Rutinas / Fechas exactas
    @State private var mostrarRutinaSheet = false

    // Toast (usa tu extensión global ToastView.toast(_:text:))
    @State private var showToast = false
    @State private var toastText = "Listo ✅"

    private let tipos = ["Gimnasio", "Cardio", "Funcional", "Favoritos"]
    @Namespace private var tipoAnimacion
    @State private var pendingUpsertTask: Task<Void, Never>? = nil

    // Partes disponibles según el tipo actual
    var partesDisponibles: [String] {
        let base: [Ejercicio] = (tipoSeleccionado == "Favoritos")
        ? ejercicios.filter { $0.esFavorito }
        : ejercicios.filter { $0.tipo == tipoSeleccionado }

        let set = Set<String>(base.map { $0.categoria.isEmpty ? "General" : $0.categoria })
        return set.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    // Lista final: filtra por tipo + partes y ordena A→Z
    var ejerciciosFiltradosYOrdenados: [Ejercicio] {
        var base: [Ejercicio] = (tipoSeleccionado == "Favoritos")
        ? ejercicios.filter { $0.esFavorito }
        : ejercicios.filter { $0.tipo == tipoSeleccionado }

        if !filtroPartes.isEmpty {
            base = base.filter { filtroPartes.contains($0.categoria.isEmpty ? "General" : $0.categoria) }
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

                    // TIPOS (chips con iconos – Favoritos en amarillo, definido en TipoChipsBar.swift)
                    TipoChipsBar(
                        tipos: tipos,
                        seleccionado: $tipoSeleccionado,
                        namespace: tipoAnimacion
                    )

                    // PARTES DEL CUERPO (chips mejorados)
                    if !partesDisponibles.isEmpty {
                        PartesCuerpoChips(
                            partes: partesDisponibles,
                            seleccionadas: $filtroPartes
                        )
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    // Estado selección hoy
                    if !seleccionados.isEmpty {
                        SeleccionResumen(count: seleccionados.count) {
                            seleccionados.removeAll()
                            persistPlanDebounced()
                        }
                        .padding(.horizontal)
                    }

                    // Lista simple sin títulos por categoría (solo tarjetas)
                    if cargando {
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
                        onGuardar(elegidos)
                        isPresented = false
                    } label: {
                        Text("Añadir").fontWeight(.semibold)
                    }
                    .disabled(seleccionados.isEmpty)
                }
                // Botón Rutina / Fechas arriba
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
                fetchEjercicios()
                preloadPlanDelDia()
            }
            // Compatibilidad iOS 16/17
            .onChangeCompat(of: fecha) { _, _ in
                persistPlanDebounced()
                preloadPlanDelDia()
            }
        }
        // Hoja para elegir rutina semanal o fechas exactas (MultiDatePicker)
        .sheet(isPresented: $mostrarRutinaSheet) {
            RoutineDaysSheet { choice in
                let ejerciciosElegidos = ejerciciosSeleccionadosHoy
                guard !ejerciciosElegidos.isEmpty else { return }

                Task {
                    do {
                        switch choice {
                        case .weekdays(let selectedWeekdays, let weeksCount):
                            try await TrainingRoutineScheduler.scheduleRoutine(
                                startFrom: fecha,
                                weekdays: selectedWeekdays,
                                weeks: weeksCount,
                                ejercicios: ejerciciosElegidos
                            )
                            await MainActor.run {
                                toastText = "Aplicada rutina: \(weekdaySummary(selectedWeekdays)) · \(weeksCount) semanas ✅"
                            }

                        case .exactDates(let dates):
                            try await TrainingRoutineScheduler.scheduleOnExactDates(
                                dates: dates,
                                ejercicios: ejerciciosElegidos
                            )
                            let df = DateFormatter()
                            df.locale = Locale(identifier: "es_ES")
                            df.dateStyle = .medium
                            let resumen = dates.sorted().prefix(4).map { df.string(from: $0) }.joined(separator: ", ")
                            await MainActor.run {
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

    // MARK: - Data
    func fetchEjercicios() {
        Task {
            cargando = true
            defer { cargando = false }
            do {
                let items = try await SupabaseService.shared.fetchEjerciciosConFavoritos()
                await MainActor.run { self.ejercicios = items }
            } catch {
                print("❌ Error al cargar ejercicios:", error)
            }
        }
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
            } catch {
                print("❌ Error al upsert del plan:", error)
            }
        }
    }

    // MARK: - Favoritos
    func toggleFavorito(ejercicioID: UUID) {
        guard let idx = ejercicios.firstIndex(where: { $0.id == ejercicioID }) else { return }
        ejercicios[idx].esFavorito.toggle()
        let target = ejercicios[idx].esFavorito
        Task {
            do {
                try await SupabaseService.shared.setFavorito(ejercicioID: ejercicioID, favorito: target)
            } catch {
                await MainActor.run { ejercicios[idx].esFavorito.toggle() }
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
