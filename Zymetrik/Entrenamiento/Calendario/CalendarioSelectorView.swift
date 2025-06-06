import SwiftUI

struct CalendarioSelectorView: View {
    @Binding var selectedDate: Date
    var fechasConEntrenamiento: Set<Date>

    @State private var mostrarVistaMensual = false

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Selecciona el día")
                    .font(.subheadline)
                    .foregroundColor(.black)

                Spacer()

                Button(action: {
                    withAnimation {
                        mostrarVistaMensual.toggle()
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: mostrarVistaMensual ? "chevron.down.circle.fill" : "chevron.up.circle.fill")
                        Text(mostrarVistaMensual ? "Vista semanal" : "Vista mensual")
                    }
                    .font(.caption)
                    .foregroundColor(.black)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(Capsule())
                }
            }
            .padding(.horizontal)

            if mostrarVistaMensual {
                MonthlyCalendarView(
                    selectedDate: $selectedDate,
                    fechasConEntrenamiento: fechasConEntrenamiento
                )
            } else {
                CalendarStripView(
                    selectedDate: $selectedDate,
                    fechasConEntrenamiento: fechasConEntrenamiento
                )
            }
        }
        .padding(.top, 4)
    }
}

