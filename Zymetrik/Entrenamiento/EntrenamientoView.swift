import SwiftUI
import Supabase

struct EntrenamientoView: View {
    @EnvironmentObject var planStore: TrainingPlanStore
    @EnvironmentObject var subs: SubscriptionStore   // 👈 añade esto

    @State private var fechaSeleccionada: Date = Date()
    @State private var mostrarLista = false

    // Confirmación de eliminación
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
                CalendarView(
                    selectedDate: $fechaSeleccionada,
                    ejerciciosPorDia: convertKeysToDate(planStore),
                    onAdd: { mostrarLista = true }
                )

                // 👇 Tarjeta compacta (solo si NO es PRO)
                if !subs.isPro {
                    PlansMiniCard(onTap: goToTemplates)
                        .padding(.horizontal)
                        .padding(.top, 4)
                }

                if !ejerciciosDelDia.isEmpty {
                    listaEjercicios
                } else {
                    vacio
                }

                Spacer()

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
                            .padding(.bottom, 100)
                            .accessibilityLabel("Comenzar entrenamiento de hoy")
                    }
                }
            }
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
            .onAppear {
                planStore.refresh(day: fechaSeleccionada)
                planStore.preloadWeek(around: fechaSeleccionada)
            }
            .onChange(of: fechaSeleccionada) { _, newValue in
                planStore.refresh(day: newValue)
            }
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

    // MARK: - Navegación a Plantillas
    private func goToTemplates() {
        // TODO: abre tu PlantillasPROView o Paywall.
        // Ejemplo con un Router/sheet propio, o NavigationLink desde el tab contenedor.
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

// MARK: - Tarjeta compacta “Planes de entrenamiento”
private struct PlansMiniCard: View {
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(LinearGradient(colors: [.purple, .pink, .orange],
                                             startPoint: .topLeading,
                                             endPoint: .bottomTrailing)
                              .opacity(0.18))
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
