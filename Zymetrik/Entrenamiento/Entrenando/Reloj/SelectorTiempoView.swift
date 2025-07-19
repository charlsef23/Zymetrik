import SwiftUI

struct SelectorTiempoView: View {
    @Environment(\.dismiss) var dismiss
    @State private var minutos = 0
    @State private var segundos = 0

    var onGuardar: (Int, Int) -> Void

    var body: some View {
        NavigationView {
            Form {
                Stepper("Minutos: \(minutos)", value: $minutos, in: 0...59)
                Stepper("Segundos: \(segundos)", value: $segundos, in: 0...59)
            }
            .navigationTitle("Configurar temporizador")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        onGuardar(minutos, segundos)
                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
            }
        }
    }
}
