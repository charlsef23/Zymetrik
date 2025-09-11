import SwiftUI

struct RecentSessionsList: View {
    let sesiones: [SesionEjercicio]

    var body: some View {
        if sesiones.isEmpty {
            HStack(spacing: 8) {
                Image(systemName: "tray")
                Text("Sin sesiones todavía")
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
            )
        } else {
            VStack(spacing: 8) {
                ForEach(items(), id: \.id) { s in
                    HStack {
                        Text(s.fecha, style: .date)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(formatoPeso(s.pesoTotal))
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.primary)
                            .monospacedDigit()
                    }
                    .padding(.vertical, 6)
                    .contentShape(Rectangle())

                    if s.id != items().last?.id {
                        Divider().opacity(0.5)
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(.quaternary, lineWidth: 1)
                    )
            )
        }
    }

    private func items() -> [SesionEjercicio] {
        let sorted = sesiones.sorted { $0.fecha > $1.fecha }
        return Array(sorted.prefix(3))
    }
}

// Helpers locales para formato
private func formatoPeso(_ v: Double) -> String {
    let f = NumberFormatter(); f.maximumFractionDigits = 1; f.minimumFractionDigits = 0
    return (f.string(from: NSNumber(value: v)) ?? "\(v)") + " kg"
}
