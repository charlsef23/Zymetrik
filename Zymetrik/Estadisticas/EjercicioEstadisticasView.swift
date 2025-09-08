import SwiftUI

// Si YA tienes esta struct en otro archivo, elimina esta duplicada.
struct TotalesComparativa {
    let series: Int
    let reps: Int
    let kg: Double
    let kgPorSerie: Double?
    let repsPorSerie: Double?

    init(series: Int, reps: Int, kg: Double, kgPorSerie: Double? = nil, repsPorSerie: Double? = nil) {
        self.series = series
        self.reps = reps
        self.kg = kg
        self.kgPorSerie = kgPorSerie
        self.repsPorSerie = repsPorSerie
    }
}

// MARK: - Vista principal (DISEÑO NUEVO, sin línea arriba)

struct EjercicioEstadisticasView: View {
    let ejercicio: EjercicioPostContenido
    let comparativaAnterior: TotalesComparativa?

    init(ejercicio: EjercicioPostContenido, comparativaAnterior: TotalesComparativa? = nil) {
        self.ejercicio = ejercicio
        self.comparativaAnterior = comparativaAnterior
    }

    // Derivadas
    private var kgPorSerie: Double {
        guard ejercicio.totalSeries > 0 else { return 0 }
        return ejercicio.totalPeso / Double(ejercicio.totalSeries)
    }
    private var repsPorSerie: Double {
        guard ejercicio.totalSeries > 0 else { return 0 }
        return Double(ejercicio.totalRepeticiones) / Double(ejercicio.totalSeries)
    }

    // Grid adaptativa para las cards compactas
    private var columns: [GridItem] { [GridItem(.adaptive(minimum: 150), spacing: 12)] }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            // Header limpio (sin barra/linea)
            VStack(alignment: .leading, spacing: 6) {
                Text(ejercicio.nombre)
                    .font(.system(.title3, design: .rounded).weight(.semibold))
                    .lineLimit(1)
            }

            // HERO: carga total
            HeroMetric(
                title: "Kg totales",
                valueText: formatNumber(ejercicio.totalPeso) + " kg",
                delta: delta(for: .kg)
            )

            // Tiles con micro-barra de progreso
            HStack(spacing: 12) {
                ProgressMetricTile(
                    title: "Series",
                    valueText: "\(ejercicio.totalSeries)",
                    tint: .blue,
                    progress: progress(actual: Double(ejercicio.totalSeries), prev: Double(comparativaAnterior?.series ?? 0)),
                    delta: delta(for: .series)
                )
                ProgressMetricTile(
                    title: "Reps",
                    valueText: "\(ejercicio.totalRepeticiones)",
                    tint: .green,
                    progress: progress(actual: Double(ejercicio.totalRepeticiones), prev: Double(comparativaAnterior?.reps ?? 0)),
                    delta: delta(for: .reps)
                )
                ProgressMetricTile(
                    title: "Kg",
                    valueText: formatNumber(ejercicio.totalPeso),
                    tint: .orange,
                    progress: progress(actual: ejercicio.totalPeso, prev: comparativaAnterior?.kg ?? 0),
                    delta: delta(for: .kg)
                )
            }

            // Medias por set en cards compactas (2 columnas)
            LazyVGrid(columns: columns, spacing: 12) {
                CompactStatCard(
                    title: "Kg por set",
                    value: formatNumber(kgPorSerie),
                    tint: .pink,
                    delta: deltaMediaActualVsAnterior(
                        actual: kgPorSerie,
                        anterior: comparativaAnterior?.kgPorSerie ?? inferPrevKgPerSet()
                    )
                )
                CompactStatCard(
                    title: "Reps por set",
                    value: formatNumber(repsPorSerie),
                    tint: .mint,
                    delta: deltaMediaActualVsAnterior(
                        actual: repsPorSerie,
                        anterior: comparativaAnterior?.repsPorSerie ?? inferPrevRepsPerSet()
                    )
                )
            }

            if comparativaAnterior != nil {
                Text("Comparado con la sesión anterior")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)
            }
        }
        .padding(16)
        .background(GlassCardBackground())
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 18, x: 0, y: 8)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Estadísticas de \(ejercicio.nombre)")
    }

    // MARK: - Deltas & helpers

    enum Campo { case series, reps, kg }

    private func delta(for campo: Campo) -> Double? {
        guard let comp = comparativaAnterior else { return nil }
        switch campo {
        case .series:
            return porcentajeCambio(actual: Double(ejercicio.totalSeries), anterior: Double(comp.series))
        case .reps:
            return porcentajeCambio(actual: Double(ejercicio.totalRepeticiones), anterior: Double(comp.reps))
        case .kg:
            return porcentajeCambio(actual: ejercicio.totalPeso, anterior: comp.kg)
        }
    }

    /// Progreso normalizado 0..1 frente a la sesión previa
    private func progress(actual: Double, prev: Double) -> Double {
        guard prev > 0 else { return 1 }         // sin previa -> lleno
        let ratio = actual / prev
        let normalized = min(max(ratio, 0.0), 1.25) / 1.25 // cap a +25%
        return normalized
    }

    private func inferPrevKgPerSet() -> Double? {
        guard let c = comparativaAnterior, c.series > 0 else { return nil }
        return c.kg / Double(c.series)
    }
    private func inferPrevRepsPerSet() -> Double? {
        guard let c = comparativaAnterior, c.series > 0 else { return nil }
        return Double(c.reps) / Double(c.series)
    }

    private func deltaMediaActualVsAnterior(actual: Double, anterior: Double?) -> Double? {
        guard let anterior, anterior != 0 else { return nil }
        return ((actual - anterior) / anterior) * 100.0
    }
    private func porcentajeCambio(actual: Double, anterior: Double) -> Double? {
        guard anterior != 0 else { return nil }
        return ((actual - anterior) / anterior) * 100.0
    }

    private func formatNumber(_ v: Double) -> String {
        let f = NumberFormatter()
        f.maximumFractionDigits = 1
        f.minimumFractionDigits = 0
        return f.string(from: NSNumber(value: v)) ?? "\(v)"
    }
}

// MARK: - Fondo “glass” seguro (sin material)

private struct GlassCardBackground: View {
    @Environment(\.colorScheme) private var scheme
    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 22, style: .continuous)
        ZStack {
            shape.fill(Color(UIColor.systemBackground))
            shape.fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.primary.opacity(scheme == .dark ? 0.06 : 0.03),
                        Color.clear
                    ]),
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            )
            shape.stroke(Color.primary.opacity(0.06), lineWidth: 1)
        }
    }
}

// MARK: - Hero metric

private struct HeroMetric: View {
    let title: String
    let valueText: String
    let delta: Double?

    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.primary.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.primary.opacity(0.10), lineWidth: 1)
                )

            HStack(alignment: .firstTextBaseline, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(title.uppercased())
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .tracking(0.5)
                    Text(valueText)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .monospacedDigit()
                }
                Spacer()
                if let d = delta {
                    DeltaBadge(d: d)
                }
            }
            .padding(16)
        }
        .frame(height: 88)
    }
}

// MARK: - Tile con barra de progreso

private struct ProgressMetricTile: View {
    let title: String
    let valueText: String
    let tint: Color
    let progress: Double    // 0..1
    let delta: Double?

    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [tint.opacity(0.12), tint.opacity(0.06)]),
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(tint.opacity(0.20), lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 8) {
                Text(title.uppercased())
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .tracking(0.5)

                Text(valueText)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .monospacedDigit()

                // barra de progreso sutil
                ProgressBar(percent: progress, tint: tint)

                if let d = delta {
                    DeltaBadge(d: d, tint: tint)
                }
            }
            .padding(14)
        }
        .frame(maxWidth: .infinity, minHeight: 116)
    }
}

private struct ProgressBar: View {
    let percent: Double  // 0..1
    let tint: Color

    var body: some View {
        GeometryReader { geo in
            let fullW = geo.size.width
            let w = max(0, min(fullW * percent, fullW))

            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(tint.opacity(0.18))
                    .frame(height: 8)
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [tint, tint.opacity(0.5)]),
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .frame(width: w, height: 8)
            }
        }
        .frame(height: 8)
    }
}

// MARK: - Cards compactas 2 columnas

private struct CompactStatCard: View {
    let title: String
    let value: String
    let tint: Color
    let delta: Double?

    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(tint.opacity(0.10))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(tint.opacity(0.18), lineWidth: 1)
                )

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(value)
                        .font(.callout.weight(.semibold))
                        .monospacedDigit()
                }
                Spacer()
                if let d = delta {
                    DeltaBadge(d: d, tint: tint)
                }
            }
            .padding(12)
        }
        .frame(maxWidth: .infinity, minHeight: 72)
    }
}

// MARK: - Badges de delta (texto solo)

private struct DeltaBadge: View {
    let d: Double
    var tint: Color? = nil

    var body: some View {
        let same = abs(d) < 0.05
        let up = d > 0
        let txt = same ? "0%" : "\(up ? "+" : "−")\(abs(d).formatted(.number.precision(.fractionLength(1))))%"

        return Text(txt)
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .monospacedDigit()
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(
                Capsule().fill(
                    same ? Color.gray.opacity(0.18)
                         : (up ? (tint ?? .accentColor).opacity(0.22) : Color.red.opacity(0.18))
                )
            )
            .foregroundStyle(
                same ? Color.secondary
                     : (up ? (tint ?? .accentColor) : .red)
            )
            .accessibilityLabel(
                Text(
                    same ? "Sin cambio"
                         : (up ? "Mejora \(abs(d).formatted(.number.precision(.fractionLength(1)))) por ciento"
                               : "Empeora \(abs(d).formatted(.number.precision(.fractionLength(1)))) por ciento")
                )
            )
    }
}
