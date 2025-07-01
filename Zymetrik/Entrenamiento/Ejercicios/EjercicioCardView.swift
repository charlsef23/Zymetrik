import SwiftUI

struct EjercicioCardView: View {
    let ejercicio: Ejercicio
    let tipoSeleccionado: String
    let seleccionado: Bool

    var body: some View {
        HStack(spacing: 16) {
            AsyncImage(url: URL(string: ejercicio.imagen_url ?? "")) { phase in
                switch phase {
                case .empty:
                    ProgressView().frame(width: 70, height: 70)
                case .success(let image):
                    image.resizable().scaledToFill()
                case .failure:
                    Image(systemName: "photo")
                        .resizable()
                        .scaledToFit()
                        .padding(20)
                        .foregroundColor(.gray)
                @unknown default:
                    EmptyView()
                }
            }
            .frame(width: 70, height: 70)
            .background(Color.gray.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(ejercicio.nombre)
                    .font(.headline)
                    .foregroundColor(.black)
                Text(ejercicio.descripcion)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            if seleccionado {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(fondoTarjeta(for: tipoSeleccionado))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.06), radius: 5, x: 0, y: 3)
        .padding(.horizontal)
    }

    func fondoTarjeta(for tipo: String) -> Color {
        switch tipo {
        case "Gimnasio":
            return Color.blue.opacity(0.1)
        case "Cardio":
            return Color.red.opacity(0.1)
        case "Funcional":
            return Color.green.opacity(0.1)
        default:
            return Color.gray.opacity(0.1)
        }
    }
}
