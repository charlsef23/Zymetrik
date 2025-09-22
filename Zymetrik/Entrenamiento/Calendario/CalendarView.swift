import SwiftUI

struct CalendarView: View {
    @Binding var selectedDate: Date
    var ejerciciosPorDia: [Date: [Ejercicio]] = [:]
    /// Acción que se ejecuta al pulsar “Añadir” en la toolbar
    var onAdd: () -> Void = {}

    @State private var currentWeekIndex: Int = 500
    private let calendar = Calendar(identifier: .gregorian)

    var body: some View {
        // 🔵 Construye set de días con ejercicios normalizados a INICIO DE DÍA LOCAL
        let exerciseDaysLocal: Set<Date> = {
            var set = Set<Date>()
            let cal = Calendar.current
            for (k, v) in ejerciciosPorDia where !v.isEmpty {
                set.insert(cal.startOfDay(for: k))   // 👈 LOCAL
            }
            return set
        }()

        TabView(selection: $currentWeekIndex) {
            ForEach(0..<1000, id: \.self) { index in
                let startOfWeek = getStartOfWeek(for: index - 500)
                let weekDays = (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: startOfWeek) }

                HStack(spacing: 12) {
                    ForEach(weekDays, id: \.self) { date in
                        // Flags por día (misma UI)
                        let isToday = calendar.isDateInToday(date)
                        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
                        let isPast = date < calendar.startOfDay(for: Date())
                        // ✅ compara por startOfDay LOCAL
                        let tieneEjercicios = exerciseDaysLocal.contains(Calendar.current.startOfDay(for: date))

                        VStack(spacing: 6) {
                            VStack(spacing: 4) {
                                Text("\(calendar.component(.day, from: date))")
                                    .fontWeight(isToday ? .bold : .regular)
                                    .foregroundColor(isPast ? .gray : Color("CalendarDay"))

                                Text(weekdayShort(for: date))
                                    .font(.caption)
                                    .foregroundColor(isToday ? .red : (isPast ? .gray : Color("CalendarDay")))
                            }

                            if tieneEjercicios {
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 6, height: 6)
                            }
                        }
                        .frame(width: 44, height: 60)
                        .background(isSelected ? Color.gray.opacity(0.2) : Color.clear)
                        .cornerRadius(8)
                        .contentShape(Rectangle())
                        .onTapGesture { selectedDate = date }
                    }
                }
                .padding(.horizontal)
                .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(height: 110)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Añadir") { onAdd() }
            }
        }
    }

    // MARK: - Helpers

    private func getStartOfWeek(for offset: Int) -> Date {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 2 // lunes
        let today = Date()
        let baseWeek = cal.dateInterval(of: .weekOfYear, for: today)!.start
        return cal.date(byAdding: .weekOfYear, value: offset, to: baseWeek)!
    }

    private func weekdayShort(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_ES")
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).capitalized
    }
}
