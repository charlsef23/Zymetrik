import SwiftUI
import Charts

struct GraficaPesoView: View {
    let sesiones: [SesionEjercicio]   // id, fecha: Date, pesoTotal: Double
    @State private var selectedDate: Date?

    // Evita hacer el sort dentro del body
    private var datos: [SesionEjercicio] {
        sesiones.sorted { (a: SesionEjercicio, b: SesionEjercicio) -> Bool in
            a.fecha < b.fecha
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Progreso")
                .font(.system(size: 16, weight: .semibold, design: .rounded))

            if datos.isEmpty {
                EmptyState()
            } else {
                SimplePesoChart(
                    datos: datos,
                    selectedDate: $selectedDate
                )
                .frame(height: 200)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16).fill(Color(.systemBackground))
        )
    }
}

private struct SimplePesoChart: View {
    let datos: [SesionEjercicio]
    @Binding var selectedDate: Date?

    var body: some View {
        Chart {
            // Línea (separada del ForEach de puntos)
            ForEach(datos) { s in
                LineMark(
                    x: .value("Fecha", s.fecha as Date),
                    y: .value("Peso", s.pesoTotal as Double)
                )
                .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round))
                .foregroundStyle(Color.accentColor)
            }

            // Puntos
            ForEach(datos) { s in
                PointMark(
                    x: .value("Fecha", s.fecha as Date),
                    y: .value("Peso", s.pesoTotal as Double)
                )
                .symbol(.circle)
                .symbolSize(40)
                .foregroundStyle(Color.accentColor)
            }

            // Selección -> tooltip
            if let selectedDate,
               let nearest = nearestEntry(to: selectedDate, in: datos) {
                RuleMark(x: .value("Selección", selectedDate as Date))
                    .foregroundStyle(.tertiary)

                PointMark(
                    x: .value("Fecha", nearest.fecha as Date),
                    y: .value("Peso", nearest.pesoTotal as Double)
                )
                .symbolSize(80)
                .foregroundStyle(.primary)
                .annotation(position: .top) {
                    Tooltip(valor: nearest.pesoTotal, fecha: nearest.fecha)
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
}

private struct EmptyState: View {
    var body: some View {
        Text("Aún no hay datos")
            .foregroundStyle(.secondary)
            .frame(height: 160)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemGroupedBackground)))
    }
}

private struct Tooltip: View {
    let valor: Double
    let fecha: Date

    var body: some View {
        VStack(spacing: 4) {
            Text(shortDate(fecha))
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(formatPeso(valor))
                .font(.caption.weight(.semibold))
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.thinMaterial)
        )
    }
}

// MARK: - Helpers

private func nearestEntry(to date: Date, in datos: [SesionEjercicio]) -> SesionEjercicio? {
    datos.min {
        abs($0.fecha.timeIntervalSince1970 - date.timeIntervalSince1970) <
        abs($1.fecha.timeIntervalSince1970 - date.timeIntervalSince1970)
    }
}

private func shortDate(_ date: Date) -> String {
    let f = DateFormatter()
    f.locale = .current
    f.setLocalizedDateFormatFromTemplate("d MMM")
    return f.string(from: date)
}

private func formatPeso(_ value: Double) -> String {
    let nf = NumberFormatter()
    nf.numberStyle = .decimal
    nf.maximumFractionDigits = 1
    return "\(nf.string(from: value as NSNumber) ?? "-") kg"
}

private func formatPesoShort(_ value: Double) -> String {
    let nf = NumberFormatter()
    nf.numberStyle = .decimal
    nf.maximumFractionDigits = 0
    return "\(nf.string(from: value as NSNumber) ?? "-")"
}
