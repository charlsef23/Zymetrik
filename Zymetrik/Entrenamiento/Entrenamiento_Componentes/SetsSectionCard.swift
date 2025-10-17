import SwiftUI

struct SetsSectionCard: View {
    let titulo: String
    let sets: [SetRegistro]

    // Callbacks
    let onAddSet: () -> Void
    let onUpdateSet: (Int, Int, Double) -> Void
    let onDeleteSet: (Int) -> Void
    let onDuplicateSet: (Int) -> Void

    private var totalSeries: Int { sets.count }
    private var totalReps: Int { sets.reduce(0) { $0 + $1.repeticiones } }
    private var totalKg: Double { sets.reduce(0) { $0 + (Double($1.repeticiones) * $1.peso) } }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack(spacing: 12) {
                Text(titulo)
                    .font(.system(.headline, design: .rounded))
                Spacer()
                Button {
                    onAddSet()
                } label: {
                    Label("Añadir", systemImage: "plus.circle.fill")
                        .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }

            // Lista
            VStack(spacing: 12) {
                ForEach(sets.indices, id: \.self) { idx in
                    UltraCleanSetRow(
                        index: idx,
                        set: sets[idx],
                        onChange: { reps, kg in onUpdateSet(idx, reps, kg) },
                        onDelete: { onDeleteSet(idx) },
                        onDuplicate: { onDuplicateSet(idx) }
                    )
                }
            }

            // Totales
            HStack {
                let kgText = String(format: "%.1f", totalKg)
                Text("\(totalSeries) series · \(totalReps) reps · \(kgText) kg")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Spacer()
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.secondary.opacity(0.12), lineWidth: 1)
        )
    }
}

// MARK: - Fila Ultra-Clean (± + edición manual por tap)

private struct UltraCleanSetRow: View {
    let index: Int
    @ObservedObject var set: SetRegistro

    let onChange: (Int, Double) -> Void
    let onDelete: () -> Void
    let onDuplicate: () -> Void

    private let repsStep = 1
    private let kgStep: Double = 2.5

    var body: some View {
        VStack(spacing: 12) {
            // Top bar
            HStack {
                Text("Set \(set.numero)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                HStack(spacing: 16) {
                    Button(action: onDuplicate) {
                        Image(systemName: "plus.square.on.square")
                    }
                    .foregroundStyle(.blue)

                    Button(role: .destructive, action: onDelete) {
                        Image(systemName: "trash")
                    }
                    .foregroundStyle(.red)
                }
            }

            // Métricas
            HStack(spacing: 12) {
                MetricPillInt(
                    title: "Reps",
                    titleColor: .blue,
                    value: set.repeticiones,
                    range: 0...500,
                    step: repsStep,
                    minusAction: {
                        // Arreglo: siempre dispara onChange aunque ya esté en 0
                        let new = max(0, set.repeticiones - repsStep)
                        set.repeticiones = new
                        onChange(set.repeticiones, set.peso)
                    },
                    plusAction: {
                        let new = min(500, set.repeticiones + repsStep)
                        set.repeticiones = new
                        onChange(set.repeticiones, set.peso)
                    },
                    commitAction: { newValue in
                        let clamped = min(500, max(0, newValue))
                        set.repeticiones = clamped
                        onChange(set.repeticiones, set.peso)
                    }
                )

                MetricPillDouble(
                    title: "Kg",
                    titleColor: .green,
                    value: set.peso,
                    range: 0...2000,
                    step: kgStep,
                    decimals: 1,
                    minusAction: {
                        let new = max(0, (set.peso - kgStep).roundedTo(1))
                        set.peso = new
                        onChange(set.repeticiones, set.peso)
                    },
                    plusAction: {
                        let new = min(2000, (set.peso + kgStep).roundedTo(1))
                        set.peso = new
                        onChange(set.repeticiones, set.peso)
                    },
                    commitAction: { newValue in
                        let clamped = min(2000, max(0, newValue)).roundedTo(1)
                        set.peso = clamped
                        onChange(set.repeticiones, set.peso)
                    }
                )
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [Color(.secondarySystemBackground), Color(.systemBackground)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.secondary.opacity(0.08), lineWidth: 1)
        )
    }
}

// MARK: - Píldora INT (± + edición manual)

private struct MetricPillInt: View {
    let title: String
    let titleColor: Color
    let value: Int
    let range: ClosedRange<Int>
    let step: Int
    let minusAction: () -> Void
    let plusAction: () -> Void
    let commitAction: (Int) -> Void

    @State private var editing = false
    @State private var tempText = ""
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(titleColor)

            HStack(spacing: 8) {
                Button(action: minusAction) {
                    Image(systemName: "minus")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(titleColor)
                }
                .frame(width: 28, height: 28)
                .background(Circle().strokeBorder(titleColor.opacity(0.5), lineWidth: 1))

                Group {
                    if editing {
                        TextField("0", text: $tempText)
                            .focused($focused)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.plain)
                            .multilineTextAlignment(.center)
                            .font(.system(.body, design: .monospaced).weight(.semibold))
                            .frame(minWidth: 44)
                            .onAppear {
                                tempText = "\(value)"
                                // Foco al mostrar
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                    focused = true
                                }
                            }
                            .toolbar {
                                ToolbarItemGroup(placement: .keyboard) {
                                    Spacer()
                                    Button("Hecho") {
                                        commitInt()
                                    }
                                }
                            }
                    } else {
                        Text("\(value)")
                            .font(.system(.body, design: .monospaced).weight(.semibold))
                            .frame(minWidth: 44)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                editing = true
                            }
                    }
                }

                Button(action: plusAction) {
                    Image(systemName: "plus")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(titleColor)
                }
                .frame(width: 28, height: 28)
                .background(Circle().strokeBorder(titleColor.opacity(0.5), lineWidth: 1))
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .background(Capsule().fill(Color(.systemBackground)))
            .overlay(Capsule().strokeBorder(titleColor.opacity(0.3), lineWidth: 1))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func commitInt() {
        let filtered = tempText.filter { "0123456789".contains($0) }
        let parsed = Int(filtered) ?? value
        let clamped = min(range.upperBound, max(range.lowerBound, parsed))
        commitAction(clamped)
        editing = false
        focused = false
    }
}

// MARK: - Píldora DOUBLE (± + edición manual)

private struct MetricPillDouble: View {
    let title: String
    let titleColor: Color
    let value: Double
    let range: ClosedRange<Double>
    let step: Double
    let decimals: Int
    let minusAction: () -> Void
    let plusAction: () -> Void
    let commitAction: (Double) -> Void

    @State private var editing = false
    @State private var tempText = ""
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(titleColor)

            HStack(spacing: 8) {
                Button(action: minusAction) {
                    Image(systemName: "minus")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(titleColor)
                }
                .frame(width: 28, height: 28)
                .background(Circle().strokeBorder(titleColor.opacity(0.5), lineWidth: 1))

                Group {
                    if editing {
                        TextField("0.0", text: $tempText)
                            .focused($focused)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.plain)
                            .multilineTextAlignment(.center)
                            .font(.system(.body, design: .monospaced).weight(.semibold))
                            .frame(minWidth: 44)
                            .onAppear {
                                tempText = formatValue(value)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                    focused = true
                                }
                            }
                            .toolbar {
                                ToolbarItemGroup(placement: .keyboard) {
                                    Spacer()
                                    Button("Hecho") {
                                        commitDouble()
                                    }
                                }
                            }
                    } else {
                        Text(formatValue(value))
                            .font(.system(.body, design: .monospaced).weight(.semibold))
                            .frame(minWidth: 44)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                editing = true
                            }
                    }
                }

                Button(action: plusAction) {
                    Image(systemName: "plus")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(titleColor)
                }
                .frame(width: 28, height: 28)
                .background(Circle().strokeBorder(titleColor.opacity(0.5), lineWidth: 1))
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .background(Capsule().fill(Color(.systemBackground)))
            .overlay(Capsule().strokeBorder(titleColor.opacity(0.3), lineWidth: 1))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func commitDouble() {
        // Admite coma o punto
        let normalized = tempText.replacingOccurrences(of: ",", with: ".")
        let parsed = Double(normalized) ?? value
        let clamped = min(range.upperBound, max(range.lowerBound, parsed)).roundedTo(decimals)
        commitAction(clamped)
        editing = false
        focused = false
    }

    private func formatValue(_ v: Double) -> String {
        if decimals == 0 || v.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(v))"
        } else {
            return String(format: "%.\(decimals)f", v)
        }
    }
}

// MARK: - Helpers

private extension Double {
    func roundedTo(_ places: Int) -> Double {
        let p = pow(10.0, Double(places))
        return (self * p).rounded() / p
    }
}
