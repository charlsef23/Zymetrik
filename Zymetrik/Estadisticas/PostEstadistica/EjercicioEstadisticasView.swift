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

// MARK: - Vista principal

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

    // ---- 1RM estimado ----
    private var oneRMActual: Double {
        // 1RM real conectado a los sets del ejercicio
        calcular1RMDesdeSets(ejercicio.sets)
    }
    
    private var oneRMPrevio: Double? { estimar1RMPrevio(comparativaAnterior) }
    private var oneRMDelta: Double? {
        guard let prev = oneRMPrevio, prev != 0 else { return nil }
        return ((oneRMActual - prev) / prev) * 100.0
    }

    // Grid adaptativa
    private var columns: [GridItem] { [GridItem(.adaptive(minimum: 150), spacing: 12)] }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            // Header
            VStack(alignment: .leading, spacing: 6) {
                Text(ejercicio.nombre)
                    .font(.system(.title3, design: .rounded).weight(.semibold))
                    .lineLimit(1)
                Text("Estadísticas")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.secondary)
            }

            // HERO: 1RM en lila
            HeroMetric(
                title: "1RM estimado",
                valueText: formatNumber(oneRMActual) + " kg",
                delta: oneRMDelta,
                tint: .purple
            )

            // Tiles: Series, Reps, Kg
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

            // Medias por set
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
    }

    // MARK: - Helpers

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

    private func progress(actual: Double, prev: Double) -> Double {
        guard prev > 0 else { return 1 }
        let ratio = actual / prev
        return min(max(ratio, 0.0), 1.25) / 1.25
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

// MARK: - 1RM Helpers

private func calcular1RMDesdeSets(_ sets: [SetPost]) -> Double {
    // Filtra sets válidos
    let validos = sets.filter { $0.repeticiones > 0 && $0.peso > 0 }
    guard !validos.isEmpty else { return 0 }

    // Si existe un set de 1 rep, el 1RM es el mayor peso de esos sets
    if let maxSingle = validos.filter({ $0.repeticiones == 1 }).map({ $0.peso }).max() {
        return maxSingle
    }

    // Si no hay singles, usa el máximo 1RM estimado por Brzycki entre todos los sets
    let estimados = validos.map { s in oneRMBrzycki(peso: s.peso, reps: s.repeticiones) }
    return estimados.max() ?? 0
}

private func oneRMBrzycki(peso: Double, reps: Int) -> Double {
    // Si es 1 repetición, el 1RM es el propio peso levantado
    if reps <= 1 { return peso }
    // Brzycki: 1RM = peso * 36 / (37 - reps) (fiable hasta ~10 reps)
    let r = min(max(reps, 1), 36)
    let denominator = 37.0 - Double(r)
    guard denominator > 0 else { return peso }
    return peso * 36.0 / denominator
}

private func estimar1RMActual(kgPorSerie: Double, repsPorSerie: Double, totalPeso: Double, totalSeries: Int) -> Double {
    let mediaGlobalSet = totalSeries > 0 ? totalPeso / Double(totalSeries) : 0
    let pesoRef = max(kgPorSerie, mediaGlobalSet)
    let repsRef = max(1, Int(round(repsPorSerie)))
    return oneRMBrzycki(peso: pesoRef, reps: repsRef)
}

private func estimar1RMPrevio(_ comp: TotalesComparativa?) -> Double? {
    guard let c = comp else { return nil }
    guard let kgSet = c.kgPorSerie, let repsSet = c.repsPorSerie else { return nil }
    let mediaGlobalSet = c.series > 0 ? c.kg / Double(c.series) : 0
    let pesoRef = max(kgSet, mediaGlobalSet)
    let repsRef = max(1, Int(round(repsSet)))
    return oneRMBrzycki(peso: pesoRef, reps: repsRef)
}

// MARK: - Fondo glass

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

// MARK: - Hero metric (con tint configurable)

private struct HeroMetric: View {
    let title: String
    let valueText: String
    let delta: Double?
    var tint: Color = .purple

    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(tint.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(tint.opacity(0.25), lineWidth: 1)
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
                    DeltaBadge(d: d, tint: tint)
                }
            }
            .padding(16)
        }
        .frame(height: 88)
    }
}

// MARK: - ProgressMetricTile

private struct ProgressMetricTile: View {
    let title: String
    let valueText: String
    let tint: Color
    let progress: Double
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
    let percent: Double
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

// MARK: - CompactStatCard

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

// MARK: - DeltaBadge

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
    }
}

