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

    // Feedback háptico ligero
    @State private var haptics = UISelectionFeedbackGenerator()

    // Calendario empezando en lunes
    private var mondayFirstCalendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 2 // lunes
        return cal
    }

    private let days: Array<(name: String, long: String, num: Int)> = [
        ("L", "Lunes", 2), ("M", "Martes", 3), ("X", "Miércoles", 4), ("J", "Jueves", 5), ("V", "Viernes", 6), ("S", "Sábado", 7), ("D", "Domingo", 1)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Encabezado y modo
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Planifica tu rutina")
                            .font(.title2.weight(.semibold))
                        Text("Elige por días de semana o por fechas exactas.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)

                    Picker("", selection: $mode) {
                        Text("Por semana").tag(Mode.weekdays)
                        Text("Calendario").tag(Mode.calendar)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    if mode == .weekdays {
                        Group { weekdaysSection }
                    } else {
                        Group { calendarSection }
                    }

                    Spacer(minLength: 8)

                    confirmButton
                        .padding(.bottom, 8)
                }
                .padding(.top, 12)
            }
            .background(.thinMaterial)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .principal) {
                    Text("Plan de entrenamiento")
                        .font(.headline)
                }
            }
        }
        .onAppear { haptics.prepare() }
    }

    // MARK: - Secciones

    private var weekdaysSection: some View {
        VStack(spacing: 14) {
            // Tarjeta de días
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Días de la semana", systemImage: "calendar.badge.clock")
                        .font(.headline)
                    Spacer()
                    Button {
                        selectedWeekdays = []
                    } label: {
                        Label("Limpiar", systemImage: "xmark.circle")
                            .labelStyle(.iconOnly)
                    }
                    .buttonStyle(.borderless)
                    .tint(.secondary)
                    .accessibilityLabel("Limpiar días seleccionados")
                }

                // Chips de días
                HStack(spacing: 10) {
                    ForEach(days, id: \.num) { item in
                        let isOn = selectedWeekdays.contains(item.num)
                        WeekdayChip(item: item, isOn: isOn) {
                            toggleWeekday(item.num)
                        }
                    }
                }
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .padding(.horizontal)

            // Tarjeta de semanas
            VStack(alignment: .leading, spacing: 12) {
                Label("Semanas a programar", systemImage: "repeat")
                    .font(.headline)
                HStack(alignment: .center, spacing: 12) {
                    let binding = Binding<Double>(
                        get: { Double(weeks) },
                        set: { weeks = Int($0.rounded()) }
                    )
                    Slider(value: binding, in: 1...24, step: 1)
                        .tint(.accentColor)

                    Stepper(value: $weeks, in: 1...24) {
                        Text("\(weeks)")
                            .font(.headline.monospacedDigit())
                            .frame(minWidth: 36)
                    }
                    .labelsHidden()
                }
                Text("Se planificarán \(weeks) semana\(weeks == 1 ? "" : "s").")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .padding(.horizontal)
        }
    }

    private var calendarSection: some View {
        VStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Selecciona fechas", systemImage: "calendar")
                        .font(.headline)
                    Spacer()
                    Button {
                        selectedDates.removeAll()
                    } label: {
                        Label("Limpiar", systemImage: "xmark.circle")
                            .labelStyle(.iconOnly)
                    }
                    .buttonStyle(.borderless)
                    .tint(.secondary)
                    .accessibilityLabel("Limpiar fechas seleccionadas")
                }

                MultiDatePicker(
                    "Fechas",
                    selection: $selectedDates
                )
                .environment(\.calendar, mondayFirstCalendar)
                .padding(.top, 4)

                if !selectedDates.isEmpty {
                    Divider()
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Resumen")
                            .font(.subheadline.weight(.semibold))
                        Text(calendarSummary)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .padding(.horizontal)
        }
    }

    private var confirmButton: some View {
        Button {
            switch mode {
            case .weekdays:
                guard !selectedWeekdays.isEmpty else { return }
                let dates = generateDatesForWeekdays(weekdays: selectedWeekdays, weeks: weeks)
                guard !dates.isEmpty else { return }
                onConfirmChoice(.exactDates(dates: dates))
            case .calendar:
                // Convierte DateComponents -> Date (normalizado a inicio de día)
                let cal = mondayFirstCalendar
                let datesArray: [Date] = selectedDates.compactMap { comps in
                    guard let d = cal.date(from: comps) else { return nil }
                    return cal.startOfDay(for: d)
                }
                let dates: Set<Date> = Set(datesArray)
                guard !dates.isEmpty else { return }
                onConfirmChoice(.exactDates(dates: dates))
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                Text("Aplicar")
                    .bold()
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill((isApplyEnabled ? Color.accentColor : Color.gray.opacity(0.3)))
            )
            .foregroundStyle(.white)
            .padding(.horizontal)
        }
        .disabled(!isApplyEnabled)
        .animation(.spring(duration: 0.25), value: isApplyEnabled)
        .sensoryFeedback(.selection, trigger: isApplyEnabled)
    }

    private var isApplyEnabled: Bool {
        (mode == .weekdays && !selectedWeekdays.isEmpty) ||
        (mode == .calendar && !selectedDates.isEmpty)
    }

    private var calendarSummary: String {
        let cal = mondayFirstCalendar
        let formatter = DateFormatter()
        formatter.calendar = cal
        formatter.locale = Locale.current
        formatter.dateStyle = .medium
        let dates: [Date] = selectedDates.compactMap { cal.date(from: $0) }.map { cal.startOfDay(for: $0) }
        let unique = Array(Set(dates)).sorted()
        if unique.isEmpty { return "Sin fechas" }
        if unique.count <= 3 {
            return unique.map { formatter.string(from: $0) }.joined(separator: ", ")
        }
        let first = unique.first!, last = unique.last!
        return "\(unique.count) fechas entre \(formatter.string(from: first)) y \(formatter.string(from: last))"
    }

    // MARK: - Helpers

    private func toggleWeekday(_ num: Int) {
        if selectedWeekdays.contains(num) {
            selectedWeekdays.remove(num)
        } else {
            selectedWeekdays.insert(num)
        }
        haptics.selectionChanged()
    }

    private func dayLongName(for weekday: Int) -> String {
        // 1=Domingo ... 7=Sábado
        let names = ["Domingo","Lunes","Martes","Miércoles","Jueves","Viernes","Sábado"]
        return names[(weekday - 1 + 7) % 7]
    }

    private func generateDatesForWeekdays(weekdays: Set<Int>, weeks: Int) -> Set<Date> {
        let cal = mondayFirstCalendar
        let today = cal.startOfDay(for: Date())
        let todayWeekday = cal.component(.weekday, from: today)

        var results: [Date] = []

        // Include today only if today's weekday is selected
        if weekdays.contains(todayWeekday) {
            results.append(today)
        }

        let orderedDays = weekdays.sorted { a, b in
            let da = (a - todayWeekday + 7) % 7
            let db = (b - todayWeekday + 7) % 7
            return da < db
        }

        for day in orderedDays {
            let delta = (day - todayWeekday + 7) % 7
            let firstOffset = (delta == 0) ? 7 : delta
            for w in 0..<weeks {
                if let nextDate = cal.date(byAdding: .day, value: firstOffset + (w * 7), to: today) {
                    results.append(cal.startOfDay(for: nextDate))
                }
            }
        }

        return Set(results)
    }

    private struct WeekdayChip: View {
        let item: (name: String, long: String, num: Int)
        let isOn: Bool
        let action: () -> Void

        var body: some View {
            Button(action: action) {
                VStack(spacing: 4) {
                    Text(item.name)
                        .font(.headline)
                    Circle()
                        .fill(isOn ? Color.accentColor : Color.clear)
                        .frame(width: 6, height: 6)
                        .overlay(
                            Circle().stroke(Color.gray.opacity(0.35), lineWidth: isOn ? 0 : 1)
                        )
                        .accessibilityHidden(true)
                }
                .frame(width: 48, height: 48)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(isOn ? Color.accentColor.opacity(0.15) : Color(.systemGray6))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(isOn ? Color.accentColor : Color.gray.opacity(0.25), lineWidth: isOn ? 2 : 1)
                )
                .foregroundStyle(isOn ? Color.accentColor : Color.primary)
            }
            .accessibilityLabel(item.long)
            .accessibilityAddTraits(isOn ? .isSelected : [])
        }
    }
}
