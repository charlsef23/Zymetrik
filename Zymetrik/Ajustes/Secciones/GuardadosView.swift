import SwiftUI

struct GuardadosView: View {
    // Placeholder: en el futuro podrías separar por categorías: posts, entrenamientos, rutinas
    let elementosGuardados: [String] = [
        "Entrenamiento de pierna", "Post motivacional", "Rutina semanal"
    ]

    var body: some View {
        VStack {
            if elementosGuardados.isEmpty {
                Text("Todavía no has guardado nada.")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(elementosGuardados, id: \.self) { item in
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                                .frame(height: 120)
                                .overlay(
                                    HStack {
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text(item)
                                                .font(.headline)
                                            Text("Ver más detalles")
                                                .font(.subheadline)
                                                .foregroundColor(.blue)
                                        }
                                        Spacer()
                                    }
                                    .padding()
                                )
                                .padding(.horizontal)
                        }
                    }
                    .padding(.top)
                }
            }
        }
        .navigationTitle("Guardados")
    }
}

#Preview {
    GuardadosView()
}
