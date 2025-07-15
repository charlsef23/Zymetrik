import SwiftUI

struct EjercicioRegistroView: View {
    let ejercicio: Ejercicio
    let sets: [SetRegistro]
    let onAddSet: () -> Void
    let onUpdateSet: (Int, Int, Double) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 16) {
                AsyncImage(url: URL(string: ejercicio.imagen_url ?? "")) { phase in
                    switch phase {
                    case .empty:
                        ProgressView().frame(width: 60, height: 60)
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .failure:
                        Image(systemName: "photo")
                            .resizable()
                            .scaledToFit()
                            .padding(16)
                            .foregroundColor(.gray)
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(width: 60, height: 60)
                .background(Color.gray.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 4) {
                    Text(ejercicio.nombre)
                        .font(.headline)
                        .foregroundColor(.black)

                    Text(ejercicio.descripcion)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Spacer()
            }

            VStack(spacing: 8) {
                ForEach(sets.indices, id: \.self) { index in
                    SetRegistroView(
                        set: sets[index],
                        onUpdate: { repeticiones, peso in
                            onUpdateSet(index, repeticiones, peso)
                        }
                    )
                }

                Button(action: onAddSet) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Añadir serie")
                    }
                    .foregroundColor(.black)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        .padding(.horizontal)
    }
}
