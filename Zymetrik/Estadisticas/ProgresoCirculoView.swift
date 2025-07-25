import SwiftUI

struct ProgresoCirculoView: View {
    let estado: ProgresoEstado

    var body: some View {
        let (color, icon): (Color, String) = {
            switch estado {
            case .mejorado: return (.green, "arrow.up")
            case .igual: return (.yellow, "minus")
            case .empeorado: return (.red, "arrow.down")
            }
        }()

        return ZStack {
            Circle()
                .fill(color)
                .frame(width: 28, height: 28)

            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
        }
    }
}
