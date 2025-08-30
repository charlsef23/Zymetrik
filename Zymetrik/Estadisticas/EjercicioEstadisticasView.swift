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

// MARK: - Vista principal (sin iconos, colores modernos)

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
        VStack(spacing: 20) {
            HeaderRowSimple(title: ejercicio.nombre, subtitle: "Estadísticas")

            // 3 tarjetas sin iconos, con color de fondo suave
            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                spacing: 12
            ) {
                StatTileSimple(
                    title: "Series",
                    value: "\(ejercicio.totalSeries)",
                    tint: .blue,
                    delta: delta(for: .series)
                )

                StatTileSimple(
                    title: "Reps",
                    value: "\(ejercicio.totalRepeticiones)",
                    tint: .green,
                    delta: delta(for: .reps)
                )

                StatTileSimple(
                    title: "Kg",
                    value: ejercicio.totalPeso.formatted(.number.precision(.fractionLength(1))),
                    tint: .orange,
                    delta: delta(for: .kg)
                )
            }

            HStack(spacing: 10) {
                StatCapsuleSimple(
                    title: "Kg/set",
                    value: kgPorSerie.formatted(.number.precision(.fractionLength(1))),
                    tint: .pink,
                    delta: deltaMediaActualVsAnterior(
                        actual: kgPorSerie,
                        anterior: comparativaAnterior?.kgPorSerie ?? inferPrevKgPerSet()
                    )
                )

                StatCapsuleSimple(
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
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(Color.black.opacity(0.05), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.08), radius: 18, x: 0, y: 8)
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
        guard anterior != 0 else { return nil }
        return ((actual - anterior) / anterior) * 100.0
    }

    private func porcentajeCambio(actual: Double, anterior: Double) -> Double? {
        guard anterior != 0 else { return nil }
        return ((actual - anterior) / anterior) * 100.0
    }
}

// MARK: - Componentes UI (sin iconos)

private struct HeaderRowSimple: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(.title3, design: .rounded).weight(.semibold))
                .lineLimit(1)

            HStack(spacing: 10) {
                Text(subtitle)
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.secondary)

                // Línea/acento de color como detalle moderno
                Capsule()
                    .fill(Color.accentColor.opacity(0.25))
                    .frame(width: 56, height: 6)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct StatTileSimple: View {
    let title: String
    let value: String
    let tint: Color
    let delta: Double?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .monospacedDigit()

            if let delta {
                DeltaBadgeText(delta: delta, tint: tint)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 120, alignment: .leading)
        .padding(16)
        .background(
            // Fondo con color suave (sin iconos)
            RoundedRectangle(cornerRadius: 18)
                .fill(tint.opacity(0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(tint.opacity(0.20), lineWidth: 1)
        )
    }
}

private struct StatCapsuleSimple: View {
    let title: String
    let value: String
    let tint: Color
    let delta: Double?

    var body: some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.callout.weight(.semibold))
                .monospacedDigit()

            if let delta {
                DeltaBadgeText(delta: delta, tint: tint)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(
            Capsule().fill(tint.opacity(0.10))
        )
        .overlay(
            Capsule().stroke(tint.opacity(0.20), lineWidth: 1)
        )
    }
}

private struct DeltaBadgeText: View {
    let delta: Double
    let tint: Color

    var body: some View {
        // Sin iconos: solo texto con +/− y porcentaje
        let same = abs(delta) < 0.05
        let sign = same ? "" : (delta > 0 ? "+" : "−")
        let text = same ? "0%" : "\(sign)\(abs(delta).formatted(.number.precision(.fractionLength(1))))%"

        return Text(text)
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .monospacedDigit()
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(
                Capsule().fill(
                    same ? Color.gray.opacity(0.18)
                         : (delta > 0 ? tint.opacity(0.22) : Color.red.opacity(0.18))
                )
            )
            .foregroundStyle(
                same ? Color.secondary
                     : (delta > 0 ? tint : Color.red)
            )
    }
}
