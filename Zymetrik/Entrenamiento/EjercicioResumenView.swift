import SwiftUI

struct EjercicioResumenView: View {
    let ejercicio: Ejercicio
    @Environment(\.colorScheme) private var scheme

    private var heroBackground: LinearGradient {
        LinearGradient(
            colors: [.indigo, .blue],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var cardBackground: LinearGradient {
        LinearGradient(
            colors: scheme == .dark
            ? [Color(.secondarySystemBackground), Color(.systemBackground)]
            : [Color(.systemBackground), Color(.secondarySystemBackground)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }

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
            .background(heroBackground)
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
        .background(cardBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}
