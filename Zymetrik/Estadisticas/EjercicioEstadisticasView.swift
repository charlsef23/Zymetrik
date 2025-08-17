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

// MARK: - Vista principal (estadísticas: cuadrados más grandes, mismo tamaño de números)

struct EjercicioEstadisticasView: View {
    let ejercicio: EjercicioPostContenido
    let comparativaAnterior: TotalesComparativa?

    init(ejercicio: EjercicioPostContenido, comparativaAnterior: TotalesComparativa? = nil) {
        self.ejercicio = ejercicio
        self.comparativaAnterior = comparativaAnterior
    }

    private var kgPorSerie: Double {
        guard ejercicio.totalSeries > 0 else { return 0 }
        return ejercicio.totalPeso / Double(ejercicio.totalSeries)
    }

    private var repsPorSerie: Double {
        guard ejercicio.totalSeries > 0 else { return 0 }
        return Double(ejercicio.totalRepeticiones) / Double(ejercicio.totalSeries)
    }

    var body: some View {
        VStack(spacing: 22) {
            HeaderRow(title: ejercicio.nombre, subtitle: "Estadísticas")

            // 3 cuadrados más grandes (sin aumentar tipografías)
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ], spacing: 16) {
                StatTile(
                    title: "Series",
                    icon: "square.grid.2x2.fill",
                    value: "\(ejercicio.totalSeries)",
                    tint: .blue,
                    delta: delta(for: .series)
                )
                StatTile(
                    title: "Reps",
                    icon: "number.circle.fill",
                    value: "\(ejercicio.totalRepeticiones)",
                    tint: .green,
                    delta: delta(for: .reps)
                )
                StatTile(
                    title: "Kg",
                    icon: "scalemass.fill",
                    value: ejercicio.totalPeso.formatted(.number.precision(.fractionLength(1))),
                    tint: .orange,
                    delta: delta(for: .kg)
                )
            }

            HStack(spacing: 14) {
                StatCapsule(
                    title: "Kg/set",
                    value: kgPorSerie.formatted(.number.precision(.fractionLength(1))),
                    tint: .pink,
                    delta: deltaMediaActualVsAnterior(
                        actual: kgPorSerie,
                        anterior: comparativaAnterior?.kgPorSerie ?? inferPrevKgPerSet()
                    )
                )
                StatCapsule(
                    title: "Reps/set",
                    value: repsPorSerie.formatted(.number.precision(.fractionLength(1))),
                    tint: .mint,
                    delta: deltaMediaActualVsAnterior(
                        actual: repsPorSerie,
                        anterior: comparativaAnterior?.repsPorSerie ?? inferPrevRepsPerSet()
                    )
                )
                Spacer(minLength: 0)
            }
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(.white.opacity(0.08), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.1), radius: 18, x: 0, y: 8)
        )
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

    private func inferPrevKgPerSet() -> Double? {
        guard let c = comparativaAnterior, c.series > 0 else { return nil }
        return c.kg / Double(c.series)
    }

    private func inferPrevRepsPerSet() -> Double? {
        guard let c = comparativaAnterior, c.series > 0 else { return nil }
        return Double(c.reps) / Double(c.series)
    }

    private func deltaMediaActualVsAnterior(actual: Double, anterior: Double?) -> Double? {
        guard let anterior else { return nil }
        return ((actual - anterior) / anterior) * 100.0
    }

    private func porcentajeCambio(actual: Double, anterior: Double) -> Double? {
        guard anterior != 0 else { return nil }
        return ((actual - anterior) / anterior) * 100.0
    }
}

// MARK: - Componentes UI

private struct HeaderRow: View {
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [Color.accentColor.opacity(0.9), Color.accentColor.opacity(0.35)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
                .frame(width: 54, height: 54)
                .overlay(
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundColor(.white)
                        .font(.system(size: 22, weight: .bold))
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(.title3, design: .rounded).weight(.semibold))
                    .lineLimit(1)
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }
}

private struct StatTile: View {
    let title: String
    let icon: String
    let value: String
    let tint: Color
    let delta: Double?

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(tint.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(tint)
                }
                Spacer()
            }

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            // 🔸 Números: MISMO tamaño que antes (no los cambio)
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .monospacedDigit()

            if let delta {
                MiniDelta(delta: delta).padding(.top, 6)
            }
        }
        // 🔹 Más grande por contenedor (no por tipografía)
        .frame(maxWidth: .infinity, minHeight: 130)
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(.white.opacity(0.06), lineWidth: 1)
        )
    }
}

private struct StatCapsule: View {
    let title: String
    let value: String
    let tint: Color
    let delta: Double?

    var body: some View {
        HStack(spacing: 10) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.callout.weight(.semibold)) // igual que la versión anterior "más grande"
                .monospacedDigit()
            if let delta {
                MiniDelta(delta: delta)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
        .background(Capsule().fill(tint.opacity(0.12)))
        .overlay(Capsule().stroke(tint.opacity(0.2), lineWidth: 1))
    }
}

private struct MiniDelta: View {
    let delta: Double
    var up: Bool { delta > 0 }
    var same: Bool { abs(delta) < 0.05 }

    var body: some View {
        let icon = same ? "arrow.right" : (up ? "arrow.up" : "arrow.down")
        let sign = same ? "" : (up ? "+" : "−")
        let text = same ? "0%" : "\(sign)\(abs(delta).formatted(.number.precision(.fractionLength(1))))%"

        return HStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 11, weight: .bold))
            Text(text)
                .font(.system(size: 12, weight: .bold))
                .monospacedDigit()
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(
            Capsule().fill((up ? Color.green : (same ? Color.gray : Color.red)).opacity(0.2))
        )
        .overlay(Capsule().stroke(.white.opacity(0.1), lineWidth: 0.5))
        .foregroundStyle(up ? Color.green : (same ? .secondary : .red))
    }
}
