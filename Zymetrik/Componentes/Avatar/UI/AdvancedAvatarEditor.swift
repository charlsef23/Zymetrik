import SwiftUI
import PhotosUI

struct AdvancedAvatarEditor: View {
    let originalImage: UIImage
    let onSave: (UIImage) -> Void
    let onCancel: () -> Void
    
    @State private var selectedFilter: AvatarFilter = .none
    @State private var brightness: Double = 0
    @State private var contrast: Double = 1
    @State private var saturation: Double = 1
    @State private var isProcessing = false
    
    private let imageProcessor = ImageProcessor()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Preview Section
                    previewSection
                    
                    // Filters Section
                    filtersSection
                    
                    // Adjustments Section
                    adjustmentsSection
                    
                    // Action Buttons
                    actionButtons
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Editar Avatar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        onCancel()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        saveImage()
                    }
                    .disabled(isProcessing)
                }
            }
        }
    }
    
    // MARK: - Subvistas
    
    private var previewSection: some View {
        VStack(spacing: 16) {
            if isProcessing {
                ZStack {
                    Circle()
                        .fill(Color(.systemGray6))
                        .frame(width: 200, height: 200)
                    
                    ProgressView("Procesando...")
                        .tint(.blue)
                }
            } else {
                Image(uiImage: processedImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 200, height: 200)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 4)
                    )
            }
        }
    }
    
    private var filtersSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Filtros")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if selectedFilter != .none {
                    ResetButton {
                        withAnimation(.easeInOut) {
                            selectedFilter = .none
                        }
                        HapticManager.shared.lightImpact()
                    }
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(AvatarFilter.allCases, id: \.self) { filter in
                        FilterButton(
                            filter: filter,
                            isSelected: selectedFilter == filter
                        ) {
                            withAnimation(.easeInOut) {
                                selectedFilter = filter
                            }
                            HapticManager.shared.selection()
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
    
    private var adjustmentsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Ajustes")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if brightness != 0 || contrast != 1 || saturation != 1 {
                    ResetButton {
                        withAnimation(.easeInOut) {
                            resetAdjustments()
                        }
                        HapticManager.shared.lightImpact()
                    }
                }
            }
            
            VStack(spacing: 16) {
                AdjustmentSlider(
                    title: "Brillo",
                    value: $brightness,
                    range: -0.5...0.5,
                    icon: "sun.max"
                )
                
                AdjustmentSlider(
                    title: "Contraste",
                    value: $contrast,
                    range: 0.5...2.0,
                    icon: "circle.lefthalf.filled"
                )
                
                AdjustmentSlider(
                    title: "Saturación",
                    value: $saturation,
                    range: 0...2.0,
                    icon: "paintpalette"
                )
            }
        }
    }
    
    private var actionButtons: some View {
        HStack(spacing: 16) {
            Button("Cancelar") {
                onCancel()
            }
            .font(.body)
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))
            .clipShape(Capsule())
            
            Button("Guardar") {
                saveImage()
            }
            .font(.body)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                isProcessing ? Color.gray : Color.blue
            )
            .clipShape(Capsule())
            .disabled(isProcessing)
        }
    }
    
    // MARK: - Computed Properties
    
    private var processedImage: UIImage {
        var image = selectedFilter.apply(to: originalImage)
        image = imageProcessor.adjustImage(
            image,
            brightness: brightness,
            contrast: contrast,
            saturation: saturation
        )
        return ImageCropper.cropToSquare(image, size: 400)
    }
    
    // MARK: - Methods
    
    private func resetAdjustments() {
        brightness = 0
        contrast = 1
        saturation = 1
    }
    
    private func saveImage() {
        guard !isProcessing else { return }
        
        isProcessing = true
        HapticManager.shared.mediumImpact()
        
        Task {
            let finalImage = await processImageAsync()
            
            await MainActor.run {
                onSave(finalImage)
                isProcessing = false
                HapticManager.shared.success()
            }
        }
    }
    
    private func processImageAsync() async -> UIImage {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let result = self.processedImage
                continuation.resume(returning: result)
            }
        }
    }
}
