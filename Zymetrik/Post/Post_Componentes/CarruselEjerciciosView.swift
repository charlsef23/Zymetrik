import SwiftUI

struct CarruselEjerciciosView: View {
    let ejercicios: [EjercicioPostContenido]
    @Binding var ejercicioSeleccionado: EjercicioPostContenido?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach(ejercicios) { ejercicioItem in
                    Button {
                        withAnimation(.easeInOut) {
                            ejercicioSeleccionado = ejercicioItem
                        }
                    } label: {
                        VStack(spacing: 12) {
                            // Imagen del ejercicio
                            if let urlString = ejercicioItem.imagen_url, let url = URL(string: urlString) {
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .empty:
                                        ProgressView()
                                            .frame(width: 100, height: 100)
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 100, height: 100)
                                            .clipped()
                                            .cornerRadius(12)
                                    case .failure:
                                        Image(systemName: "photo.fill")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 40, height: 40)
                                            .foregroundColor(.gray)
                                    @unknown default:
                                        EmptyView()
                                    }
                                }
                            } else {
                                Image(systemName: "photo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 40, height: 40)
                                    .foregroundColor(.gray)
                            }

                            // Nombre del ejercicio
                            Text(ejercicioItem.nombre)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .frame(maxWidth: 100)
                        }
                        .padding()
                        .frame(width: 120)
                        .background(
                            ejercicioSeleccionado?.id == ejercicioItem.id
                            ? Color.accentColor.opacity(0.2)
                            : Color(.systemGray6)
                        )
                        .cornerRadius(18)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(
                                    ejercicioSeleccionado?.id == ejercicioItem.id
                                    ? Color.accentColor
                                    : Color.gray.opacity(0.3),
                                    lineWidth: 1
                                )
                        )
                        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
    }
}
