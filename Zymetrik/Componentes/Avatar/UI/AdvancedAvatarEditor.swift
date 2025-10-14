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
                    previewSection
                    filtersSection
                    adjustmentsSection
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
                                offset = CGSize(
                                    width: lastOffset.width + value.translation.width,
                                    height: lastOffset.height + value.translation.height
                                )
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

            VStack(spacing: 16) {
                AdjustmentSlider(title: "Brillo", value: $brightness, range: -0.5...0.5, icon: "sun.max")
                AdjustmentSlider(title: "Contraste", value: $contrast, range: 0.5...2.0, icon: "circle.lefthalf.filled")
                AdjustmentSlider(title: "Saturación", value: $saturation, range: 0...2.0, icon: "paintpalette")
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
            .background(isProcessing ? Color.gray : Color.blue)
            .clipShape(Capsule())
            .disabled(isProcessing)
        }
    }

    // MARK: - Imagen para preview (en main)

    private var basePreviewImage: UIImage {
        var image = originalImage.normalizedUp()
        image = selectedFilter.apply(to: image)
        image = imageProcessor.adjustImage(image, brightness: brightness, contrast: contrast, saturation: saturation)
        return image
    }

    // MARK: - Snapshot y procesado en background

    private struct Snapshot {
        let originalImage: UIImage
        let filter: AvatarFilter
        let brightness: Double
        let contrast: Double
        let saturation: Double
        let zoomScale: CGFloat
        let offset: CGSize
    }

    // No es async; lo ejecutaremos dentro de `MainActor.run { ... }`
    private func makeSnapshot() -> Snapshot {
        Snapshot(
            originalImage: originalImage,
            filter: selectedFilter,
            brightness: brightness,
            contrast: contrast,
            saturation: saturation,
            zoomScale: zoomScale,
            offset: offset
        )
    }

    private func processImageAsync() async -> UIImage {
        // ✅ Captura de estado segura en el MainActor
        let s = await MainActor.run { makeSnapshot() }

        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                var img = s.originalImage.normalizedUp()
                img = s.filter.apply(to: img)

                let processor = ImageProcessor()
                img = processor.adjustImage(
                    img,
                    brightness: s.brightness,
                    contrast: s.contrast,
                    saturation: s.saturation
                )

                let targetSize = CGSize(width: 400, height: 400)
                let result = ImageCropper.crop(
                    img,
                    to: targetSize,
                    zoomScale: s.zoomScale,
                    offset: s.offset
                )
                continuation.resume(returning: result)
            }
        }
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
}

// MARK: - Crop helper

extension ImageCropper {
    /// Crops the image to a square of target size using a center-based zoom and offset in preview space.
    static func crop(_ image: UIImage, to targetSize: CGSize, zoomScale: CGFloat, offset: CGSize) -> UIImage {
        let baseSize = min(targetSize.width, targetSize.height)
        let canvas = CGSize(width: baseSize, height: baseSize)

        let renderer = UIGraphicsImageRenderer(size: canvas)
        return renderer.image { ctx in
            ctx.cgContext.setFillColor(UIColor.clear.cgColor)
            ctx.cgContext.fill(CGRect(origin: .zero, size: canvas))

            let imgSize = image.size
            let scaleToFill = max(canvas.width / imgSize.width, canvas.height / imgSize.height)
            let baseWidth = imgSize.width * scaleToFill
            let baseHeight = imgSize.height * scaleToFill

            var drawRect = CGRect(
                x: (canvas.width - baseWidth) / 2.0,
                y: (canvas.height - baseHeight) / 2.0,
                width: baseWidth,
                height: baseHeight
            )

            // Ajuste de desplazamiento (offset) — el preview es 200pt, el destino 400px
            let z = max(0.5, min(3.0, zoomScale))
            let center = CGPoint(x: canvas.width/2, y: canvas.height/2)
            let scaleFactor = canvas.width / 200.0
            let translatedOffset = CGSize(width: offset.width * scaleFactor, height: offset.height * scaleFactor)
            drawRect = drawRect.applying(CGAffineTransform(translationX: translatedOffset.width, y: translatedOffset.height))

            // Zoom alrededor del centro
            let newSize = CGSize(width: drawRect.width * z, height: drawRect.height * z)
            drawRect = CGRect(x: center.x - newSize.width/2, y: center.y - newSize.height/2, width: newSize.width, height: newSize.height)

            image.draw(in: drawRect)
        }
    }
}
