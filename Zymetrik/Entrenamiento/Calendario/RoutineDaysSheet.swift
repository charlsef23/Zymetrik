import SwiftUI

/// Hoja para elegir días de la semana y cuántas semanas aplicar.
struct RoutineDaysSheet: View {
    /// Devuelve los weekdays seleccionados (1=Domingo ... 7=Sábado) y el número de semanas
    var onConfirm: (_ weekdays: Set<Int>, _ weeks: Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedDays: Set<Int> = [2] // Lunes por defecto (Calendar gregoriano: 1=Domingo, 2=Lunes...)
    @State private var weeks: Int = 8

    private let days: [(name: String, num: Int)] = [
        ("L", 2), ("M", 3), ("X", 4), ("J", 5), ("V", 6), ("S", 7), ("D", 1)
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Elige los días para tu rutina")
                    .font(.title3.weight(.semibold))
                    .padding(.top, 8)

                // Chips de días
                HStack(spacing: 10) {
                    ForEach(days, id: \.num) { item in
                        let isOn = selectedDays.contains(item.num)
                        Button {
                            if isOn { selectedDays.remove(item.num) } else { selectedDays.insert(item.num) }
                        } label: {
                            Text(item.name)
                                .font(.headline)
                                .frame(width: 44, height: 44)
                                .background(isOn ? Color.accentColor : Color(.systemGray6))
                                .foregroundColor(isOn ? .white : .primary)
                                .clipShape(Circle())
                                .overlay(
                                    Circle().stroke(Color.gray.opacity(0.35), lineWidth: isOn ? 0 : 1)
                                )
                        }
                        .accessibilityLabel(dayLongName(for: item.num))
                    }
                }

                // Semanas a programar
                VStack(spacing: 8) {
                    Text("Semanas a programar")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Stepper(value: $weeks, in: 1...24) {
                        Text("\(weeks) semanas")
                            .font(.headline)
                    }
                    .padding(.horizontal)
                }

                Spacer()

                Button {
                    guard !selectedDays.isEmpty else { return }
                    onConfirm(selectedDays, weeks)
                } label: {
                    Text("Aplicar rutina")
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                }
                .disabled(selectedDays.isEmpty)
                .padding(.bottom, 16)
            }
            .padding(.horizontal)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
            }
        }
    }

    private func dayLongName(for weekday: Int) -> String {
        // 1=Domingo ... 7=Sábado
        let names = ["Domingo","Lunes","Martes","Miércoles","Jueves","Viernes","Sábado"]
        return names[(weekday - 1 + 7) % 7]
    }
}
