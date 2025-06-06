// CrearPostView.swift (actualizado: picker corregido)
import SwiftUI
import PhotosUI

struct CrearPostView: View {
    @Environment(\.dismiss) var dismiss

    @State private var lugar: String = ""
    @State private var selectedItem: PhotosPickerItem?
    @State private var previewImage: Image?
    @State private var ejercicios: [String] = ["Ejercicio", "Ejercicio", "Ejercicio"]
    @State private var puedeCompartir = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Campo lugar
                VStack(alignment: .leading, spacing: 6) {
                    Text("Añadir un lugar")
                        .font(.subheadline)
                        .foregroundColor(.gray)

                    TextField("", text: $lugar)
                        .padding(10)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }

                // Área foto/video
                ZStack {
                    Rectangle()
                        .fill(Color(.systemGray6))
                        .frame(height: 200)
                        .cornerRadius(12)

                    if let image = previewImage {
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(height: 200)
                            .clipped()
                            .cornerRadius(12)
                    } else {
                        Text("Fotos o video")
                            .foregroundColor(.gray)
                    }
                }

                // Botón para seleccionar foto/video
                PhotosPicker(selection: $selectedItem, matching: .any(of: [.images, .videos])) {
                    HStack {
                        Image(systemName: "photo")
                        Text("Seleccionar imagen o video")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }

                // Botones de ejercicios
                HStack(spacing: 12) {
                    ForEach(ejercicios, id: \.self) { nombre in
                        Text(nombre)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color(.systemGray5))
                            .cornerRadius(8)
                    }
                }

                // Botón compartir
                Button("Compartir") {
                    // Acción de compartir
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(puedeCompartir ? Color.blue : Color.blue.opacity(0.3))
                .foregroundColor(.white)
                .cornerRadius(10)
                .disabled(!puedeCompartir)

                Spacer()
            }
            .padding()
            .navigationTitle("Añadir publicación")   
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: selectedItem) { oldItem, newItem in
                Task {
                    guard let item = newItem else { return }

                    if let data = try? await item.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        previewImage = Image(uiImage: uiImage)
                        puedeCompartir = true
                    }
                }
            }
        }
    }
}

#Preview {
    CrearPostView()
}
