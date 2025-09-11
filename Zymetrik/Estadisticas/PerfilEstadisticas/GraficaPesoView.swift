import SwiftUI
import Charts

struct GraficaPesoView: View {
    let sesiones: [SesionEjercicio]   // id, fecha: Date, pesoTotal: Double
    @State private var selectedDate: Date?

    private var datos: [SesionEjercicio] { sesiones.sorted { $0.fecha < $1.fecha } }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Progreso")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                Spacer()
            }

            if datos.isEmpty {
                EmptyState()
            } else {
                SimplePesoChart(datos: datos, selectedDate: $selectedDate)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(.quaternary, lineWidth: 1)
                )
        )
    }
}

private struct SimplePesoChart: View {
    let datos: [SesionEjercicio]
    @Binding var selectedDate: Date?

    private var maxValor: Double? { datos.map(\.pesoTotal).max() }
    private var minValor: Double? { datos.map(\.pesoTotal).min() }
    var body: some View {
        Chart {
            ForEach(datos) { s in
                LineMark(x: .value("Fecha", s.fecha), y: .value("Peso", s.pesoTotal))
                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                    .interpolationMethod(.catmullRom)
            }

            ForEach(Array(datos.enumerated()), id: \.element.id) { i, s in
                let color = colorForPoint(at: i)
                PointMark(x: .value("Fecha", s.fecha), y: .value("Peso", s.pesoTotal))
                    .symbol(.circle)
                    .symbolSize(symbolSizeForPoint(at: i))
                    .foregroundStyle(color)
                    .annotation(position: .overlay) {
                        Circle()
                            .stroke(color.opacity(0.35), lineWidth: 6)
                            .frame(width: 8, height: 8)
                            .allowsHitTesting(false)
                    }
            }

            if let selectedDate,
               let nearest = nearestEntry(to: selectedDate, in: datos),
               let i = datos.firstIndex(where: { $0.id == nearest.id }) {

                let color = colorForPoint(at: i)

                RuleMark(x: .value("Selección", selectedDate)).foregroundStyle(.tertiary)

                PointMark(x: .value("Fecha", nearest.fecha), y: .value("Peso", nearest.pesoTotal))
                    .symbol(.circle)
                    .symbolSize(90)
                    .foregroundStyle(color)
                    .annotation(position: .top, alignment: .center) {
                        Text(formatPeso(nearest.pesoTotal))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(color)
                    }
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 6)) { v in
                AxisGridLine().foregroundStyle(.quaternary)
                AxisValueLabel {
                    if let d = v.as(Date.self) { Text(shortDate(d)) }
                }
                .font(.caption2).foregroundStyle(.secondary)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { v in
                AxisGridLine().foregroundStyle(.quaternary)
                AxisValueLabel {
                    if let y = v.as(Double.self) { Text(formatPesoShort(y)) }
                }
                .font(.caption2).foregroundStyle(.secondary)
            }
        }
        .chartXSelection(value: $selectedDate)
    }


    private func colorForPoint(at index: Int) -> Color {
        guard index < datos.count else { return .accentColor }
        let val = datos[index].pesoTotal

        if let maxV = maxValor, abs(val - maxV) <= 0.1 { return .purple } // ✅ usa maxV
        if let minV = minValor, abs(val - minV) <= 0.1 { return .red }    // ✅ usa minV

        if index > 0 {
            let prev = datos[index - 1].pesoTotal
            if val > prev + 0.1 { return .green }
            if abs(val - prev) <= 0.1 { return .yellow }
        }
        return .accentColor
    }

    private func symbolSizeForPoint(at index: Int) -> CGFloat {
        let s = datos[index].pesoTotal

        if let maxV = maxValor, abs(s - maxV) <= 0.1 { return 70 } // ✅ usa maxV
        if let minV = minValor, abs(s - minV) <= 0.1 { return 60 } // ✅ usa minV
        return 40
    }
}

private struct EmptyState: View {
    var body: some View {
        Text("Aún no hay datos")
            .foregroundStyle(.secondary)
            .frame(height: 140)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
    }
}

// Helpers locales del gráfico
private func nearestEntry(to date: Date, in datos: [SesionEjercicio]) -> SesionEjercicio? {
    datos.min {
        abs($0.fecha.timeIntervalSince1970 - date.timeIntervalSince1970) <
        abs($1.fecha.timeIntervalSince1970 - date.timeIntervalSince1970)
    }
}
private func shortDate(_ date: Date) -> String {
    let f = DateFormatter(); f.locale = .current; f.setLocalizedDateFormatFromTemplate("d MMM")
    return f.string(from: date)
}
private func formatPeso(_ value: Double) -> String {
    let nf = NumberFormatter(); nf.numberStyle = .decimal; nf.maximumFractionDigits = 1
    return "\(nf.string(from: value as NSNumber) ?? "-") kg"
}
private func formatPesoShort(_ value: Double) -> String {
    let nf = NumberFormatter(); nf.numberStyle = .decimal; nf.maximumFractionDigits = 0
    return "\(nf.string(from: value as NSNumber) ?? "-")"
}
