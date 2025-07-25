import SwiftUI

struct CronometroView: View {
    @Binding var tiempo: Int
    @Binding var timerActivo: Bool
    @Binding var temporizador: Timer?

    @State private var esTemporizador = false
    @State private var tiempoRestante = 0
    @State private var mostrarSelectorTiempo = false

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemGray5))
                    .frame(height: 80)

                Text(formatearTiempo(segundos: esTemporizador ? tiempoRestante : tiempo))
                    .font(.system(size: 36, weight: .bold, design: .monospaced))
                    .foregroundColor(.black)

                HStack {
                    Spacer()
                    Button {
                        mostrarSelectorTiempo = true
                    } label: {
                        Image(systemName: "timer")
                            .font(.title3)
                            .padding(8)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(radius: 2)
                    }
                    .padding(.trailing, 24)
                }
            }
            .padding(.horizontal)

            HStack(spacing: 16) {
                Button(action: resetTimer) {
                    Text("X Cancel")
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }

                Button(action: toggleTimer) {
                    Text(timerActivo ? "Pause" : "Play")
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(timerActivo ? Color.gray : Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .background(Color.white.ignoresSafeArea(edges: .bottom))
        .sheet(isPresented: $mostrarSelectorTiempo) {
            SelectorTiempoView { minutos, segundos in
                tiempoRestante = (minutos * 60) + segundos
                esTemporizador = true
                resetTimer()
            }
        }
    }

    private func toggleTimer() {
        if timerActivo {
            temporizador?.invalidate()
            timerActivo = false
        } else {
            if esTemporizador {
                temporizador = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                    if tiempoRestante > 0 {
                        tiempoRestante -= 1
                    } else {
                        timerActivo = false
                        temporizador?.invalidate()
                    }
                }
            } else {
                temporizador = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                    tiempo += 1
                }
            }
            timerActivo = true
        }
    }

    private func resetTimer() {
        temporizador?.invalidate()
        timerActivo = false
        if esTemporizador {
            tiempoRestante = 0
        } else {
            tiempo = 0
        }
    }

    private func formatearTiempo(segundos: Int) -> String {
        let horas = segundos / 3600
        let minutos = (segundos % 3600) / 60
        let segundosRestantes = segundos % 60
        return String(format: "%d:%02d:%02d", horas, minutos, segundosRestantes)
    }
}
