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

    // Pre-cálculos para colores
    private var maxValor: Double? { datos.map(\.pesoTotal).max() }
    private var minValor: Double? { datos.map(\.pesoTotal).min() }

    var body: some View {
        Chart {
            // Línea (separada del ForEach de puntos)
            ForEach(datos) { s in
                LineMark(
                    x: .value("Fecha", s.fecha as Date),
                    y: .value("Peso", s.pesoTotal as Double)
                )
                .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                .foregroundStyle(Color.accentColor)
            }

            // Puntos con color según estado
            ForEach(Array(datos.enumerated()), id: \.element.id) { i, s in
                let color = colorForPoint(at: i)

                PointMark(
                    x: .value("Fecha", s.fecha as Date),
                    y: .value("Peso", s.pesoTotal as Double)
                )
                .symbol(.circle)
                .symbolSize(symbolSizeForPoint(at: i))
                .foregroundStyle(color)
                // Halo suave para mejorar visibilidad
                .annotation(position: .overlay) {
                    Circle()
                        .stroke(color.opacity(0.35), lineWidth: 6)
                        .frame(width: 8, height: 8)
                        .allowsHitTesting(false)
                }
            }

            // Selección -> mostrar solo el peso con color del punto
            if let selectedDate,
               let nearest = nearestEntry(to: selectedDate, in: datos),
               let i = datos.firstIndex(where: { $0.id == nearest.id }) {

                let color = colorForPoint(at: i)

                RuleMark(x: .value("Selección", selectedDate as Date))
                    .foregroundStyle(.tertiary)

                PointMark(
                    x: .value("Fecha", nearest.fecha as Date),
                    y: .value("Peso", nearest.pesoTotal as Double)
                )
                .symbol(.circle)
                .symbolSize(90)
                .foregroundStyle(color)
                .annotation(position: .top, alignment: .center) {
                    Text(formatPeso(nearest.pesoTotal))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(color)
                }
                .accessibilityLabel("Valor seleccionado")
                .accessibilityValue("\(formatPeso(nearest.pesoTotal)) el \(shortDate(nearest.fecha))")
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

    // MARK: - Color logic

    private func colorForPoint(at index: Int) -> Color {
        guard index < datos.count else { return .accentColor }
        let val = datos[index].pesoTotal

        // Récord máximo
        if let maxV = maxValor, isClose(val, maxV) {
            return .purple // 🟣 record
        }
        // Mínimo histórico
        if let minV = minValor, isClose(val, minV) {
            return .red // 🔴 mínimo
        }
        // Comparación con anterior (si existe)
        if index > 0 {
            let prev = datos[index - 1].pesoTotal
            if val > prev + epsilon {
                return .green // 🟢 mejora
            } else if isClose(val, prev) {
                return .yellow // 🟡 igual
            }
        }
        // Descenso u otros casos → color por defecto
        return .accentColor
    }

    private func symbolSizeForPoint(at index: Int) -> CGFloat {
        // Un poco más grande para record/min para que destaque
        let s = datos[index].pesoTotal
        if let maxV = maxValor, isClose(s, maxV) { return 70 }
        if let minV = minValor, isClose(s, minV) { return 60 }
        return 40
    }

    private func colorForSelected(_ s: SesionEjercicio) -> Color {
        // Mantiene el mismo color de estado también al seleccionar
        if let i = datos.firstIndex(where: { $0.id == s.id }) {
            return colorForPoint(at: i)
        }
        return .primary
    }

    // Tolerancia para “igual”
    private var epsilon: Double { 0.1 } // ~100g; ajústalo si quieres

    private func isClose(_ a: Double, _ b: Double) -> Bool {
        abs(a - b) <= epsilon
    }
}

private struct EmptyState: View {
    var body: some View {
        Text("Aún no hay datos")
            .foregroundStyle(.secondary)
            .frame(height: 160)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemGroupedBackground))
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
