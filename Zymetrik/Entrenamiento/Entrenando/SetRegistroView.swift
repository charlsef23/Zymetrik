import SwiftUI

struct SetRegistroView: View {
    @State private var repeticiones: String
    @State private var peso: String

    let set: SetRegistro
    let onUpdate: (Int, Double) -> Void

    init(set: SetRegistro, onUpdate: @escaping (Int, Double) -> Void) {
        self.set = set
        self.onUpdate = onUpdate
        _repeticiones = State(initialValue: "\(set.repeticiones)")
        _peso = State(initialValue: "\(set.peso)")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Set \(set.numero)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.black)

                Spacer()

                HStack(spacing: 16) {
                    HStack(spacing: 6) {
                        Image(systemName: "repeat")
                            .foregroundColor(.blue)
                        TextField("Reps", text: $repeticiones)
                            .keyboardType(.numberPad)
                            .frame(width: 40)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.black)
                            .onChange(of: repeticiones) {
                                update()
                            }
                    }

                    HStack(spacing: 6) {
                        Image(systemName: "scalemass")
                            .foregroundColor(.green)
                        TextField("Peso", text: $peso)
                            .keyboardType(.decimalPad)
                            .frame(width: 60)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.black)
                            .onChange(of: peso) {
                                update()
                            }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }

    private func update() {
        let repes = Int(repeticiones) ?? 0
        let pesoValor = Double(peso) ?? 0
        onUpdate(repes, pesoValor)
    }
}
