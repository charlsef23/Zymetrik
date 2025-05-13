import SwiftUI
import PhotosUI
import Supabase

// Helper para codificar cualquier tipo
struct AnyEncodable: Encodable {
    private let _encode: (Encoder) throws -> Void

    init<T: Encodable>(_ value: T) {
        self._encode = value.encode
    }

    func encode(to encoder: Encoder) throws {
        try _encode(encoder)
    }
}

struct NewPostSheetView: View {
    @Binding var isPresented: Bool
    @State private var texto: String = ""
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedImage: UIImage? = nil
    @State private var isUploading = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Nueva Publicación")
                    .font(.title2)
                    .bold()

                TextEditor(text: $texto)
                    .frame(height: 120)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)

                if let selectedImage {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                        .cornerRadius(12)
                        .padding(.horizontal)
                }

                PhotosPicker(selection: $selectedItem, matching: .images) {
                    HStack {
                        Image(systemName: "photo")
                        Text(selectedImage == nil ? "Seleccionar imagen" : "Cambiar imagen")
                    }
                    .foregroundColor(.blue)
                }
                .onChange(of: selectedItem) {
                    Task {
                        if let data = try? await selectedItem?.loadTransferable(type: Data.self),
                           let uiImage = UIImage(data: data) {
                            selectedImage = uiImage
                        }
                    }
                }

                if let error {
                    Text("❌ \(error)")
                        .foregroundColor(.red)
                }

                Button {
                    Task {
                        await publicar()
                    }
                } label: {
                    HStack {
                        if isUploading {
                            ProgressView()
                        } else {
                            Image(systemName: "paperplane.fill")
                            Text("Publicar")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(texto.isEmpty ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(texto.isEmpty || isUploading)

                Spacer()
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        isPresented = false
                    }
                }
            }
        }
    }

    func publicar() async {
        isUploading = true
        error = nil

        do {
            var imageUrl: String? = nil

            if let image = selectedImage {
                let fileName = UUID().uuidString
                imageUrl = try await SupabaseImageUploader.uploadImage(image, fileName: fileName)
            }

            let user = try await SupabaseManager.shared.client.auth.session.user

            var postData: [String: AnyEncodable] = [
                "user_id": AnyEncodable(user.id.uuidString),
                "content": AnyEncodable(texto)
            ]

            if let imageUrl {
                postData["image_url"] = AnyEncodable(imageUrl)
            }

            try await SupabaseManager.shared.client
                .from("posts")
                .insert(postData)
                .execute()

            isPresented = false
        } catch {
            self.error = error.localizedDescription
        }

        isUploading = false
    }
}

