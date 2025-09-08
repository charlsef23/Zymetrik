import SwiftUI

struct SetRegistroView: View {
    @State private var repeticiones: String
    @State private var peso: String

    let set: SetRegistro
    let onUpdate: (Int, Double) -> Void

    init(set: SetRegistro, onUpdate: @escaping (Int, Double) -> Void) {
        self.set = set
        self.onUpdate = onUpdate
        _repeticiones = State(initialValue: set.repeticiones > 0 ? "\(set.repeticiones)" : "")
        _peso = State(initialValue: set.peso > 0 ? "\(set.peso)" : "")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Set \(set.numero)")
                    .font(.subheadline.weight(.semibold))

                Spacer()

                HStack(spacing: 16) {
                    HStack(spacing: 6) {
                        Image(systemName: "repeat")
                            .foregroundStyle(.blue)
                        TextField("Reps", text: $repeticiones)
                            .keyboardType(.numberPad)
                            .frame(width: 48)
                            .multilineTextAlignment(.center)
                            .submitLabel(.done)
                            .onChange(of: repeticiones) { _, _ in
                                update()
                            }
                    }

                    HStack(spacing: 6) {
                        Image(systemName: "scalemass")
                            .foregroundStyle(.green)
                        TextField("Peso", text: $peso)
                            .keyboardType(.decimalPad)
                            .frame(width: 64)
                            .multilineTextAlignment(.center)
                            .submitLabel(.done)
                            .onChange(of: peso) { _, _ in
                                update()
                            }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(.gray.opacity(0.2), lineWidth: 1)
        )
    }

    private func update() {
        // No empujes 0 si el usuario está borrando para escribir
        let repes = Int(repeticiones) ?? (repeticiones.isEmpty ? set.repeticiones : 0)
        let pesoValor = Double(peso.replacingOccurrences(of: ",", with: ".")) ?? (peso.isEmpty ? set.peso : 0)
        onUpdate(repes, pesoValor)
    }
}
