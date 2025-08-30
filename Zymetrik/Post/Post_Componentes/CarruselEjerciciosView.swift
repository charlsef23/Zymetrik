import SwiftUI

struct CarruselEjerciciosView: View {
    let ejercicios: [EjercicioPostContenido]
    @Binding var ejercicioSeleccionado: EjercicioPostContenido?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                ForEach(ejercicios) { ejercicioItem in
                    Button {
                        withAnimation(.easeInOut) {
                            ejercicioSeleccionado = ejercicioItem
                        }
                    } label: {
                        ZStack {
                            // Imagen del ejercicio (solo foto)
                            if let urlString = ejercicioItem.imagen_url,
                               let url = URL(string: urlString) {
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .empty:
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color(.secondarySystemBackground))
                                            .overlay(ProgressView())
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .scaledToFill()
                                    case .failure:
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color(.secondarySystemBackground))
                                    @unknown default:
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color(.secondarySystemBackground))
                                    }
                                }
                                .frame(width: 120, height: 120)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .contentShape(RoundedRectangle(cornerRadius: 16))
                            } else {
                                // Placeholder
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(.secondarySystemBackground))
                                    .frame(width: 120, height: 120)
                                    .contentShape(RoundedRectangle(cornerRadius: 16))
                            }
                        }
                        // Marco verde (seleccionado) / gris (no seleccionado)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    ejercicioSeleccionado?.id == ejercicioItem.id
                                    ? Color.green
                                    : Color.gray.opacity(0.3),
                                    lineWidth: ejercicioSeleccionado?.id == ejercicioItem.id ? 3 : 1
                                )
                        )
                        // Glow sutil solo si está seleccionado
                        .shadow(
                            color: ejercicioSeleccionado?.id == ejercicioItem.id
                                ? Color.green.opacity(0.35)
                                : Color.clear,
                            radius: 8, x: 0, y: 4
                        )
                        .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
    }
}
