import SwiftUI

struct EntrenamientoView: View {
    @EnvironmentObject var planStore: TrainingPlanStore

    @State private var fechaSeleccionada: Date = Date()
    @State private var mostrarLista = false

    // Confirmación de eliminación
    @State private var ejercicioAEliminar: Ejercicio?
    @State private var mostrarConfirmacionEliminar = false

    // MARK: - Computados para aligerar
    private var esHoy: Bool {
        Calendar.current.isDateInToday(fechaSeleccionada)
    }
    private var ejerciciosDelDia: [Ejercicio] {
        planStore.ejercicios(en: fechaSeleccionada)
    }
    private var weekdayText: String {
        fechaSeleccionada.formatted(.dateTime.weekday(.wide)).capitalized
    }
    private var monthDayText: String {
        fechaSeleccionada.formatted(.dateTime.month(.wide).day())
    }
    private var yearText: String {
        fechaSeleccionada.formatted(.dateTime.year())
    }
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
                header

                CalendarView(
                    selectedDate: $fechaSeleccionada,
                    ejerciciosPorDia: convertKeysToDate(planStore)
                )

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
                            .padding()
                            .accessibilityLabel("Comenzar entrenamiento de hoy")
                    }
                }
            }
            .navigationBarHidden(true)
            .overlay(botonFlotanteAgregar)
            .sheet(isPresented: $mostrarLista) {
                ListaEjerciciosView(
                    fecha: fechaSeleccionada,
                    onGuardar: { ejercicios in
                        planStore.add(ejercicios: ejercicios, para: fechaSeleccionada)
                    },
                    isPresented: $mostrarLista
                )
                .environmentObject(planStore) // <- importante para refrescos tras rutinas
            }
            .onAppear {
                planStore.refresh(day: fechaSeleccionada)       // Refresco inicial del día visible
                planStore.preloadWeek(around: fechaSeleccionada) // Opcional: precargar semana
            }
            .onChange(of: fechaSeleccionada) { oldValue, newValue in
                planStore.refresh(day: newValue)
            }
            .alert("Quitar ejercicio", isPresented: $mostrarConfirmacionEliminar) {
                Button("Eliminar", role: .destructive) {
                    if let ejercicio = ejercicioAEliminar {
                        planStore.remove(ejercicioID: ejercicio.id, de: fechaSeleccionada)
                        ejercicioAEliminar = nil
                    }
                }
                Button("Cancelar", role: .cancel) {
                    ejercicioAEliminar = nil
                }
            } message: {
                Text(alertMessage)
            }
        }
    }

    // MARK: - Subvistas pequeñas
    private var header: some View {
        HStack {
            Text(weekdayText)
                .font(.title.bold())
            if esHoy {
                Circle().fill(Color.red).frame(width: 10, height: 10)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(monthDayText).font(.subheadline)
                Text(yearText).font(.subheadline)
            }
        }
        .padding(.horizontal)
    }

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
                            Label {
                                Text("Quitar")
                            } icon: {
                                Image(systemName: "trash")
                            }
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

    private var botonFlotanteAgregar: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: { mostrarLista = true }) {
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.foregroundPlus)
                        .frame(width: 56, height: 56)
                        .background(.backgroundPlus)
                        .clipShape(Circle())
                        .shadow(radius: 4)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 40)
            }
        }
    }

    // Convierte claves String -> Date para sombrear el calendario
    private func convertKeysToDate(_ store: TrainingPlanStore) -> [Date: [Ejercicio]] {
        var out: [Date: [Ejercicio]] = [:]

        // Parser de claves "yyyy-MM-dd" en ZONA LOCAL (coherente con TrainingPlanStore)
        let df = DateFormatter()
        df.calendar = Calendar(identifier: .gregorian)
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = .current                // 👈 LOCAL, no UTC
        df.dateFormat = "yyyy-MM-dd"

        let cal = Calendar.current            // 👈 también LOCAL

        for (k, v) in store.ejerciciosPorDia {
            if let parsed = df.date(from: k) {
                // Normaliza a 00:00 LOCAL para comparar celdas del calendario
                let localStart = cal.startOfDay(for: parsed)
                out[localStart] = v
            }
        }
        return out
    }
}
