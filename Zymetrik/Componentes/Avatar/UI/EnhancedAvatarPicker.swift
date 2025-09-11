import SwiftUI
import PhotosUI

struct EnhancedAvatarPicker: View {
    let currentImageURL: String?
    let onImageSelected: (UIImage) -> Void
    let size: CGFloat
    
    @State private var showEditor = false
    @State private var selectedImage: UIImage?
    @State private var showPhotoPicker = false
    @State private var selectedItem: PhotosPickerItem?
    @State private var isLoading = false
    
    var body: some View {
        Button {
            showPhotoPicker = true
            HapticManager.shared.lightImpact()
        } label: {
            ZStack(alignment: .bottomTrailing) {
                if isLoading {
                    loadingAvatar
                } else {
                    AvatarAsyncImage(
                        url: currentImageURL.validHTTPURL,
                        size: size,
                        showBorder: true,
                        borderColor: .white,
                        borderWidth: 3
                    )
                }
                editButton
            }
        }
        .buttonStyle(.plain)
        .photosPicker(
            isPresented: $showPhotoPicker,
            selection: $selectedItem,
            matching: .images
        )
        .onChange(of: selectedItem) { _, newValue in
            if let item = newValue {
                Task {
                    await loadImage(from: item)
                }
            }
        }
        .sheet(isPresented: $showEditor) {
            if let image = selectedImage {
                AdvancedAvatarEditor(
                    originalImage: image,
                    onSave: { editedImage in
                        onImageSelected(editedImage)
                        showEditor = false
                        HapticManager.shared.success()
                    },
                    onCancel: {
                        showEditor = false
                        HapticManager.shared.lightImpact()
                    }
                )
            }
        }
    }
    
    private var loadingAvatar: some View {
        Circle()
            .fill(Color(.systemGray6))
            .frame(width: size, height: size)
            .overlay(
                ProgressView()
                    .scaleEffect(0.8)
                    .tint(.blue)
            )
    }
    
    private var editButton: some View {
        ZStack {
            Circle()
                .fill(.white)
                .frame(width: size * 0.28, height: size * 0.28)
                .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
            
            Circle()
                .fill(.blue)
                .frame(width: size * 0.22, height: size * 0.22)
            
            Image(systemName: isLoading ? "hourglass" : "camera.fill")
                .font(.system(size: size * 0.09, weight: .medium))
                .foregroundColor(.white)
        }
        .offset(x: -size * 0.05, y: -size * 0.05)
    }
    
    private func loadImage(from item: PhotosPickerItem) async {
        await MainActor.run { isLoading = true }
        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let uiImage = UIImage(data: data) else {
                await MainActor.run { isLoading = false }
                return
            }
            await MainActor.run {
                selectedImage = uiImage
                isLoading = false
                showEditor = true
                HapticManager.shared.lightImpact()
            }
        } catch {
            await MainActor.run { isLoading = false }
            HapticManager.shared.error()
        }
    }
}
