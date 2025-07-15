import SwiftUI


struct CronometroView: View {
    @Binding var tiempo: Int
    @Binding var timerActivo: Bool
    @Binding var temporizador: Timer?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black)
                .frame(height: 100)
                .padding(.horizontal)
                .shadow(radius: 4)

            HStack(spacing: 24) {
                Text(formatearTiempo(segundos: tiempo))
                    .font(.system(size: 32, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)

                Button(action: toggleTimer) {
                    Image(systemName: timerActivo ? "pause.fill" : "play.fill")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.green)
                        .clipShape(Circle())
                }

                Button(action: resetTimer) {
                    Image(systemName: "arrow.counterclockwise")
                        .foregroundColor(.white)
                }
            }
        }
        .padding(.top)
    }

    private func toggleTimer() {
        if timerActivo {
            temporizador?.invalidate()
            timerActivo = false
        } else {
            temporizador = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                tiempo += 1
            }
            timerActivo = true
        }
    }

    private func resetTimer() {
        temporizador?.invalidate()
        tiempo = 0
        timerActivo = false
    }

    private func formatearTiempo(segundos: Int) -> String {
        let minutos = segundos / 60
        let segundos = segundos % 60
        return String(format: "%02d:%02d", minutos, segundos)
    }
}
