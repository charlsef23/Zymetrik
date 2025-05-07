import SwiftUI
import SwiftData

struct CalendarioView: View {
    @Query private var sesiones: [WorkoutSession]
    @Environment(\.modelContext) private var context

    @Binding var fechaSeleccionada: Date

    @State private var mostrarFormulario = false
    @State private var sesionAEliminar: WorkoutSession?
    @State private var mostrarAlertaEliminar = false

    @State private var mensajeExito: String = ""
    @State private var mostrarMensajeExito: Bool = false

    private let calendar = Calendar(identifier: .gregorian)
    private let days = ["L", "M", "X", "J", "V", "S", "D"]

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text(currentMonthYear)
                    .font(.title2)
                    .bold()

                // Días de la semana
                HStack {
                    ForEach(days, id: \.self) { day in
                        Text(day)
                            .frame(maxWidth: .infinity)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }

                // Cuadrícula de días
                let daysInMonth = calendar.range(of: .day, in: .month, for: fechaSeleccionada)!
                let firstWeekday = (calendar.component(.weekday, from: firstOfMonth) + 5) % 7 // lunes = 0

                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 12) {
                    ForEach(0..<firstWeekday, id: \.self) { _ in
                        Text(" ").frame(height: 40)
                    }

                    ForEach(daysInMonth, id: \.self) { day in
                        let date = dateFor(day)
                        let hasWorkout = sesiones.contains { calendar.isDate($0.date, inSameDayAs: date) }
                        let isToday = calendar.isDateInToday(date)
                        let isSelected = calendar.isDate(date, inSameDayAs: fechaSeleccionada)

                        Button {
                            fechaSeleccionada = date
                        } label: {
                            VStack(spacing: 4) {
                                Text("\(day)")
                                    .fontWeight(isSelected ? .bold : .regular)
                                    .foregroundColor(isToday && !isSelected ? .red : .primary)

                                if hasWorkout {
                                    Circle()
                                        .fill(Color.blue)
                                        .frame(width: 6, height: 6)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(6)
                        }
                        .background(isSelected ? Color.blue.opacity(0.15) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }

                Divider()

                // Lista de entrenamientos
                List {
                    ForEach(sesiones.filter { calendar.isDate($0.date, inSameDayAs: fechaSeleccionada) }) { sesion in
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemBackground))
                                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)

                            NavigationLink(destination: DetalleSesionView(sesion: sesion)) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(sesion.title)
                                        .font(.headline)
                                        .foregroundColor(.primary)

                                    Text(formatearFechaCorta(sesion.date))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.vertical, 4)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                sesionAEliminar = sesion
                                mostrarAlertaEliminar = true
                            } label: {
                                Label("Eliminar", systemImage: "trash")
                            }
                        }
                    }

                    if sesiones.filter({ calendar.isDate($0.date, inSameDayAs: fechaSeleccionada) }).isEmpty {
                        Text("No hay entrenamientos para este día")
                            .foregroundColor(.gray)
                            .padding()
                    }
                }
                .listStyle(.plain)
            }
            .padding()
            .navigationTitle("Calendario")
            .sheet(isPresented: $mostrarFormulario) {
                AñadirEntrenamientoView(fecha: fechaSeleccionada)
            }
            .overlay(botonFlotante, alignment: .bottomTrailing)
            .alert("¿Eliminar entrenamiento?", isPresented: $mostrarAlertaEliminar, actions: {
                Button("Eliminar", role: .destructive) {
                    if let sesion = sesionAEliminar {
                        context.delete(sesion)
                        try? context.save()
                        mostrarMensaje("Entrenamiento eliminado")
                    }
                }
                Button("Cancelar", role: .cancel) { }
            }, message: {
                Text("Esta acción no se puede deshacer.")
            })
            .overlay(mensajeEmergente, alignment: .top)
            .animation(.easeInOut, value: mostrarMensajeExito)
        }
    }

    // MARK: - Helpers

    var firstOfMonth: Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: fechaSeleccionada))!
    }

    func dateFor(_ day: Int) -> Date {
        calendar.date(bySetting: .day, value: day, of: firstOfMonth)!
    }

    var currentMonthYear: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL yyyy"
        formatter.locale = Locale(identifier: "es_ES")
        return formatter.string(from: fechaSeleccionada).capitalized
    }

    func formatearFechaCorta(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "es_ES")
        return formatter.string(from: date)
    }

    func mostrarMensaje(_ texto: String) {
        mensajeExito = texto
        mostrarMensajeExito = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            mostrarMensajeExito = false
        }
    }

    var mensajeEmergente: some View {
        Group {
            if mostrarMensajeExito {
                Text(mensajeExito)
                    .padding()
                    .background(Color.green.opacity(0.95))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .shadow(radius: 10)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, 16)
            }
        }
    }

    var botonFlotante: some View {
        Button {
            mostrarFormulario = true
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)
                .padding()
                .background(Color.blue)
                .clipShape(Circle())
                .shadow(radius: 5)
        }
        .padding()
    }
}
