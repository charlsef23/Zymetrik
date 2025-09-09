import SwiftUI

// Devuelve o una rutina semanal o un conjunto de fechas exactas
enum RoutinePlanChoice {
    case weekdays(weekdays: Set<Int>, weeks: Int) // 1=Dom ... 7=Sáb
    case exactDates(dates: Set<Date>)             // Fechas exactas (sin recurrencia)
}

struct RoutineDaysSheet: View {
    var onConfirmChoice: (_ choice: RoutinePlanChoice) -> Void

    @Environment(\.dismiss) private var dismiss

    enum Mode: String, CaseIterable {
        case weekdays = "Por semana"
        case calendar = "Calendario"
    }
    @State private var mode: Mode = .weekdays

    // Weekdays
    @State private var selectedWeekdays: Set<Int> = [2] // Lunes
    @State private var weeks: Int = 8

    // Calendario Apple-style: múltiples fechas exactas
    @State private var selectedDates: Set<DateComponents> = []

    // Calendario empezando en lunes
    private var mondayFirstCalendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 2 // lunes
        return cal
    }

    private let days: [(name: String, num: Int)] = [
        ("L", 2), ("M", 3), ("X", 4), ("J", 5), ("V", 6), ("S", 7), ("D", 1)
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Picker("", selection: $mode) {
                    Text("Por semana").tag(Mode.weekdays)
                    Text("Calendario").tag(Mode.calendar)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                if mode == .weekdays {
                    Text("Elige los días de la semana")
                        .font(.title3.weight(.semibold))

                    // Chips de días
                    HStack(spacing: 10) {
                        ForEach(days, id: \.num) { item in
                            let isOn = selectedWeekdays.contains(item.num)
                            Button {
                                if isOn { selectedWeekdays.remove(item.num) } else { selectedWeekdays.insert(item.num) }
                            } label: {
                                Text(item.name)
                                    .font(.headline)
                                    .frame(width: 44, height: 44)
                                    .background(isOn ? Color.accentColor : Color(.systemGray6))
                                    .foregroundColor(isOn ? .white : .primary)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle().stroke(Color.gray.opacity(0.35), lineWidth: isOn ? 0 : 1)
                                    )
                            }
                            .accessibilityLabel(dayLongName(for: item.num))
                        }
                    }

                    VStack(spacing: 8) {
                        Text("Semanas a programar")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Stepper(value: $weeks, in: 1...24) {
                            Text("\(weeks) semanas")
                                .font(.headline)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.top, 8)

                } else {

                    // Apple-style calendar (multi selección)
                    MultiDatePicker(
                        "Fechas",
                        selection: $selectedDates
                    )
                    .environment(\.calendar, mondayFirstCalendar)
                    .padding(.horizontal)
                }

                Spacer(minLength: 8)

                Button {
                    switch mode {
                    case .weekdays:
                        guard !selectedWeekdays.isEmpty else { return }
                        onConfirmChoice(.weekdays(weekdays: selectedWeekdays, weeks: weeks))

                    case .calendar:
                        // Convierte DateComponents -> Date (normalizado a inicio de día)
                        let cal = mondayFirstCalendar
                        let datesArray: [Date] = selectedDates.compactMap { comps in
                            guard let d = cal.date(from: comps) else { return nil }
                            return cal.startOfDay(for: d)
                        }
                        let dates: Set<Date> = Set(datesArray) // <- tipo explícito para evitar ambigüedad
                        guard !dates.isEmpty else { return }
                        onConfirmChoice(.exactDates(dates: dates))
                    }
                } label: {
                    Text("Aplicar")
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                }
                .disabled(
                    (mode == .weekdays && selectedWeekdays.isEmpty) ||
                    (mode == .calendar && selectedDates.isEmpty)
                )
                .padding(.bottom, 16)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
            }
        }
    }

    private func dayLongName(for weekday: Int) -> String {
        // 1=Domingo ... 7=Sábado
        let names = ["Domingo","Lunes","Martes","Miércoles","Jueves","Viernes","Sábado"]
        return names[(weekday - 1 + 7) % 7]
    }
}
