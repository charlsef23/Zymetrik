import SwiftUI

struct BodyPartFilterChips: View {
    let partesDisponibles: [String]
    @Binding var seleccionadas: Set<String>

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(partesDisponibles, id: \.self) { parte in
                    let isOn = seleccionadas.contains(parte)
                    Button {
                        if isOn { seleccionadas.remove(parte) } else { seleccionadas.insert(parte) }
                    } label: {
                        HStack(spacing: 6) {
                            Text(parte)
                                .font(.subheadline.weight(.semibold))
                            if isOn { Image(systemName: "checkmark.circle.fill").font(.caption2) }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(isOn ? Color.accentColor.opacity(0.18) : Color(.systemGray6))
                        )
                        .overlay(
                            Capsule().stroke(isOn ? Color.accentColor : Color.gray.opacity(0.35), lineWidth: 1)
                        )
                    }
                    .foregroundColor(isOn ? .accentColor : .primary)
                }

                if !seleccionadas.isEmpty {
                    Button {
                        seleccionadas.removeAll()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "xmark.circle.fill")
                            Text("Limpiar")
                        }
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(Color.red.opacity(0.12)))
                        .overlay(Capsule().stroke(Color.red.opacity(0.5), lineWidth: 1))
                        .foregroundColor(.red)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.top, 4)
    }
}
