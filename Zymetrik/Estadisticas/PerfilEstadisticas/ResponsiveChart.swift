import SwiftUI

struct ResponsiveChart: View {
    let sesiones: [SesionEjercicio]
    let sizeCategory: ContentSizeCategory
    let hSizeClass: UserInterfaceSizeClass?

    var body: some View {
        ViewThatFits(in: .vertical) {
            GraficaPesoView(sesiones: sesiones)
                .frame(height: targetHeight(multiplier: 0.40))
            GraficaPesoView(sesiones: sesiones)
                .frame(height: targetHeight(multiplier: 0.32))
            GraficaPesoView(sesiones: sesiones)
                .frame(height: targetHeight(multiplier: 0.26))
        }
    }

    private func targetHeight(multiplier: CGFloat) -> CGFloat {
        let base: CGFloat = (hSizeClass == .regular) ? 560 : 380
        let textFactor: CGFloat = sizeCategory.isAccessibilityCategory ? 1.25 : 1.0
        return max(170, base * multiplier * textFactor)
    }
}
