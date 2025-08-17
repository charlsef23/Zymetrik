import SwiftUI

struct EjercicioResumenView: View {
    let ejercicio: Ejercicio

    var body: some View {
        HStack(spacing: 16) {
            AsyncImage(url: URL(string: ejercicio.imagen_url ?? "")) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(width: 60, height: 60)
                case .success(let image):
                    image.resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .clipped()
                case .failure:
                    Image(systemName: "photo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .padding(10)
                        .foregroundColor(.gray)
                @unknown default:
                    EmptyView()
                }
            }
            .background(Color.gray.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 4) {
                Text(ejercicio.nombre)
                    .font(.headline)
                Text(ejercicio.descripcion)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding()
        .background(Color.white) // si usas modo oscuro, considera Color(.systemBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        // ⬇️ En List mejor sin padding horizontal extra
        //.padding(.horizontal)
    }
}

