import SwiftUI
import Supabase

struct ListaEjerciciosView: View {
    let fecha: Date
    var onGuardar: ([Ejercicio]) -> Void
    @Binding var isPresented: Bool

    @State private var ejercicios: [Ejercicio] = []
    @State private var tipoSeleccionado: String = "Gimnasio"
    @State private var filtroPartes: Set<String> = []      // Filtro por partes del cuerpo (categoria)
    @State private var seleccionados: Set<UUID> = []       // Persistente por día
    @State private var cargando = false

    // Añadimos "Favoritos"
    private let tipos = ["Gimnasio", "Cardio", "Funcional", "Favoritos"]
    @Namespace private var tipoAnimacion

    // Controla upserts para no spamear
    @State private var pendingUpsertTask: Task<Void, Never>? = nil

    // Partes disponibles según el tipo actual (y favoritos)
    var partesDisponibles: [String] {
        let base: [Ejercicio]
        if tipoSeleccionado == "Favoritos" {
            base = ejercicios.filter { $0.esFavorito }
        } else {
            base = ejercicios.filter { $0.tipo == tipoSeleccionado }
        }
        let set = Set(base.map { ($0.categoria.isEmpty ? "General" : $0.categoria) })
        return set.sorted()
    }

    // Agrupa por categoría con lógica de tipo y filtro de partes
    var ejerciciosFiltradosPorTipo: [String: [Ejercicio]] {
        var base: [Ejercicio]
        if tipoSeleccionado == "Favoritos" {
            base = ejercicios.filter { $0.esFavorito }
        } else {
            base = ejercicios.filter { $0.tipo == tipoSeleccionado }
        }
        if !filtroPartes.isEmpty {
            base = base.filter { filtroPartes.contains($0.categoria.isEmpty ? "General" : $0.categoria) }
        }
        return Dictionary(grouping: base) { $0.categoria.isEmpty ? "General" : $0.categoria }
    }

    // Recupera array de ejercicios desde el set seleccionado
    var ejerciciosSeleccionadosHoy: [Ejercicio] {
        ejercicios.filter { seleccionados.contains($0.id) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // Selector tipo
                    TipoSelectorView(
                        tipos: tipos,
                        tipoSeleccionado: $tipoSeleccionado,
                        tipoAnimacion: tipoAnimacion
                    )

                    // Chips de filtro por parte del cuerpo
                    if !partesDisponibles.isEmpty {
                        BodyPartFilterChips(
                            partesDisponibles: partesDisponibles,
                            seleccionadas: $filtroPartes
                        )
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    // Estado selección hoy
                    if !seleccionados.isEmpty {
                        HStack(spacing: 8) {
                            Image(systemName: "calendar.circle.fill")
                            Text("\(seleccionados.count) seleccionados hoy")
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                            Button(role: .destructive) {
                                seleccionados.removeAll()
                                persistPlanDebounced()
                            } label: {
                                Text("Quitar todos")
                            }
                            .font(.caption)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                        )
                        .padding(.horizontal)
                    }

                    // Lista
                    if cargando {
                        ProgressView("Cargando ejercicios...")
                            .frame(maxWidth: .infinity)
                            .padding(.top, 24)
                    } else {
                        EjerciciosAgrupadosView(
                            ejerciciosFiltradosPorTipo: ejerciciosFiltradosPorTipo,
                            tipoSeleccionado: tipoSeleccionado,
                            seleccionados: $seleccionados,
                            isFavorito: { id in
                                ejercicios.first(where: { $0.id == id })?.esFavorito ?? false
                            },
                            onToggleFavorito: { id in
                                toggleFavorito(ejercicioID: id)
                            },
                            onToggleSeleccion: { _ in
                                // Persistir cada toggle con pequeña espera
                                persistPlanDebounced()
                            }
                        )
                    }

                    Spacer(minLength: 8)
                }
                .padding(.bottom, 40)
            }
            .background(Color(.systemGroupedBackground))
            .ignoresSafeArea(edges: .bottom)
            .navigationTitle("Seleccionar ejercicios")
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
            }
            .onAppear {
                fetchEjercicios()
                preloadPlanDelDia()   // carga selección persistida
            }
            // ✅ Sin deprecation en iOS 17, compatible con iOS 16
            .onChangeCompat(of: fecha) { _, _ in
                preloadPlanDelDia()
            }
        }
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

    /// Carga los ejercicios ya guardados en `entrenamientos_planeados` para la fecha dada
    func preloadPlanDelDia() {
        Task {
            do {
                let guardados = try await SupabaseService.shared.fetchPlan(fecha: fecha)
                let ids = Set(guardados.map(\.id))
                await MainActor.run {
                    self.seleccionados = ids
                }
            } catch {
                // Si no existe fila aun, simplemente no selecciona nada
                print("ℹ️ Sin plan previo para el día o error:", error)
            }
        }
    }

    // MARK: - Persistencia inmediata con debounce
    /// Llama a `upsertPlan(fecha, ejercicios:)` con un pequeño debounce para agrupar toques rápidos
    func persistPlanDebounced() {
        pendingUpsertTask?.cancel()
        let selected = ejerciciosSeleccionadosHoy
        pendingUpsertTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 450_000_000) // ~0.45s
            do {
                try await SupabaseService.shared.upsertPlan(fecha: fecha, ejercicios: selected)
            } catch {
                print("❌ Error al upsert del plan:", error)
            }
        }
    }

    // MARK: - Helpers
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
}

// MARK: - Helper de compatibilidad iOS 16/17 para onChange
extension View {
    @ViewBuilder
    func onChangeCompat<T: Equatable>(
        of value: T,
        perform action: @escaping (_ oldValue: T, _ newValue: T) -> Void
    ) -> some View {
        if #available(iOS 17.0, *) {
            self.onChange(of: value) { oldValue, newValue in
                action(oldValue, newValue)
            }
        } else {
            self.onChange(of: value) { newValue in
                action(newValue, newValue) // iOS 16 no expone oldValue
            }
        }
    }
}
