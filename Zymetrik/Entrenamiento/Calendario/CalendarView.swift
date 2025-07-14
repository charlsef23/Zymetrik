import SwiftUI

struct CalendarView: View {
    @Binding var selectedDate: Date
    @Binding var isMonthlyView: Bool
    @State private var currentMonth: Date = Date()
    @State private var currentWeekIndex: Int = 500  // Punto inicial
    private let calendar = Calendar(identifier: .gregorian)

    var body: some View {
        VStack(spacing: 16) {
            // Encabezado
            HStack {
                Text("Selecciona el día")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button {
                    isMonthlyView.toggle()
                } label: {
                    Label(
                        isMonthlyView ? "Vista semanal" : "Vista mensual",
                        systemImage: isMonthlyView ? "chevron.up" : "chevron.down"
                    )
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
                weeklySwipeView
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

    // MARK: - Vista semanal con swipe horizontal
    var weeklySwipeView: some View {
        TabView(selection: $currentWeekIndex) {
            ForEach(0..<1000, id: \.self) { index in
                let startOfWeek = getStartOfWeek(for: index - 500)
                let weekDays = (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: startOfWeek) }
                
                HStack(spacing: 8) {
                    ForEach(weekDays, id: \.self) { date in
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
                .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(height: 70)
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
                        .stroke(isToday && !isSelected ? Color.gray.opacity(0.5) : .clear, lineWidth: 1.5)
                )
        }
    }

    // MARK: - Helpers

    func getStartOfWeek(for offset: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2 // lunes

        let today = Date()
        let baseWeek = calendar.dateInterval(of: .weekOfYear, for: today)!.start
        return calendar.date(byAdding: .weekOfYear, value: offset, to: baseWeek)!
    }

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

    func weekdayLetter(for date: Date) -> String {
        let letters = ["L", "M", "X", "J", "V", "S", "D"]
        let weekday = calendar.component(.weekday, from: date)
        // Convertir weekday de domingo=1 a índice con lunes=0
        let adjustedIndex = (weekday + 5) % 7
        return letters[adjustedIndex]
    }
}
