import SwiftUI

struct EntrenandoView: View {
    let ejercicios: [Ejercicio]

    @State private var tiempo: TimeInterval = 0
    @State private var timerActivo = false
    @State private var timer: Timer?
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack {
            // Cronómetro
            VStack(spacing: 8) {
                Text(formatearTiempo(tiempo))
                    .font(.system(size: 36, weight: .bold, design: .monospaced))

                HStack(spacing: 20) {
                    Button(action: {
                        if timerActivo {
                            pausar()
                        } else {
                            iniciar()
                        }
                    }) {
                        Label(timerActivo ? "Pausar" : "Iniciar", systemImage: timerActivo ? "pause.fill" : "play.fill")
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(timerActivo ? Color.orange : Color.green)
                            .cornerRadius(10)
                    }

                    Button(action: {
                        resetear()
                    }) {
                        Label("Resetear", systemImage: "arrow.counterclockwise")
                            .font(.subheadline)
                            .foregroundColor(.red)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.white)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.red, lineWidth: 1)
                            )
                    }
                }
            }
            .padding()

            Divider()

            // Lista de ejercicios
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(ejercicios, id: \.id) { ejercicio in
                        EjercicioEnSesionView(ejercicio: ejercicio)
                    }
                }
                .padding(.bottom, 40)
            }

            Spacer()

            // Botón de finalizar
            Button("Finalizar entrenamiento") {
                // Aquí podrías guardar resultados, hacer una publicación, etc.
                dismiss()
            }
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.black)
            .cornerRadius(12)
            .padding()
        }
        .navigationTitle("Entrenando")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            timer?.invalidate()
        }
    }

    // Formateador de tiempo
    private func formatearTiempo(_ tiempo: TimeInterval) -> String {
        let minutos = Int(tiempo) / 60
        let segundos = Int(tiempo) % 60
        return String(format: "%02d:%02d", minutos, segundos)
    }

    private func iniciar() {
        timerActivo = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            tiempo += 1
        }
    }

    private func pausar() {
        timerActivo = false
        timer?.invalidate()
    }

    private func resetear() {
        tiempo = 0
        timerActivo = false
        timer?.invalidate()
    }
}
