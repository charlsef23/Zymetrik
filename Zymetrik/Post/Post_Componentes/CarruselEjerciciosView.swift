import SwiftUI
import UIKit

struct CarruselEjerciciosView: View {
    let ejercicios: [EjercicioPostContenido]
    @Binding var ejercicioSeleccionado: EjercicioPostContenido?

    /// Cache de imágenes precargadas: key = id de ejercicio
    var preloadedImages: [UUID: UIImage] = [:]

    init(
        ejercicios: [EjercicioPostContenido],
        ejercicioSeleccionado: Binding<EjercicioPostContenido?>,
        preloadedImages: [UUID: UIImage] = [:]
    ) {
        self.ejercicios = ejercicios
        self._ejercicioSeleccionado = ejercicioSeleccionado
        self.preloadedImages = preloadedImages
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                ForEach(ejercicios) { ejercicioItem in
                    Button {
                        withAnimation(.easeInOut) {
                            ejercicioSeleccionado = ejercicioItem
                            UISelectionFeedbackGenerator().selectionChanged()
                        }
                    } label: {
                        ZStack {
                            if let image = preloadedImages[ejercicioItem.id] {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 120, height: 120)
                                    .clipped()
                            } else if let urlString = ejercicioItem.imagen_url,
                                      let url = URL(string: urlString) {
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .empty:
                                        ShimmerRect()
                                            .frame(width: 120, height: 120)
                                    case .success(let image):
                                        image.resizable()
                                            .scaledToFill()
                                            .frame(width: 120, height: 120)
                                            .clipped()
                                    case .failure:
                                        PlaceholderRect(icon: "dumbbell.fill")
                                            .frame(width: 120, height: 120)
                                    @unknown default:
                                        PlaceholderRect(icon: "dumbbell.fill")
                                            .frame(width: 120, height: 120)
                                    }
                                }
                                .transaction { t in t.animation = nil } // avoid fade flicker when switching feeds
                                .id(ejercicioItem.id) // stabilize identity per item
                            } else {
                                PlaceholderRect(icon: "dumbbell.fill")
                                    .frame(width: 120, height: 120)
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(
                                    ejercicioSeleccionado?.id == ejercicioItem.id
                                    ? Color.green
                                    : Color.gray.opacity(0.28),
                                    lineWidth: ejercicioSeleccionado?.id == ejercicioItem.id ? 3 : 1
                                )
                        )
                        .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)
                    }
                    .buttonStyle(.plain)
                    .id("ejercicio-\(ejercicioItem.id.uuidString)")
                    .accessibilityLabel(Text("\(ejercicioItem.nombre)"))
                    .accessibilityAddTraits(ejercicioSeleccionado?.id == ejercicioItem.id ? .isSelected : [])
                }
            }
            .padding(.horizontal, 2)
            .padding(.vertical, 8)
        }
    }
}
