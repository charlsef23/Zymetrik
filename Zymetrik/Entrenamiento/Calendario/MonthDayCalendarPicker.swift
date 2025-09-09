import SwiftUI

struct MonthDayCalendarPicker: View {
    /// Días del mes seleccionados como números 1...31 (estado en el padre)
    @Binding var selectedDayNumbers: Set<Int>
    /// Mes mostrado en el encabezado (cualquier fecha del mes)
    @State private var visibleMonth: Date = Date()

    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 2 // Lunes
        return cal
    }

    private var monthTitle: String {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "es_ES")
        fmt.dateFormat = "LLLL yyyy"
        return fmt.string(from: visibleMonth).capitalized
    }

    private var daysInMonth: Int {
        calendar.range(of: .day, in: .month, for: visibleMonth)?.count ?? 30
    }

    private var firstWeekdayOffset: Int {
        // Número de "celdas vacías" antes del día 1 para alinear el lunes como primera columna
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: visibleMonth))!
        let weekday = calendar.component(.weekday, from: startOfMonth) // 1=Dom ... 7=Sáb
        // Convertimos a índice 0..6 donde 0=Lunes
        let index = (weekday + 5) % 7 // Dom(1)->6, Lun(2)->0, Mar(3)->1, ...
        return index
    }

    var body: some View {
        VStack(spacing: 12) {
            header

            // Cabecera L M X J V S D
            HStack {
                ForEach(["L","M","X","J","V","S","D"], id: \.self) { d in
                    Text(d)
                        .font(.caption.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.secondary)
                }
            }

            // Grid del mes
            let totalCells = firstWeekdayOffset + daysInMonth
            let rows = Int(ceil(Double(totalCells) / 7.0))

            VStack(spacing: 8) {
                ForEach(0..<rows, id: \.self) { row in
                    HStack(spacing: 8) {
                        ForEach(0..<7, id: \.self) { col in
                            let cellIndex = row * 7 + col
                            if cellIndex < firstWeekdayOffset {
                                // celda vacía antes del día 1
                                Spacer().frame(maxWidth: .infinity, minHeight: 36)
                            } else {
                                let day = cellIndex - firstWeekdayOffset + 1
                                if day <= daysInMonth {
                                    dayCell(day)
                                } else {
                                    Spacer().frame(maxWidth: .infinity, minHeight: 36)
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
    }

    private var header: some View {
        HStack {
            Button {
                withAnimation {
                    visibleMonth = calendar.date(byAdding: .month, value: -1, to: visibleMonth) ?? visibleMonth
                }
            } label: {
                Image(systemName: "chevron.left")
            }
            Spacer()
            Text(monthTitle)
                .font(.headline)
            Spacer()
            Button {
                withAnimation {
                    visibleMonth = calendar.date(byAdding: .month, value: 1, to: visibleMonth) ?? visibleMonth
                }
            } label: {
                Image(systemName: "chevron.right")
            }
        }
    }

    @ViewBuilder
    private func dayCell(_ day: Int) -> some View {
        let isOn = selectedDayNumbers.contains(day)
        Button {
            if isOn { selectedDayNumbers.remove(day) } else { selectedDayNumbers.insert(day) }
        } label: {
            Text("\(day)")
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity, minHeight: 36)
                .background(isOn ? Color.accentColor : Color(.systemGray6))
                .foregroundColor(isOn ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.35), lineWidth: isOn ? 0 : 1)
                )
        }
        .accessibilityLabel("Día \(day)")
    }
}
