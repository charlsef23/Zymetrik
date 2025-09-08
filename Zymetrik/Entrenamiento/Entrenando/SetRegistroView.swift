import SwiftUI

struct SetRegistroRow: View {
    @ObservedObject var set: SetRegistro
    let onUpdate: (Int, Double) -> Void
    let onDelete: (() -> Void)?
    let onDuplicate: (() -> Void)?
    @State private var isCompleted = false
    @FocusState private var pesoFocused: Bool

    var body: some View {
        HStack(spacing: 10) {
            // Nº de set
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(isCompleted ? Color.green.opacity(0.15) : Color.secondary.opacity(0.12))
                Text("\(set.numero)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
            }
            .frame(width: 44, height: 44)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isCompleted ? Color.green.opacity(0.55) : Color.secondary.opacity(0.2), lineWidth: 1)
            )

            // Reps
            HStack(spacing: 6) {
                Label("Reps", systemImage: "repeat")
                    .labelStyle(.iconOnly)
                    .foregroundStyle(.blue)
                Stepper(value: Binding(
                    get: { set.repeticiones },
                    set: { new in
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        set.repeticiones = max(0, new)
                        onUpdate(set.repeticiones, set.peso)
                    }
                ), in: 0...300) {
                    Text("\(set.repeticiones)")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .frame(minWidth: 34, alignment: .trailing)
                }
                .labelsHidden()
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            // Peso
            HStack(spacing: 6) {
                Label("Peso", systemImage: "scalemass")
                    .labelStyle(.iconOnly)
                    .foregroundStyle(.green)
                TextField("0.0", value: Binding(
                    get: { set.peso },
                    set: { new in
                        set.peso = max(0, new.rounded(toPlaces: 2))
                        onUpdate(set.repeticiones, set.peso)
                    }
                ), format: .number.precision(.fractionLength(0...2)))
                    .focused($pesoFocused)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 64)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .toolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            Spacer()
                            Button("Hecho") { pesoFocused = false }
                        }
                    }
                Text("kg")
                    .foregroundStyle(.secondary)
                    .font(.footnote)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            Spacer(minLength: 0)

            // Completar set
            Button {
                isCompleted.toggle()
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(isCompleted ? .success : .warning)
            } label: {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isCompleted ? .green : .secondary)
            }
            .accessibilityLabel(isCompleted ? "Set completado" : "Marcar set como completado")
        }
        .padding(10)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.black.opacity(0.05), lineWidth: 1)
        )
        .contentShape(Rectangle())
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            if let onDelete {
                Button(role: .destructive) { onDelete() } label: {
                    Label("Borrar", systemImage: "trash")
                }
            }
            if let onDuplicate {
                Button { onDuplicate() } label: {
                    Label("Duplicar", systemImage: "plus.square.on.square")
                }.tint(.blue)
            }
        }
        // Presets rápidos
        .contextMenu {
            Button("x5 reps") {
                let h = UIImpactFeedbackGenerator(style: .soft); h.impactOccurred()
                set.repeticiones += 5
                onUpdate(set.repeticiones, set.peso)
            }
            Button("x10 reps") {
                let h = UIImpactFeedbackGenerator(style: .soft); h.impactOccurred()
                set.repeticiones += 10
                onUpdate(set.repeticiones, set.peso)
            }
            Divider()
            Button("+2.5 kg") {
                let h = UIImpactFeedbackGenerator(style: .soft); h.impactOccurred()
                set.peso = (set.peso + 2.5).rounded(toPlaces: 2)
                onUpdate(set.repeticiones, set.peso)
            }
            Button("+5 kg") {
                let h = UIImpactFeedbackGenerator(style: .soft); h.impactOccurred()
                set.peso = (set.peso + 5).rounded(toPlaces: 2)
                onUpdate(set.repeticiones, set.peso)
            }
        }
    }
}

private extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let p = pow(10.0, Double(places))
        return (self * p).rounded() / p
    }
}
