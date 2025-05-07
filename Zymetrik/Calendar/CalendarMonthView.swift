import SwiftUI

struct CalendarMonthView: View {
    var sesiones: [WorkoutSession]
    var monthDate: Date
    @Binding var selectedDate: Date
    var calendar: Calendar

    private let days = ["L", "M", "X", "J", "V", "S", "D"]

    var body: some View {
        VStack(spacing: 8) {
            // Encabezado de días
            HStack {
                ForEach(days, id: \.self) { day in
                    Text(day)
                        .frame(maxWidth: .infinity)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }

            let daysInMonth = calendar.range(of: .day, in: .month, for: monthDate)!
            let firstWeekdayIndex = (calendar.component(.weekday, from: firstOfMonth) + 5) % 7

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 12) {
                ForEach(0..<firstWeekdayIndex, id: \.self) { _ in
                    Text(" ").frame(height: 40)
                }

                ForEach(daysInMonth, id: \.self) { day in
                    let date = dateFor(day)
                    let isToday = esHoy(date)
                    let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
                    let hasWorkout = sesiones.contains(where: { calendar.isDate($0.date, inSameDayAs: date) })

                    Button {
                        selectedDate = date
                    } label: {
                        VStack(spacing: 4) {
                            Text("\(day)")
                                .fontWeight(isSelected ? .bold : .regular)
                                .foregroundColor(
                                    isToday && !isSelected ? .red :
                                    hasWorkout ? .blue : .primary
                                )

                            if hasWorkout {
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 6, height: 6)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(4)
                        .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }
            }
        }
    }

    var firstOfMonth: Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: monthDate))!
    }

    func dateFor(_ day: Int) -> Date {
        calendar.date(bySetting: .day, value: day, of: firstOfMonth)!
    }

    func esHoy(_ date: Date) -> Bool {
        calendar.isDate(date, inSameDayAs: Date())
    }
}
