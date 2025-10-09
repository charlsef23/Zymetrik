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

    @State private var zoomScale: CGFloat = 1.0
    @State private var lastZoomScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

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
                ZStack {
                    Circle()
                        .fill(Color(.systemGray6))
                        .frame(width: 200, height: 200)
                        .overlay(
                            GeometryReader { geo in
                                let size = min(geo.size.width, geo.size.height)
                                let frameSize = CGSize(width: size, height: size)
                                Image(uiImage: basePreviewImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: frameSize.width, height: frameSize.height)
                                    .scaleEffect(zoomScale)
                                    .offset(offset)
                                    .clipped()
                            }
                            .clipShape(Circle())
                        )
                }
                .frame(width: 200, height: 200)
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                .overlay(Circle().stroke(Color.white, lineWidth: 4))
                .gesture(
                    SimultaneousGesture(
                        DragGesture()
                            .onChanged { value in
                                offset = CGSize(width: lastOffset.width + value.translation.width,
                                                height: lastOffset.height + value.translation.height)
                            }
                            .onEnded { _ in
                                lastOffset = offset
                            },
                        MagnificationGesture()
                            .onChanged { value in
                                zoomScale = max(0.5, min(3.0, lastZoomScale * value))
                            }
                            .onEnded { _ in
                                lastZoomScale = zoomScale
                            }
                    )
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
                if brightness != 0 || contrast != 1 || saturation != 1 || zoomScale != 1.0 || offset != .zero {
                    ResetButton {
                        withAnimation(.easeInOut) { resetAdjustments() }
                        HapticManager.shared.lightImpact()
                    }
                }
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
    
    // MARK: - Imagen para preview sin crop final
    private var basePreviewImage: UIImage {
        var image = originalImage.normalizedUp()
        image = selectedFilter.apply(to: image)
        image = imageProcessor.adjustImage(image, brightness: brightness, contrast: contrast, saturation: saturation)
        return image
    }

    // MARK: - Imagen procesada
    private var processedImage: UIImage {
        // 1) Normaliza orientación
        var image = originalImage.normalizedUp()
        // 2) Filtros/Ajustes
        image = selectedFilter.apply(to: image)
        image = imageProcessor.adjustImage(image, brightness: brightness, contrast: contrast, saturation: saturation)
        // 3) Aplicar recorte circular centrado usando transformaciones del usuario (zoom y desplazamiento)
        let targetSize = CGSize(width: 400, height: 400)
        return ImageCropper.crop(image, to: targetSize, zoomScale: zoomScale, offset: offset)
    }

    // MARK: - Acciones
    private func resetAdjustments() {
        brightness = 0
        contrast = 1
        saturation = 1
        zoomScale = 1.0
        lastZoomScale = 1.0
        offset = .zero
        lastOffset = .zero
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

extension ImageCropper {
    /// Crops the image to a square of target size using a center-based zoom and offset in preview space.
    static func crop(_ image: UIImage, to targetSize: CGSize, zoomScale: CGFloat, offset: CGSize) -> UIImage {
        let baseSize = min(targetSize.width, targetSize.height)
        let canvas = CGSize(width: baseSize, height: baseSize)
        // Render into a square context applying scale and translation
        let renderer = UIGraphicsImageRenderer(size: canvas)
        return renderer.image { ctx in
            ctx.cgContext.setFillColor(UIColor.clear.cgColor)
            ctx.cgContext.fill(CGRect(origin: .zero, size: canvas))
            // Compute drawing rect. Start with fitting the image to canvas, then apply scale and offset.
            let imgSize = image.size
            let scaleToFill = max(canvas.width / imgSize.width, canvas.height / imgSize.height)
            let baseWidth = imgSize.width * scaleToFill
            let baseHeight = imgSize.height * scaleToFill
            var drawRect = CGRect(x: (canvas.width - baseWidth) / 2.0,
                                  y: (canvas.height - baseHeight) / 2.0,
                                  width: baseWidth,
                                  height: baseHeight)
            // Apply user zoom
            let z = max(0.5, min(3.0, zoomScale))
            let center = CGPoint(x: canvas.width/2, y: canvas.height/2)
            // Translate by offset (note: offset is in preview points, same scale as canvas 200pt vs 400px target; we assume proportional)
            let scaleFactor = canvas.width / 200.0 // preview circle is 200pt wide
            let translatedOffset = CGSize(width: offset.width * scaleFactor, height: offset.height * scaleFactor)
            drawRect = drawRect.applying(CGAffineTransform(translationX: translatedOffset.width, y: translatedOffset.height))
            // Apply zoom around center by expanding rect size and shifting origin to keep center stable
            let newSize = CGSize(width: drawRect.width * z, height: drawRect.height * z)
            drawRect = CGRect(x: center.x - newSize.width/2, y: center.y - newSize.height/2, width: newSize.width, height: newSize.height)
            image.draw(in: drawRect)
        }
    }
}
