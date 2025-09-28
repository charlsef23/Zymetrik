import SwiftUI
import Supabase

struct EntrenamientoView: View {
    @EnvironmentObject var planStore: TrainingPlanStore
    @EnvironmentObject var subs: SubscriptionStore

    @State private var fechaSeleccionada: Date = Date()
    @State private var mostrarLista = false

    // Plantillas PRO
    @State private var mostrarPlantillas = false
    @State private var ejerciciosCatalogo: [Ejercicio] = []
    @State private var cargandoCatalogo = false

    // Confirmaciones / estados de acciones de rutina
    @State private var confirmCancel = false
    @State private var cancelInFlight = false

    @State private var confirmReplace = false
    @State private var replaceInFlight = false

    // Confirmación de eliminación individual
    @State private var ejercicioAEliminar: Ejercicio?
    @State private var mostrarConfirmacionEliminar = false

    // MARK: - Computados
    private var esHoy: Bool { Calendar.current.isDateInToday(fechaSeleccionada) }
    private var ejerciciosDelDia: [Ejercicio] { planStore.ejercicios(en: fechaSeleccionada) }

    private var alertMessage: String {
        if let ejercicio = ejercicioAEliminar {
            return "Vas a quitar “\(ejercicio.nombre)” de \(fechaSeleccionada.formatted(date: .abbreviated, time: .omitted))."
        } else {
            return "¿Seguro que quieres quitar este ejercicio?"
        }
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {

                // 📅 Calendario
                CalendarView(
                    selectedDate: $fechaSeleccionada,
                    ejerciciosPorDia: convertKeysToDate(planStore),
                    onAdd: { mostrarLista = true }
                )

                // 🔒/🔓 Tarjetas bajo calendario
                if !subs.isPro {
                    PlansMiniCard(onTap: { openTemplates(replaceCurrent: false) })
                        .padding(.horizontal)
                        .padding(.top, 4)
                } else {
                    ActiveRoutineManageCard(
                        routineName: RoutineTracker.shared.activePlanName ?? "Rutina PRO",
                        dateRange: RoutineTracker.shared.activeRange,
                        isCancelling: cancelInFlight,
                        onChange: { confirmReplace = true },        // ← reemplazar
                        onCancelConfirmed: { confirmCancel = true } // ← cancelar
                    )
                    .padding(.horizontal)
                    .padding(.top, 6)
                }

                // Lista o vacío
                if !ejerciciosDelDia.isEmpty {
                    listaEjercicios
                } else {
                    vacio
                }

                Spacer()

                // CTA entrenar abajo
                if esHoy, !ejerciciosDelDia.isEmpty {
                    NavigationLink(
                        destination: EntrenandoView(
                            ejercicios: ejerciciosDelDia,
                            fecha: fechaSeleccionada
                        )
                    ) {
                        Text("Entrenar ahora")
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal)
                            .padding(.bottom, 80)
                    }
                }
            }
            // Selección manual
            .sheet(isPresented: $mostrarLista) {
                ListaEjerciciosView(
                    fecha: fechaSeleccionada,
                    onGuardar: { ejercicios in
                        planStore.add(ejercicios: ejercicios, para: fechaSeleccionada)
                    },
                    isPresented: $mostrarLista
                )
                .environmentObject(planStore)
            }
            // Plantillas PRO
            .sheet(isPresented: $mostrarPlantillas) {
                NavigationStack {
                    if cargandoCatalogo {
                        ProgressView("Cargando ejercicios…").padding()
                    } else {
                        PlantillasPROView(ejerciciosCatalogo: ejerciciosCatalogo)
                            .environmentObject(planStore)
                            .environmentObject(subs)
                            .environmentObject(RoutineTracker.shared)
                    }
                }
            }
            // Confirmación de cancelar rutina
            .alert("Cancelar rutina", isPresented: $confirmCancel) {
                Button(cancelInFlight ? "Cancelando…" : "Cancelar rutina", role: .destructive) {
                    Task { await cancelActiveRoutine() }
                }.disabled(cancelInFlight)
                Button("Volver", role: .cancel) {}
            } message: {
                Text("Se eliminarán del calendario los entrenamientos futuros de esta rutina.")
            }
            // Confirmación de REEMPLAZAR (borrar futuros + abrir plantillas)
            .alert("Cambiar rutina", isPresented: $confirmReplace) {
                Button(replaceInFlight ? "Preparando…" : "Cambiar ahora", role: .destructive) {
                    Task { await replaceRoutineThenOpenTemplates() }
                }.disabled(replaceInFlight)
                Button("Volver", role: .cancel) {}
            } message: {
                Text("Esto borrará los entrenamientos futuros de tu rutina actual y te permitirá elegir una nueva.")
            }
            // Confirmación de quitar ejercicio individual
            .alert("Quitar ejercicio", isPresented: $mostrarConfirmacionEliminar) {
                Button("Eliminar", role: .destructive) {
                    if let ejercicio = ejercicioAEliminar {
                        planStore.remove(ejercicioID: ejercicio.id, de: fechaSeleccionada)
                        ejercicioAEliminar = nil
                    }
                }
                Button("Cancelar", role: .cancel) { ejercicioAEliminar = nil }
            } message: {
                Text(alertMessage)
            }
            .onAppear {
                planStore.refresh(day: fechaSeleccionada)
                planStore.preloadWeek(around: fechaSeleccionada)
            }
            .onChange(of: fechaSeleccionada) { _, newValue in
                planStore.refresh(day: newValue)
            }
            .navigationTitle("Entrenamiento")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Lista / vacío
    private var listaEjercicios: some View {
        List {
            ForEach(ejerciciosDelDia) { ejercicio in
                EjercicioResumenView(ejercicio: ejercicio)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            ejercicioAEliminar = ejercicio
                            mostrarConfirmacionEliminar = true
                        } label: {
                            Label { Text("Quitar") } icon: { Image(systemName: "trash") }
                        }
                    }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private var vacio: some View {
        HStack {
            Spacer()
            Text("No hay ejercicios para esta fecha")
                .foregroundColor(.secondary)
                .padding()
            Spacer()
        }
    }

    // MARK: - Flujo abrir Plantillas (con o sin reemplazo previo)
    private func openTemplates(replaceCurrent: Bool) {
        if replaceCurrent {
            confirmReplace = true
        } else {
            goToTemplates()
        }
    }

    private func goToTemplates() {
        mostrarPlantillas = true
        if ejerciciosCatalogo.isEmpty {
            cargandoCatalogo = true
            Task {
                defer { cargandoCatalogo = false }
                do {
                    let items = try await SupabaseService.shared.fetchEjerciciosConFavoritos()
                    await MainActor.run { ejerciciosCatalogo = items }
                } catch {
                    print("❌ Error cargando catálogo:", error)
                }
            }
        }
    }

    /// Borra futuros (y cancela rutina si aplica) y abre Plantillas
    private func replaceRoutineThenOpenTemplates() async {
        guard !replaceInFlight else { return }
        replaceInFlight = true
        defer { replaceInFlight = false }

        // 1) Borrar futuros (planes + rutina activa) con tu RPC
        do {
            _ = try await SupabaseService.shared.deleteFutureWorkouts()
        } catch {
            print("❌ Error limpiando futuros:", error)
            // aun así, intentamos abrir plantillas para no bloquear al usuario
        }

        // 2) Limpiar estado local de rutina
        RoutineTracker.shared.activePlanName = nil
        RoutineTracker.shared.activeRange = nil

        // 3) Refrescar calendario local
        planStore.preloadWeek(around: fechaSeleccionada)
        planStore.refresh(day: fechaSeleccionada)

        // 4) Abrir plantillas
        await MainActor.run {
            confirmReplace = false
            goToTemplates()
        }
    }

    // MARK: - Cancelar rutina activa (RPC)
    private func cancelActiveRoutine() async {
        guard !cancelInFlight else { return }
        cancelInFlight = true
        defer { cancelInFlight = false }

        do {
            try await SupabaseService.shared.cancelActiveRoutine()
        } catch {
            print("❌ RPC cancel:", error)
        }

        // Limpiar estado local + refrescar
        RoutineTracker.shared.activePlanName = nil
        RoutineTracker.shared.activeRange = nil
        planStore.preloadWeek(around: fechaSeleccionada)
        planStore.refresh(day: fechaSeleccionada)
    }

    // MARK: - Helper fechas
    private func convertKeysToDate(_ store: TrainingPlanStore) -> [Date: [Ejercicio]] {
        var out: [Date: [Ejercicio]] = [:]
        let df = DateFormatter()
        df.calendar = Calendar(identifier: .gregorian)
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = .current
        df.dateFormat = "yyyy-MM-dd"

        let cal = Calendar.current
        for (k, v) in store.ejerciciosPorDia {
            if let parsed = df.date(from: k) {
                let localStart = cal.startOfDay(for: parsed)
                out[localStart] = v
            }
        }
        return out
    }
}

// MARK: - Tarjeta compacta “Planes de entrenamiento” (para NO PRO)
private struct PlansMiniCard: View {
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(colors: [.purple, .pink, .orange],
                                           startPoint: .topLeading,
                                           endPoint: .bottomTrailing)
                            .opacity(0.18)
                        )
                        .frame(width: 44, height: 44)
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 18, weight: .bold))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Planes de entrenamiento")
                        .font(.subheadline).bold()
                    Text("Elige una rutina y añádela")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.secondarySystemBackground))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Tarjeta para PRO (Cambiar / Cancelar)
private struct ActiveRoutineManageCard: View {
    var routineName: String
    var dateRange: ClosedRange<Date>?
    var isCancelling: Bool
    var onChange: () -> Void
    var onCancelConfirmed: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(LinearGradient(colors: [.indigo, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 50, height: 50)
                    .shadow(color: .blue.opacity(0.25), radius: 8, y: 4)
                Image(systemName: "bolt.heart.fill")
                    .foregroundStyle(.white)
                    .font(.system(size: 22, weight: .bold))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(routineName)
                    .font(.subheadline.weight(.semibold))
                if let r = dateRange {
                    Text("\(r.lowerBound.formatted(date: .abbreviated, time: .omitted)) – \(r.upperBound.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Rutina activa")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                HStack(spacing: 8) {
                    Button {
                        onChange()          // ← ahora dispara confirmación de REEMPLAZO
                    } label: {
                        Label("Cambiar", systemImage: "arrow.triangle.2.circlepath")
                            .labelStyle(.titleAndIcon)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)

                    Button(role: .destructive) {
                        onCancelConfirmed() // ← dispara confirmación de CANCELACIÓN
                    } label: {
                        if isCancelling {
                            ProgressView()
                        } else {
                            Label("Cancelar", systemImage: "xmark.circle.fill")
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                .padding(.top, 2)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }
}
