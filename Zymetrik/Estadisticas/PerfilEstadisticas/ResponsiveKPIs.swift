import SwiftUI

struct ResponsiveKPIs: View {
    let sesiones: [SesionEjercicio]
    @Environment(\.sizeCategory) private var sizeCategory

    private var metrics: KPIMetrics { KPIMetrics(sesiones: sesiones) }

    var body: some View {
        GeometryReader { geo in
            let cols = columnsFor(width: geo.size.width, sizeCategory: sizeCategory)
            LazyVGrid(columns: cols, spacing: 10) {
                KPIBlock(title: "Mejor RM", value: metrics.bestRMString, icon: "trophy.fill", tint: .purple)
                KPIBlock(title: "Volumen", value: metrics.totalVolumenString, icon: "cube.box.fill", tint: .blue)
                KPIBlock(title: "Última", value: metrics.ultimaFechaString, icon: "clock.fill", tint: .orange)
            }
        }
        .frame(minHeight: 48)
    }

    private func columnsFor(width: CGFloat, sizeCategory: ContentSizeCategory) -> [GridItem] {
        let largeText = sizeCategory.isAccessibilityCategory || sizeCategory >= .extraLarge
        if width >= 720 && !largeText { return Array(repeating: GridItem(.flexible(minimum: 160), spacing: 10), count: 3) }
        if width >= 480 && !largeText { return Array(repeating: GridItem(.flexible(minimum: 150), spacing: 10), count: 2) }
        return [GridItem(.flexible(minimum: 140), spacing: 10)]
    }
}

struct KPIBlock: View {
    let title: String
    let value: String
    let icon: String
    let tint: Color

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(tint.opacity(0.18))
                    .frame(width: 30, height: 30)
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(tint)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title.uppercased())
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .tracking(0.6)
                Text(value)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(tint.opacity(0.25), lineWidth: 1)
                )
        )
    }
}
