import SwiftUI

struct EjercicioEstadisticasView: View {
    let ejercicio: EjercicioPostContenido
    /// Opcional: pasa los totales anteriores para mostrar tendencia (por ejemplo, la sesión pasada)
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
        VStack(spacing: 16) {
            // Título
            Text(ejercicio.nombre)
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Grilla de stats
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                StatCard(
                    title: "Series",
                    icon: "square.grid.2x2.fill",
                    value: "\(ejercicio.totalSeries)",
                    color: .blue,
                    delta: delta(for: .series)
                )
                StatCard(
                    title: "Reps",
                    icon: "number.circle.fill",
                    value: "\(ejercicio.totalRepeticiones)",
                    color: .green,
                    delta: delta(for: .reps)
                )
                StatCard(
                    title: "Kg",
                    icon: "scalemass.fill",
                    value: ejercicio.totalPeso.formatted(.number.precision(.fractionLength(1))),
                    color: .orange,
                    delta: delta(for: .kg)
                )
                StatCard(
                    title: "Kg/Set",
                    icon: "dumbbell.fill",
                    value: kgPorSerie.formatted(.number.precision(.fractionLength(1))),
                    color: .pink,
                    delta: deltaMediaActualVsAnterior(actual: kgPorSerie, anterior: comparativaAnterior?.kgPorSerie)
                )
                StatCard(
                    title: "Reps/Set",
                    icon: "repeat.circle.fill",
                    value: repsPorSerie.formatted(.number.precision(.fractionLength(1))),
                    color: .mint,
                    delta: deltaMediaActualVsAnterior(actual: repsPorSerie, anterior: comparativaAnterior?.repsPorSerie)
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemGray6))
        )
        .padding(.horizontal)
        // Accesibilidad
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Estadísticas de \(ejercicio.nombre)")
    }

    // MARK: - Deltas

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

    private func deltaMediaActualVsAnterior(actual: Double, anterior: Double?) -> Double? {
        guard let anterior else { return nil }
        return porcentajeCambio(actual: actual, anterior: anterior)
    }

    private func porcentajeCambio(actual: Double, anterior: Double) -> Double? {
        guard anterior != 0 else { return nil }
        return ((actual - anterior) / anterior) * 100.0
    }
}

// MARK: - Soporte comparativas

struct TotalesComparativa {
    let series: Int
    let reps: Int
    let kg: Double
    /// Derivados (opcional): si los pasas, mostramos delta en medias
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

// MARK: - Componente de stat

private struct StatCard: View {
    let title: String
    let icon: String
    let value: String
    let color: Color
    /// Delta en %, si existe (positivo ↑, negativo ↓)
    let delta: Double?

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .imageScale(.medium)
                    .foregroundStyle(color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            if let delta {
                DeltaPill(delta: delta)
                    .accessibilityLabel(deltaAccLabel(delta))
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private func deltaAccLabel(_ d: Double) -> String {
        let dir = d > 0 ? "subida" : (d < 0 ? "bajada" : "sin cambios")
        let pct = abs(d).formatted(.number.precision(.fractionLength(1)))
        return "Tendencia: \(dir) \(pct) por ciento"
    }
}

private struct DeltaPill: View {
    let delta: Double

    var body: some View {
        let up = delta > 0
        let same = abs(delta) < 0.05 // ~0%
        let icon = same ? "arrow.right" : (up ? "arrow.up" : "arrow.down")
        let sign = same ? "" : (up ? "+" : "−")
        let text = same ? "0%" : "\(sign)\(abs(delta).formatted(.number.precision(.fractionLength(1))))%"

        return HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(text)
                .font(.caption2)
                .fontWeight(.semibold)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(
            Capsule().fill((up ? Color.green : (same ? .gray : .red)).opacity(0.15))
        )
        .foregroundStyle(up ? Color.green : (same ? .secondary : .red))
    }
}
