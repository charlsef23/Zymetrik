import SwiftUI

struct CalendarView: View {
    @Binding var selectedDate: Date
    @Binding var isMonthlyView: Bool
    @State private var currentMonth: Date = Date()

    private let calendar = Calendar(identifier: .gregorian)

    var body: some View {
        VStack(spacing: 16) {
            // Encabezado con selector de vista
            HStack {
                Text("Selecciona el día")
                    .font(.subheadline)
                    .foregroundColor(.primary)

                Spacer()

                Button {
                    isMonthlyView.toggle()
                } label: {
                    Label(isMonthlyView ? "Vista semanal" : "Vista mensual", systemImage: "chevron.down")
                        .font(.caption)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background(Color(.systemGray5))
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal)

            // Calendario
            if isMonthlyView {
                monthlyGrid
            } else {
                weeklyScroll
            }
        }
    }

    // MARK: - Vista mensual
    var monthlyGrid: some View {
        VStack(spacing: 8) {
            HStack {
                Button {
                    changeMonth(by: -1)
                } label: {
                    Image(systemName: "chevron.left")
                        .padding(6)
                        .background(Color(.systemGray5))
                        .clipShape(Circle())
                }

                Spacer()

                Text(currentMonth.formatted(.dateTime.month(.wide).year()))
                    .font(.headline)

                Spacer()

                Button {
                    changeMonth(by: 1)
                } label: {
                    Image(systemName: "chevron.right")
                        .padding(6)
                        .background(Color(.systemGray5))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal)

            let daysOfWeek = ["L", "M", "X", "J", "V", "S", "D"]
            HStack {
                ForEach(daysOfWeek, id: \.self) { day in
                    Text(day)
                        .font(.caption2)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(datesInMonth(), id: \.self) { date in
                    dayButton(for: date, isSameMonth: calendar.isDate(date, equalTo: currentMonth, toGranularity: .month))
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Vista semanal
    var weeklyScroll: some View {
        let days = weekDates()

        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(days, id: \.self) { date in
                    VStack(spacing: 4) {
                        Text(weekdayLetter(for: date))
                            .font(.caption2)
                            .foregroundColor(.gray)

                        dayButton(for: date, isSameMonth: true)
                    }
                    .frame(width: 44)
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Botón día
    func dayButton(for date: Date, isSameMonth: Bool) -> some View {
        let isToday = calendar.isDateInToday(date)
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
        let isPast = date < calendar.startOfDay(for: Date())

        return Button {
            selectedDate = date
        } label: {
            Text("\(calendar.component(.day, from: date))")
                .font(.subheadline)
                .frame(width: 32, height: 32)
                .foregroundColor(
                    isSelected
                        ? .white
                        : (isPast ? Color.gray.opacity(0.4) : (isSameMonth ? .primary : .gray.opacity(0.2)))
                )
                .background(
                    isSelected
                        ? AnyView(Circle().fill(Color.black))
                        : AnyView(Color.clear)
                )
                .overlay(
                    Circle()
                        .stroke(isToday && !isSelected ? Color.red : .clear, lineWidth: 1.5)
                )
        }
    }

    // MARK: - Helpers
    func changeMonth(by value: Int) {
        if let newDate = calendar.date(byAdding: .month, value: value, to: currentMonth) {
            currentMonth = newDate
        }
    }

    func datesInMonth() -> [Date] {
        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth)) else {
            return []
        }

        let weekdayOffset = (calendar.component(.weekday, from: startOfMonth) + 5) % 7
        let startDate = calendar.date(byAdding: .day, value: -weekdayOffset, to: startOfMonth)!

        return (0..<42).compactMap {
            calendar.date(byAdding: .day, value: $0, to: startDate)
        }
    }

    func weekDates() -> [Date] {
        let weekday = calendar.component(.weekday, from: selectedDate)
        let offset = ((weekday + 5) % 7) * -1
        let startOfWeek = calendar.date(byAdding: .day, value: offset, to: selectedDate)!

        return (0..<14).compactMap { calendar.date(byAdding: .day, value: $0, to: startOfWeek) }
    }

    func weekdayLetter(for date: Date) -> String {
        let weekday = calendar.component(.weekday, from: date)
        let letters = ["D", "L", "M", "X", "J", "V", "S"]
        return letters[(weekday + 5) % 7]
    }
}
