import SwiftUI

struct CalendarView: View {
    @Binding var selectedDate: Date
    var ejerciciosPorDia: [Date: [Ejercicio]] = [:]

    @State private var currentWeekIndex: Int = 500
    private let calendar = Calendar(identifier: .gregorian)

    var body: some View {
        TabView(selection: $currentWeekIndex) {
            ForEach(0..<1000, id: \.self) { index in
                let startOfWeek = getStartOfWeek(for: index - 500)
                let weekDays = (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: startOfWeek) }

                HStack(spacing: 12) {
                    ForEach(weekDays, id: \.self) { date in
                        let isToday = calendar.isDateInToday(date)
                        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
                        let isPast = date < calendar.startOfDay(for: Date())
                        let tieneEjercicios = (ejerciciosPorDia[date.stripTime()]?.isEmpty == false)

                        VStack(spacing: 6) {
                            Text("\(calendar.component(.day, from: date))")
                                .fontWeight(isToday ? .bold : .regular)
                                .foregroundColor(isPast ? .gray : .black)

                            Text(weekdayShort(for: date))
                                .font(.caption)
                                .foregroundColor(isToday ? .red : (isPast ? .gray : .black))

                            if tieneEjercicios {
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 6, height: 6)
                            }
                        }
                        .frame(width: 44, height: 60)
                        .background(isSelected ? Color.gray.opacity(0.2) : Color.clear)
                        .cornerRadius(8)
                        .contentShape(Rectangle()) // mejora el tap
                        .onTapGesture { selectedDate = date }
                    }
                }
                .padding(.horizontal)
                .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(height: 110)
    }

    // MARK: - Helpers

    private func getStartOfWeek(for offset: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2 // lunes
        let today = Date()
        let baseWeek = calendar.dateInterval(of: .weekOfYear, for: today)!.start
        return calendar.date(byAdding: .weekOfYear, value: offset, to: baseWeek)!
    }

    private func weekdayShort(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_ES")
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).capitalized
    }
}

// Asegúrate de tener este helper en el módulo:
extension Date {
    func stripTime() -> Date {
        let comps = Calendar.current.dateComponents([.year, .month, .day], from: self)
        return Calendar.current.date(from: comps)!
    }
}
