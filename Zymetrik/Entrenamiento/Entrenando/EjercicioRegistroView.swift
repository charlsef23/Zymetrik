import SwiftUI

struct EjercicioRegistroView: View {
    let ejercicio: Ejercicio
    let sets: [SetRegistro]
    let onAddSet: () -> Void
    let onUpdateSet: (Int, Int, Double) -> Void
    var onDeleteSet: ((Int) -> Void)? = nil

    private var totalSeries: Int { sets.count }
    private var totalReps: Int { sets.reduce(0) { $0 + $1.repeticiones } }
    private var totalPeso: Double { sets.reduce(0) { $0 + $1.peso } }

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
                            .foregroundStyle(.gray)
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(width: 60, height: 60)
                .background(Color.gray.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 4) {
                    Text(ejercicio.nombre).font(.headline)
                    Text(ejercicio.descripcion)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                Spacer()
            }

            VStack(spacing: 8) {
                ForEach(sets.indices, id: \.self) { index in
                    HStack(spacing: 8) {
                        SetRegistroView(
                            set: sets[index],
                            onUpdate: { repeticiones, peso in
                                onUpdateSet(index, repeticiones, peso)
                            }
                        )

                        if let onDeleteSet {
                            Button {
                                onDeleteSet(index)
                            } label: {
                                Image(systemName: "trash")
                                    .imageScale(.medium)
                                    .padding(10)
                            }
                            .tint(.red)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .accessibilityLabel("Eliminar set \(index + 1)")
                        }
                    }
                }

                HStack {
                    Button(action: onAddSet) {
                        Label("Añadir serie", systemImage: "plus.circle.fill")
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                    }
                    Spacer()
                    Text("\(totalSeries) series · \(totalReps) reps · \(Int(totalPeso)) kg")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        .padding(.horizontal)
    }
}
