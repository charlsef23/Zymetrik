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

    // NUEVO
    @State private var quarterTurns: Int = 0
    @State private var autoFaceCenter: Bool = true

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
                    
                    // Action Buttons (👇 añadido)
                    actionButtons
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Editar Avatar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { onCancel() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") { saveImage() }
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
                        Circle().stroke(Color.white, lineWidth: 4)
                    )
            }
        }
    }
    
    private var filtersSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Filtros").font(.headline).fontWeight(.semibold)
                Spacer()
                if selectedFilter != .none {
                    ResetButton {
                        withAnimation(.easeInOut) { selectedFilter = .none }
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
                            withAnimation(.easeInOut) { selectedFilter = filter }
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
                Text("Ajustes").font(.headline).fontWeight(.semibold)
                Spacer()
                if brightness != 0 || contrast != 1 || saturation != 1 || quarterTurns != 0 {
                    ResetButton {
                        withAnimation(.easeInOut) { resetAdjustments() }
                        HapticManager.shared.lightImpact()
                    }
                }
            }

            // NUEVOS CONTROLES
            Toggle("Auto-centrar en rostro", isOn: $autoFaceCenter)
                .tint(.blue)

            HStack(spacing: 12) {
                Button {
                    quarterTurns = (quarterTurns + 1) % 4
                    HapticManager.shared.selection()
                } label: {
                    Label("Rotar 90º", systemImage: "rotate.right")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }

            // Sliders
            VStack(spacing: 16) {
                AdjustmentSlider(title: "Brillo", value: $brightness, range: -0.5...0.5, icon: "sun.max")
                AdjustmentSlider(title: "Contraste", value: $contrast, range: 0.5...2.0, icon: "circle.lefthalf.filled")
                AdjustmentSlider(title: "Saturación", value: $saturation, range: 0...2.0, icon: "paintpalette")
            }
        }
    }

    // Botones inferiores (Cancelar / Guardar)
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
            .background(isProcessing ? Color.gray : Color.blue)
            .clipShape(Capsule())
            .disabled(isProcessing)
        }
    }
    
    // MARK: - Imagen procesada
    private var processedImage: UIImage {
        // 1) Normaliza orientación
        var image = originalImage.normalizedUp()
        // 2) Filtros/Ajustes
        image = selectedFilter.apply(to: image)
        image = imageProcessor.adjustImage(image, brightness: brightness, contrast: contrast, saturation: saturation)
        // 3) Rotación manual
        image = image.rotated(quarterTurns: quarterTurns)
        // 4) Recorte final
        if autoFaceCenter {
            return ImageCropper.smartCrop(image, to: CGSize(width: 400, height: 400))
        } else {
            return ImageCropper.centerSquare(image, size: 400)
        }
    }

    // MARK: - Acciones
    private func resetAdjustments() {
        brightness = 0
        contrast = 1
        saturation = 1
        quarterTurns = 0
        autoFaceCenter = true
    }

    private func saveImage() {
        guard !isProcessing else { return }
        isProcessing = true
        HapticManager.shared.mediumImpact()
        Task {
            let final = await processImageAsync()
            await MainActor.run {
                onSave(final)
                isProcessing = false
                HapticManager.shared.success()
            }
        }
    }

    private func processImageAsync() async -> UIImage {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let result = self.processedImage
                continuation.resume(returning: result)
            }
        }
    }
}
