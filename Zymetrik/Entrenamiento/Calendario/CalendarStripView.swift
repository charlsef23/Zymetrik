import SwiftUI

struct CalendarStripView: View {
    @Binding var selectedDate: Date
    var fechasConEntrenamiento: Set<Date>

    private let days: [Date] = {
        let today = Date()
        return (0..<30).map { offset in
            Calendar.current.date(byAdding: .day, value: offset - 15, to: today)!
        }
    }()

    private let today = Date().stripTime()

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(days, id: \.self) { day in
                        let dayKey = day.stripTime()
                        let isSelected = Calendar.current.isDate(day, inSameDayAs: selectedDate)
                        let isToday = Calendar.current.isDateInToday(day)
                        let isPast = dayKey < today
                        let tieneEntreno = fechasConEntrenamiento.contains(dayKey)

                        VStack(spacing: 4) {
                            Text(shortWeekday(from: day))
                                .font(.caption2)
                                .foregroundColor(.gray)

                            Text(dayNumber(from: day))
                                .fontWeight(isToday ? .bold : .regular)
                                .foregroundColor(isSelected ? .white : isPast ? .gray.opacity(0.5) : .primary)
                                .frame(width: 38, height: 38)
                                .background(
                                    Circle()
                                        .fill(isSelected ? Color.black : isToday ? Color.gray.opacity(0.2) : Color.clear)
                                )

                            if tieneEntreno {
                                Circle()
                                    .fill(Color.black)
                                    .frame(width: 6, height: 6)
                            }
                        }
                        .id(dayKey)
                        .onTapGesture {
                            withAnimation {
                                selectedDate = day
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    proxy.scrollTo(today, anchor: .center)
                }
            }
        }
        .padding(.vertical, 6)
    }

    private func shortWeekday(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_ES")
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).uppercased()
    }

    private func dayNumber(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
}
