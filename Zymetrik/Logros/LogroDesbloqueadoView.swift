import SwiftUI

struct LogroDesbloqueadoView: View {
    let logro: LogroConEstado
    var onDismiss: () -> Void

    var body: some View {
        // Color principal: si el logro tiene color definido lo usamos, si no el accentColor
        let color = Color.fromHex(logro.color) ?? .accentColor

        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(color.opacity(0.2))
                            .frame(width: 120, height: 120)

                        Image(systemName: logro.icono_nombre)
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(color)
                    }
                    .transition(.scale.combined(with: .opacity))

                    Text("¡Logro desbloqueado!")
                        .font(.title)
                        .bold()
                        .foregroundColor(.white)

                    Text(logro.titulo)
                        .font(.title3.weight(.semibold))
                        .foregroundColor(.white)

                    Text(logro.descripcion)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Spacer()

                Button(action: onDismiss) {
                    Text("Continuar")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(color)   // <- usa el color del logro
                        .cornerRadius(12)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            #if os(iOS)
            let gen = UINotificationFeedbackGenerator()
            gen.notificationOccurred(.success)
            #endif
        }
    }
}
