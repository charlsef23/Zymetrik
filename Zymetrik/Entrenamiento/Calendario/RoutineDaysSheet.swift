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
        ("L","Lunes",2),("M","Martes",3),("X","Miércoles",4),
        ("J","Jueves",5),("V","Viernes",6),("S","Sábado",7),("D","Domingo",1)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {

                    // Encabezado
                    Header()

                    // Selector de modo
                    Picker("", selection: $mode) {
                        Text("Por semana").tag(Mode.weekdays)
                        Text("Calendario").tag(Mode.calendar)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 16)

                    // Contenido según modo
                    Group {
                        switch mode {
                        case .weekdays:
                            WeekdaysContent(
                                days: days,
                                selectedWeekdays: $selectedWeekdays,
                                weeks: $weeks,
                                onToggle: toggleWeekday
                            )
                        case .calendar:
                            CalendarContent(
                                selectedDates: $selectedDates,
                                calendar: mondayFirstCalendar,
                                summary: calendarSummary
                            )
                        }
                    }
                    .padding(.horizontal, 16)

                    Spacer(minLength: 80) // espacio para no tapar el botón
                }
                .padding(.top, 12)
            }
            .scrollIndicators(.hidden)
            .background(.regularMaterial)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .principal) {
                    Text("Plan de entrenamiento")
                        .font(.headline)
                }
            }
            .onAppear { haptics.prepare() }
            .safeAreaInset(edge: .bottom) {
                // Barra inferior pegajosa con el botón de acción
                VStack(spacing: 0) {
                    confirmButton
                        .padding(.horizontal, 16)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(isApplyEnabled ? Color.accentColor : Color.gray.opacity(0.35))
                                .shadow(color: .accentColor.opacity(0.21), radius: 12, y: 2)
                        )
                }
                .background(.regularMaterial)
                .shadow(color: .accentColor.opacity(0.18), radius: 16, y: -2)
            }
        }
    }

    // MARK: - Botón confirmar

    private var confirmButton: some View {
        Button {
            switch mode {
            case .weekdays:
                guard !selectedWeekdays.isEmpty else { return }
                let dates = generateDatesForWeekdays(weekdays: selectedWeekdays, weeks: weeks)
                guard !dates.isEmpty else { return }
                onConfirmChoice(.exactDates(dates: dates))
            case .calendar:
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
                Image(systemName: "checkmark.circle.fill").imageScale(.medium)
                Text("Aplicar")
                    .font(.title3.weight(.bold))
            }
            .frame(maxWidth: .infinity)
            .foregroundStyle(.white)
        }
        .disabled(!isApplyEnabled)
        .animation(.spring(duration: 0.2), value: isApplyEnabled)
        .sensoryFeedback(.selection, trigger: isApplyEnabled)
        .accessibilityHint("Confirma los días o las fechas seleccionadas")
    }

    private var isApplyEnabled: Bool {
        (mode == .weekdays && !selectedWeekdays.isEmpty) ||
        (mode == .calendar && !selectedDates.isEmpty)
    }

    // MARK: - Helpers (sin cambios funcionales)

    private func toggleWeekday(_ num: Int) {
        if selectedWeekdays.contains(num) {
            selectedWeekdays.remove(num)
        } else {
            selectedWeekdays.insert(num)
        }
        haptics.selectionChanged()
    }

    private func dayLongName(for weekday: Int) -> String {
        let names = ["Domingo","Lunes","Martes","Miércoles","Jueves","Viernes","Sábado"]
        return names[(weekday - 1 + 7) % 7]
    }

    private func generateDatesForWeekdays(weekdays: Set<Int>, weeks: Int) -> Set<Date> {
        let cal = mondayFirstCalendar
        let today = cal.startOfDay(for: Date())
        let todayWeekday = cal.component(.weekday, from: today)

        var results: [Date] = []

        // Incluye hoy solo si coincide el día
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
}

// MARK: - Subvistas internas (estructura & estilo únicamente)

// Cabecera compacta y consistente
private struct Header: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Planifica tu rutina")
                .font(.largeTitle.weight(.heavy))
                .foregroundStyle(LinearGradient(colors: [.accentColor, .blue], startPoint: .leading, endPoint: .trailing))
            Text("Elige por días de semana o por fechas exactas.")
                .font(.title3)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 16)
    }
}

// Sección: Por semana
private struct WeekdaysContent: View {
    let days: Array<(name: String, long: String, num: Int)>
    @Binding var selectedWeekdays: Set<Int>
    @Binding var weeks: Int
    let onToggle: (Int) -> Void

    private let columns = Array(repeating: GridItem(.flexible(minimum: 32), spacing: 8, alignment: .center), count: 7)

    var body: some View {
        VStack(spacing: 16) {

            SectionCard(title: "Días de la semana", icon: "calendar.badge.clock", actionLabel: "Limpiar", onAction: {
                selectedWeekdays = []
            }) {
                LazyVGrid(columns: columns, alignment: .center, spacing: 10) {
                    ForEach(days, id: \.num) { item in
                        let isOn = selectedWeekdays.contains(item.num)
                        WeekdayChip(item: item, isOn: isOn) { onToggle(item.num) }
                            .animation(.bouncy, value: isOn)
                    }
                }
                .padding(.top, 2)
            }

            SectionCard(title: "Semanas a programar", icon: "repeat") {
                HStack(alignment: .center, spacing: 12) {
                    let binding = Binding<Double>(
                        get: { Double(weeks) },
                        set: { weeks = Int($0.rounded()) }
                    )
                    Slider(value: binding, in: 1...24, step: 1)
                        .tint(.accentColor)

                    Stepper(value: $weeks, in: 1...24) {
                        Text("\(weeks)")
                            .font(.title3.monospacedDigit().weight(.semibold))
                            .frame(minWidth: 44)
                    }
                    .labelsHidden()
                }

                HStack(spacing: 6) {
                    Image(systemName: "info.circle").imageScale(.small)
                        .foregroundStyle(.secondary)
                    Text("Se planificarán \(weeks) semana\(weeks == 1 ? "" : "s").")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 4)
            }
        }
    }
}

// Sección: Calendario
private struct CalendarContent: View {
    @Binding var selectedDates: Set<DateComponents>
    let calendar: Calendar
    let summary: String

    var body: some View {
        SectionCard(title: "Selecciona fechas", icon: "calendar", actionLabel: "Limpiar", onAction: {
            selectedDates.removeAll()
        }) {
            MultiDatePicker("Fechas", selection: $selectedDates)
                .environment(\.calendar, calendar)
                .padding(.top, 4)

            if !selectedDates.isEmpty {
                Divider().padding(.vertical, 6)
                VStack(alignment: .leading, spacing: 6) {
                    Text("Resumen").font(.subheadline.weight(.semibold))
                    Text(summary)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
        }
    }
}

// Tarjeta de sección reutilizable
private struct SectionCard<Content: View>: View {
    let title: String
    let icon: String
    let actionLabel: String?
    var onAction: (() -> Void)?
    @ViewBuilder var content: Content

    init(title: String, icon: String, actionLabel: String? = nil, onAction: (() -> Void)? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.actionLabel = actionLabel
        self.onAction = onAction
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(title, systemImage: icon)
                    .font(.headline)
                    .symbolEffect(.pulse)
                    .foregroundStyle(.tint)
                Spacer()
                if let actionLabel, let onAction {
                    Button(actionLabel) { onAction() }
                        .buttonStyle(.borderless)
                        .foregroundStyle(.secondary)
                        .accessibilityLabel(actionLabel)
                        .tint(.accentColor)
                        .font(.body.bold())
                }
            }
            content
        }
        .padding(16)
        .background(.regularMaterial)
        .shadow(color: .accentColor.opacity(0.13), radius: 12, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.gray.opacity(0.15), lineWidth: 1)
        )
    }
}

// Chip de día compacto y consistente
private struct WeekdayChip: View {
    let item: (name: String, long: String, num: Int)
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(item.name)
                    .font(.title2.weight(.bold))
                Circle()
                    .fill(isOn ? LinearGradient(colors: [Color.accentColor.opacity(0.9), Color.accentColor.opacity(0.6)], startPoint: .top, endPoint: .bottom) : LinearGradient(colors: [.clear, .clear], startPoint: .top, endPoint: .bottom))
                    .frame(width: 6, height: 6)
                    .overlay(
                        Circle().stroke(Color.gray.opacity(isOn ? 0.0 : 0.35), lineWidth: isOn ? 0 : 1)
                    )
                    .accessibilityHidden(true)
            }
            .frame(maxWidth: .infinity, minHeight: 56) // ocupa la celda del grid
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        isOn
                        ? LinearGradient(colors: [Color.accentColor.opacity(0.3), Color.accentColor.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        : LinearGradient(colors: [Color(.systemGray6), Color(.systemGray6)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isOn ? Color.accentColor : Color.gray.opacity(0.25), lineWidth: isOn ? 2 : 1)
            )
            .foregroundStyle(isOn ? Color.accentColor : Color.primary)
            .shadow(color: isOn ? Color.accentColor.opacity(0.35) : .clear, radius: isOn ? 6 : 0)
        }
        .accessibilityLabel(item.long)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }
}
