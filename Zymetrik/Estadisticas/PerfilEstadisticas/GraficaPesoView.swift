import SwiftUI
import Charts

private enum RangoTiempo: String, CaseIterable, Identifiable {
    case unaSemana = "1S"
    case unMes     = "1M"
    case tresMeses = "3M"
    case seisMeses = "6M"
    case unAnio    = "1A"
    case todo      = "Todo"

    var id: String { rawValue }
    var title: String { rawValue }

    func cutoff(from endDate: Date) -> Date? {
        let cal = Calendar.current
        switch self {
        case .unaSemana: return cal.date(byAdding: .day, value: -7, to: endDate)
        case .unMes:     return cal.date(byAdding: .month, value: -1, to: endDate)
        case .tresMeses: return cal.date(byAdding: .month, value: -3, to: endDate)
        case .seisMeses: return cal.date(byAdding: .month, value: -6, to: endDate)
        case .unAnio:    return cal.date(byAdding: .year, value: -1, to: endDate)
        case .todo:      return nil
        }
    }
}

struct GraficaPesoView: View {
    let sesiones: [SesionEjercicio]   // id, fecha: Date, pesoTotal: Double
    @State private var selectedDate: Date?
    @State private var rango: RangoTiempo = .tresMeses

    private var datos: [SesionEjercicio] { sesiones.sorted { $0.fecha < $1.fecha } }

    private var datosFiltrados: [SesionEjercicio] {
        guard let lastDate = datos.last?.fecha else { return datos }
        guard let cutoff = rango.cutoff(from: lastDate) else { return datos }
        return datos.filter { $0.fecha >= cutoff }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Progreso")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                Spacer()
                Menu {
                    ForEach(RangoTiempo.allCases) { r in
                        Button(r.title) { rango = r }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                        Text(rango.title)
                            .font(.caption.weight(.semibold))
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(Color(.secondarySystemBackground), in: Capsule())
                }
                .menuOrder(.fixed)
            }

            resumenView

            if datos.isEmpty {
                EmptyState()
            } else {
                EnhancedPesoChart(datos: datosFiltrados, selectedDate: $selectedDate)
                    .frame(maxWidth: .infinity)
                    .frame(height: 180)
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
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var resumenView: some View {
        let series = datosFiltrados
        let actual = series.last?.pesoTotal
        let inicial = series.first?.pesoTotal
        let delta = (actual != nil && inicial != nil) ? (actual! - inicial!) : nil
        let porcentaje: Double? = {
            guard let a = actual, let i = inicial, i != 0 else { return nil }
            return (a - i) / i * 100.0
        }()

        return HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(actual != nil ? formatPeso(actual!) : "–")
                    .font(.system(.title3, design: .rounded).weight(.semibold))
                Text("Actual")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if let delta = delta {
                HStack(spacing: 8) {
                    Image(systemName: delta >= 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.caption.weight(.bold))
                    VStack(alignment: .leading, spacing: 0) {
                        Text(String(format: "%@%.1f kg", delta >= 0 ? "+" : "", delta))
                            .font(.subheadline.weight(.semibold))
                        if let p = porcentaje {
                            Text(String(format: "%.1f%%", p))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .foregroundStyle(delta >= 0 ? Color.green : Color.red)
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background((delta >= 0 ? Color.green : Color.red).opacity(0.12), in: Capsule())
            }
        }
        .padding(8)
    }
}

private struct EnhancedPesoChart: View {
    let datos: [SesionEjercicio]
    @Binding var selectedDate: Date?

    // Precomputed helpers to reduce type-checking complexity
    private var fechas: [Date] { datos.map(\.fecha) }
    private var minItem: SesionEjercicio? { datos.min(by: { $0.pesoTotal < $1.pesoTotal }) }
    private var maxItem: SesionEjercicio? { datos.max(by: { $0.pesoTotal < $1.pesoTotal }) }
    private var baseY: Double { (minValor ?? 0) * 0.995 }

    // Type-erased shape styles to simplify Charts generic inference
    private var lineShapeStyle: AnyShapeStyle { AnyShapeStyle(lineGradient) }
    private var areaShapeStyle: AnyShapeStyle { AnyShapeStyle(areaGradient) }
    private var minPointShapeStyle: AnyShapeStyle { AnyShapeStyle(LinearGradient(colors: [Color.orange, Color.red], startPoint: .top, endPoint: .bottom)) }
    private var maxPointShapeStyle: AnyShapeStyle { AnyShapeStyle(LinearGradient(colors: [Color.pink, Color.purple], startPoint: .top, endPoint: .bottom)) }

    private var minValor: Double? { datos.map(\.pesoTotal).min() }
    private var maxValor: Double? { datos.map(\.pesoTotal).max() }

    // Estilos modernos
    private var lineGradient: LinearGradient {
        LinearGradient(colors: [Color.purple, Color.blue, Color.cyan], startPoint: .leading, endPoint: .trailing)
    }
    private var areaGradient: LinearGradient {
        LinearGradient(colors: [Color.cyan.opacity(0.25), Color.purple.opacity(0.06)], startPoint: .top, endPoint: .bottom)
    }
    private var plotBackground: LinearGradient {
        LinearGradient(colors: [Color.cyan.opacity(0.10), Color.purple.opacity(0.10)], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    // Media móvil simple (ventana 5)
    private var mediaMovil: [(fecha: Date, valor: Double)] {
        guard datos.count >= 4 else { return [] }
        let window = 5
        var out: [(fecha: Date, valor: Double)] = []
        for i in datos.indices {
            let start = max(0, i - (window - 1))
            let slice = datos[start...i]
            let sum = slice.reduce(0.0) { partial, item in
                partial + item.pesoTotal
            }
            let avg = sum / Double(slice.count)
            out.append((fecha: datos[i].fecha, valor: avg))
        }
        return out
    }

    var body: some View {
        Chart {
            // Área bajo la línea
            ForEach(datos, id: \.id) { s in
                AreaMark(
                    x: .value("Fecha", s.fecha),
                    yStart: .value("Base", baseY),
                    yEnd: .value("Peso", s.pesoTotal)
                )
                .interpolationMethod(.linear)
                .foregroundStyle(areaShapeStyle)
            }

            // Línea principal
            ForEach(datos, id: \.id) { s in
                LineMark(x: .value("Fecha", s.fecha), y: .value("Peso", s.pesoTotal))
                    .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    .interpolationMethod(.linear)
                    .foregroundStyle(lineShapeStyle)
                    .shadow(color: Color.blue.opacity(0.25), radius: 6, y: 3)
            }

            // Puntos para cada entrenamiento
            ForEach(datos, id: \.id) { s in
                PointMark(
                    x: .value("Fecha", s.fecha),
                    y: .value("Peso", s.pesoTotal)
                )
                .symbol(.circle)
                .symbolSize(28)
                .foregroundStyle(lineShapeStyle)
                .shadow(color: Color.blue.opacity(0.15), radius: 2, y: 1)
            }

            // Media móvil
            ForEach(mediaMovil, id: \.fecha) { item in
                LineMark(x: .value("Fecha", item.fecha), y: .value("Media", item.valor))
                    .lineStyle(StrokeStyle(lineWidth: 1.2, dash: [4, 3]))
                    .interpolationMethod(.linear)
                    .foregroundStyle(Color.mint.opacity(0.85))
            }

            // Min/Max sutiles
            if let minItem, let minV = minValor {
                PointMark(x: .value("Fecha", minItem.fecha), y: .value("Min", minV))
                    .symbol(.circle)
                    .symbolSize(34)
                    .foregroundStyle(minPointShapeStyle)
                    .shadow(color: Color.red.opacity(0.25), radius: 4, y: 2)
            }
            if let maxItem, let maxV = maxValor {
                PointMark(x: .value("Fecha", maxItem.fecha), y: .value("Max", maxV))
                    .symbol(.circle)
                    .symbolSize(40)
                    .foregroundStyle(maxPointShapeStyle)
                    .shadow(color: Color.purple.opacity(0.25), radius: 4, y: 2)
            }

            // Selección
            if let selectedDate,
               let nearest = nearestEntry(to: selectedDate, in: datos) {
                RuleMark(x: .value("Selección", selectedDate))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                    .foregroundStyle(lineGradient.opacity(0.35))
                PointMark(x: .value("Fecha", nearest.fecha), y: .value("Peso", nearest.pesoTotal))
                    .symbol(.circle)
                    .symbolSize(44)
                    .foregroundStyle(lineShapeStyle)
                    .shadow(color: Color.blue.opacity(0.15), radius: 3, y: 1)
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 6)) { _ in
                AxisGridLine().foregroundStyle(Color.white.opacity(0.12))
                // No labels on the X axis
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { v in
                AxisGridLine().foregroundStyle(Color.white.opacity(0.12))
                AxisValueLabel {
                    if let y = v.as(Double.self) { Text(formatPesoShort(y)) }
                }
                .font(.caption2).foregroundStyle(.secondary)
            }
        }
        .chartXScale(range: .plotDimension(padding: 16))
        .chartYScale(domain: .automatic(includesZero: false), range: .plotDimension(padding: 12))
        .chartXSelection(value: $selectedDate)
        .chartBackground(alignment: .bottom) { _ in
            if let selectedDate,
               let nearest = nearestEntry(to: selectedDate, in: datos) {
                HStack(spacing: 10) {
                    Text(formatPeso(nearest.pesoTotal))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(shortDate(nearest.fecha))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .background(
                    Capsule().fill(LinearGradient(colors: [Color.blue.opacity(0.18), Color.purple.opacity(0.18)], startPoint: .leading, endPoint: .trailing))
                )
                .overlay(
                    Capsule().stroke(lineGradient.opacity(0.5), lineWidth: 1)
                )
                .padding(.top, 6)
            }
        }
        .chartPlotStyle { plot in
            plot
                .background(plotBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(lineGradient.opacity(0.35), lineWidth: 1)
                )
                .cornerRadius(12)
        }
        .frame(maxWidth: .infinity)
        .animation(.easeOut(duration: 0.2), value: fechas)
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
