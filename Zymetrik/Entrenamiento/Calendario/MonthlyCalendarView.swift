import SwiftUI

struct MonthlyCalendarView: View {
    @Binding var selectedDate: Date
    let fechasConEntrenamiento: Set<Date>
    @State private var currentMonthOffset = 0

    private var calendar: Calendar {
        var cal = Calendar.current
        cal.firstWeekday = 2 // Lunes
        return cal
    }

    private var visibleMonth: Date {
        calendar.date(byAdding: .month, value: currentMonthOffset, to: Date()) ?? Date()
    }

    private var daysInMonth: [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: visibleMonth),
              let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: monthInterval.start)) else {
            return []
        }

        let firstWeekday = calendar.component(.weekday, from: firstDay)
        let offset = (firstWeekday - calendar.firstWeekday + 7) % 7

        return (0..<42).compactMap { offsetDay in
            calendar.date(byAdding: .day, value: offsetDay - offset, to: firstDay)
        }
    }

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_ES")
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: visibleMonth).capitalized
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Button(action: {
                    withAnimation {
                        currentMonthOffset -= 1
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.black)
                        .frame(width: 32, height: 32)
                        .background(Color.gray.opacity(0.15))
                        .clipShape(Circle())
                }

                Spacer()

                Text(monthTitle)
                    .font(.title3)
                    .fontWeight(.semibold)

                Spacer()

                Button(action: {
                    withAnimation {
                        currentMonthOffset += 1
                    }
                }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.black)
                        .frame(width: 32, height: 32)
                        .background(Color.gray.opacity(0.15))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal)

            let daySymbols = calendar.veryShortWeekdaySymbols
            let orderedDays = Array(daySymbols[1...6]) + [daySymbols[0]]

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 6) {
                ForEach(orderedDays, id: \.self) { day in
                    Text(day.uppercased())
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                }

                ForEach(daysInMonth, id: \.self) { date in
                    dayCell(for: date)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 10)
    }

    private func dayCell(for date: Date) -> some View {
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
        let isToday = calendar.isDateInToday(date)
        let isCurrentMonth = calendar.isDate(date, equalTo: visibleMonth, toGranularity: .month)
        let tieneEntreno = fechasConEntrenamiento.contains(date.stripTime())

        return VStack(spacing: 4) {
            Text("\(calendar.component(.day, from: date))")
                .font(.callout)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(isSelected ? Color.black : isToday ? Color.gray.opacity(0.2) : Color.clear)
                )
                .foregroundColor(isCurrentMonth ? (isSelected ? .white : .primary) : .gray)

            if tieneEntreno {
                Circle()
                    .fill(Color.black)
                    .frame(width: 6, height: 6)
            }
        }
        .onTapGesture {
            withAnimation {
                selectedDate = date
            }
        }
    }
}
