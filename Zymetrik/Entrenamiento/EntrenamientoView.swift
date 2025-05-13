import SwiftUI

struct Ejercicio: Identifiable {
    let id = UUID()
    let nombre: String
    let series: Int
    let repeticiones: Int
    let peso: Int
}

struct Entrenamiento: Identifiable {
    let id = UUID()
    let nombre: String
    var ejercicios: [Ejercicio]
}

struct Day: Identifiable {
    let id = UUID()
    let date: Date
    var isToday: Bool
}

struct EntrenamientoView: View {
    @State private var days: [Day] = generateDays()
    @State private var selectedDate: Date = Calendar.current.startOfDay(for: Date())

    // Simulamos entrenamientos pasados
    @State private var entrenamientos: [Entrenamiento] = [
        Entrenamiento(nombre: "Pecho y tríceps", ejercicios: [
            Ejercicio(nombre: "Press banca", series: 4, repeticiones: 10, peso: 60),
            Ejercicio(nombre: "Fondos", series: 3, repeticiones: 12, peso: 0)
        ]),
        Entrenamiento(nombre: "Piernas", ejercicios: [
            Ejercicio(nombre: "Sentadillas", series: 5, repeticiones: 10, peso: 80)
        ])
    ]

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Calendario
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(days) { day in
                            let isSelected = Calendar.current.isDate(day.date, inSameDayAs: selectedDate)
                            let isToday = Calendar.current.isDateInToday(day.date)
                            let isPast = day.date < Calendar.current.startOfDay(for: Date())

                            VStack {
                                Text(shortDayString(from: day.date))
                                    .font(.caption)
                                    .foregroundColor(isSelected ? .white : (isPast ? .gray : .secondary))
                                Text(dayNumberString(from: day.date))
                                    .font(.headline)
                                    .fontWeight(isSelected ? .bold : .regular)
                                    .foregroundColor(isSelected ? .white : (isPast ? .gray : (isToday ? .black : .primary)))
                            }
                            .padding(10)
                            .background(Circle().fill(isSelected ? Color.black : (isToday ? Color.gray.opacity(0.2) : Color.clear)))
                            .onTapGesture {
                                selectedDate = Calendar.current.startOfDay(for: day.date)
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                ScrollView {
                    VStack(spacing: 24) {
                        ForEach(entrenamientos) { entrenamiento in
                            TarjetaEntrenamientoView(
                                entrenamiento: entrenamiento,
                                fecha: Calendar.current.isDateInToday(selectedDate) ? "Hoy" : fechaFormateada(selectedDate),
                                esHoy: Calendar.current.isDateInToday(selectedDate),
                                color: .purple
                            )
                        }
                    }
                }

                Spacer()
            }
            .padding(.top)
            .navigationTitle("Entreno")
        }
    }

    func fechaFormateada(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    func shortDayString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }

    func dayNumberString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    static func generateDays() -> [Day] {
        let calendar = Calendar.current
        let today = Date()
        return (0..<14).compactMap { offset in
            if let date = calendar.date(byAdding: .day, value: offset - 3, to: today) {
                return Day(date: calendar.startOfDay(for: date), isToday: calendar.isDateInToday(date))
            }
            return nil
        }
    }
}