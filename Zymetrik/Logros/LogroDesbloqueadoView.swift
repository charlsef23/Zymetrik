import SwiftUI

struct LogroDesbloqueadoView: View {
    let logro: LogroConEstado
    var onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.accentColor.opacity(0.2))
                            .frame(width: 120, height: 120)

                        Image(systemName: logro.icono_nombre)
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.accentColor)
                    }

                    Text("¡Logro desbloqueado!")
                        .font(.title)
                        .bold()
                        .foregroundColor(.white)

                    Text(logro.titulo)
                        .font(.title2)
                        .foregroundColor(.white)

                    Text(logro.descripcion)
                        .font(.subheadline)
                        .foregroundColor(.gray)
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
                        .background(Color.accentColor)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
        }
    }
}
