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
    @State private var entrenoPublicado = false
    
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
                if RoutineTracker.shared.activePlanName == nil {
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
                    if entrenoPublicado {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.white)
                            Text("Entrenamiento finalizado")
                                .bold()
                                .foregroundStyle(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                        .padding(.bottom, 80)
                    } else {
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
                Text("Se eliminarán del calendario los entrenamientos desde hoy (incluido).")
            }
            // Confirmación de REEMPLAZAR (borrar desde hoy + abrir plantillas)
            .alert("Cambiar rutina", isPresented: $confirmReplace) {
                Button(replaceInFlight ? "Preparando…" : "Cambiar ahora", role: .destructive) {
                    Task { await replaceRoutineThenOpenTemplates() }
                }.disabled(replaceInFlight)
                Button("Volver", role: .cancel) {}
            } message: {
                Text("Esto borrará los entrenamientos desde hoy (incluido) y te permitirá elegir una nueva rutina.")
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
                refreshPublishedState()
            }
            .onChange(of: fechaSeleccionada) { _, newValue in
                planStore.refresh(day: newValue)
                refreshPublishedState()
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
    
    // MARK: - CAMBIO IMPORTANTE: Reemplazar rutina => borrar desde HOY + abrir plantillas
    /// Borra desde HOY (incluido) con el mismo RPC de Ajustes y luego abre Plantillas
    private func replaceRoutineThenOpenTemplates() async {
        guard !replaceInFlight else { return }
        replaceInFlight = true
        defer { replaceInFlight = false }
        
        // Cerrar el alert
        await MainActor.run { confirmReplace = false }
        
        // 1) Borrar planificaciones desde HOY (mismo RPC que Ajustes)
        await deletePlannedWorkoutsFromToday()
        
        // 2) Ajustar estado local de rutina si procede
        await MainActor.run {
            RoutineTracker.shared.activeRange = nil
            // Si quieres forzar que no aparezca como “activa” hasta seleccionar:
            // RoutineTracker.shared.activePlanName = nil
        }
        
        // 3) Abrir plantillas para seleccionar nueva rutina
        await MainActor.run { goToTemplates() }
    }
    
    // MARK: - Cancelar rutina activa (usa el mismo RPC que Ajustes y borra desde HOY)
    private func cancelActiveRoutine() async {
        guard !cancelInFlight else { return }
        cancelInFlight = true
        defer { cancelInFlight = false }
        
        // 1) Borrar planificaciones desde HOY (mismo RPC que SettingsView.deleteFutureWorkouts)
        await deletePlannedWorkoutsFromToday()
        
        // 2) (Opcional) Cancelar rutina activa en backend si tu modelo lo requiere
        do {
            try await SupabaseService.shared.cancelActiveRoutine()
        } catch {
            print("❌ RPC cancelActiveRoutine:", error)
        }
        
        // 3) Limpiar estado local de rutina
        await MainActor.run {
            RoutineTracker.shared.activePlanName = nil
            RoutineTracker.shared.activeRange = nil
            planStore.preloadWeek(around: Date())
            planStore.refresh(day: Date())
        }
    }
    
    // MARK: - Estado de publicación
    private func refreshPublishedState() {
        let selectedDate = fechaSeleccionada
        Task {
            do {
                let posts = try await SupabaseService.shared.fetchPostsDelUsuario()
                let cal = Calendar.current
                let published = posts.contains { cal.isDate($0.fecha, inSameDayAs: selectedDate) }
                await MainActor.run { entrenoPublicado = published }
            } catch {
                print("ℹ️ No se pudo comprobar publicación:", error)
                await MainActor.run { entrenoPublicado = false }
            }
        }
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
    
    // MARK: - 🔴 Borrado unificado desde HOY (mismo RPC que SettingsView)
    /// Llama al mismo RPC que `SettingsView.deleteFutureWorkouts()` y además limpia localmente desde HOY (incluido)
    private func deletePlannedWorkoutsFromToday() async {
        do {
            // ⬇️ MISMO RPC que usa SettingsView (backend)
            _ = try await SupabaseService.shared.deleteFutureWorkouts()
        } catch {
            print("❌ RPC deleteFutureWorkouts:", error)
        }
        // Limpieza local desde HOY (incluido), para coherencia inmediata en UI
        await MainActor.run {
            nukeDaysFrom(date: Date())
        }
    }
    
    /// Vacía COMPLETAMENTE los días >= `date` (incluida) sin iterar ejercicio a ejercicio.
    /// Esto evita problemas de IDs o desajustes horario (DST/UTC).
    @MainActor
    private func nukeDaysFrom(date: Date) {
        let cal = Calendar.current
        let startDay = cal.startOfDay(for: date)
        
        let df = DateFormatter()
        df.calendar = Calendar(identifier: .gregorian)
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = .current       // ⚠️ usa la zona local que usan tus claves
        df.dateFormat = "yyyy-MM-dd"
        
        var wipedKeys: [String] = []
        
        // 1) Recorremos claves (yyyy-MM-dd) y detectamos las >= startDay
        for (k, _) in planStore.ejerciciosPorDia {
            if let d = df.date(from: k) {
                let localStart = cal.startOfDay(for: d)
                if localStart >= startDay {
                    wipedKeys.append(k)
                }
            }
        }
        
        // 2) Vaciar directamente (más robusto que remove-by-id en bucle)
        for k in wipedKeys {
            planStore.ejerciciosPorDia[k] = []   // o quita la clave si prefieres: planStore.ejerciciosPorDia.removeValue(forKey: k)
        }
        
        // 3) Refrescos de UI/datos
        planStore.preloadWeek(around: startDay)
        planStore.refresh(day: startDay)
    }
    // MARK: - Tarjeta compacta “Planes de entrenamiento” (para NO PRO)
    private struct PlansMiniCard: View {
        var onTap: () -> Void
        
        var body: some View {
            Button(action: onTap) {
                HStack(spacing: 14) {
                    ZStack {
                        // Vibrant circular badge with glow
                        Circle()
                            .fill(
                                AngularGradient(
                                    gradient: Gradient(colors: [.purple, .pink, .orange, .yellow, .purple]),
                                    center: .center
                                )
                            )
                            .frame(width: 54, height: 54)
                            .overlay(
                                Circle()
                                    .stroke(.white.opacity(0.2), lineWidth: 1)
                            )
                            .shadow(color: .pink.opacity(0.25), radius: 10, y: 6)
                        
                        // New, more dynamic icon
                        Image(systemName: "dumbbell.fill")
                            .foregroundStyle(.white)
                            .font(.system(size: 22, weight: .black))
                            .shadow(color: .black.opacity(0.2), radius: 2, y: 1)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Planes de entrenamiento")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                        Text("Elige una rutina y añádela")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                            .truncationMode(.tail)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(14)
                .background(
                    // Card with subtle glass effect
                    ZStack {
                        // Vibrant backdrop
                        LinearGradient(
                            colors: [Color.purple.opacity(0.18), Color.pink.opacity(0.14), Color.orange.opacity(0.12)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        // Soft inner highlight
                        RoundedRectangle(cornerRadius: 18)
                            .fill(.white.opacity(0.06))
                            .blur(radius: 6)
                            .padding(-2)
                    }
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay(
                            // Subtle border
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .strokeBorder(.white.opacity(0.08), lineWidth: 1)
                        )
                )
                .contentShape(Rectangle())
                .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
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
            HStack(spacing: 14) {
                // Leading badge
                ZStack {
                    Circle()
                        .fill(
                            AngularGradient(
                                gradient: Gradient(colors: [.purple, .pink, .orange, .yellow, .purple]),
                                center: .center
                            )
                        )
                        .frame(width: 56, height: 56)
                        .overlay(Circle().stroke(.white.opacity(0.2), lineWidth: 1))
                        .shadow(color: .pink.opacity(0.25), radius: 10, y: 6)
                    Image(systemName: "bolt.heart.fill")
                        .foregroundStyle(.white)
                        .font(.system(size: 24, weight: .black))
                        .shadow(color: .black.opacity(0.2), radius: 2, y: 1)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(routineName)
                        .font(.subheadline.weight(.semibold))
                    if let r = dateRange {
                        HStack(spacing: 6) {
                            Image(systemName: "calendar")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("\(r.lowerBound.formatted(date: .abbreviated, time: .omitted)) – \(r.upperBound.formatted(date: .abbreviated, time: .omitted))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Text("Rutina activa")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack(spacing: 10) {
                        Button {
                            onChange()
                        } label: {
                            Label("Cambiar", systemImage: "arrow.triangle.2.circlepath")
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    LinearGradient(colors: [.purple, .pink, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
                                )
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                                .shadow(color: .pink.opacity(0.25), radius: 8, y: 4)
                        }
                        .buttonStyle(.plain)
                        
                        Button(role: .destructive) {
                            onCancelConfirmed()
                        } label: {
                            HStack(spacing: 6) {
                                if isCancelling { ProgressView().tint(.white) } else { Image(systemName: "xmark.circle.fill") }
                                Text(isCancelling ? "Cancelando…" : "Cancelar")
                                    .font(.caption.weight(.semibold))
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                Capsule().fill(Color.red.opacity(0.15))
                            )
                            .foregroundStyle(.red)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 2)
                }
                
                Spacer(minLength: 0)
            }
            .padding(14)
            .background(
                ZStack {
                    LinearGradient(
                        colors: [Color.purple.opacity(0.12), Color.pink.opacity(0.08), Color.orange.opacity(0.06)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    RoundedRectangle(cornerRadius: 18)
                        .fill(.white.opacity(0.06))
                        .blur(radius: 6)
                        .padding(-2)
                }
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(.white.opacity(0.08), lineWidth: 1)
                    )
            )
            .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
        }
    }
}
