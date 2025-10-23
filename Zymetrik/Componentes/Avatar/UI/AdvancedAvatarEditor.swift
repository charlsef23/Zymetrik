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
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { onCancel() } }
                ToolbarItem(placement: .confirmationAction) { Button("Guardar") { saveImage() }.disabled(isProcessing) }
            }
        }
    }

    private var previewSection: some View {
        VStack(spacing: 16) {
            if isProcessing {
                ZStack {
                    Circle().fill(Color(.systemGray6)).frame(width: 200, height: 200)
                    ProgressView("Procesando…").tint(.blue)
                }
            } else {
                ZStack {
                    Circle().fill(Color(.systemGray6)).frame(width: 200, height: 200)
                        .overlay(
                            GeometryReader { geo in
                                let size = min(geo.size.width, geo.size.height)
                                let frame = CGSize(width: size, height: size)
                                Image(uiImage: basePreviewImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: frame.width, height: frame.height)
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
                            .onEnded { _ in lastOffset = offset },
                        MagnificationGesture()
                            .onChanged { value in zoomScale = max(0.5, min(3.0, lastZoomScale * value)) }
                            .onEnded { _ in lastZoomScale = zoomScale }
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
                        FilterButton(filter: filter, isSelected: selectedFilter == filter) {
                            withAnimation(.easeInOut) { selectedFilter = filter }
                            HapticManager.shared.selection()
                        }
                    }
                }.padding(.horizontal, 4)
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
            Button("Cancelar") { onCancel() }
                .font(.body).foregroundColor(.secondary)
                .frame(maxWidth: .infinity).padding(.vertical, 12)
                .background(Color(.systemGray6)).clipShape(Capsule())

            Button("Guardar") { saveImage() }
                .font(.body).fontWeight(.semibold).foregroundColor(.white)
                .frame(maxWidth: .infinity).padding(.vertical, 12)
                .background(isProcessing ? Color.gray : Color.blue)
                .clipShape(Capsule()).disabled(isProcessing)
        }
    }

    private var basePreviewImage: UIImage {
        var img = originalImage.normalizedUp()
        img = selectedFilter.apply(to: img)
        img = imageProcessor.adjustImage(img, brightness: brightness, contrast: contrast, saturation: saturation)
        return img
    }

    // Snap + procesamiento off-main
    private struct Snapshot {
        let original: UIImage; let filter: AvatarFilter
        let brightness: Double; let contrast: Double; let saturation: Double
        let zoomScale: CGFloat; let offset: CGSize
    }

    private func makeSnapshot() -> Snapshot {
        Snapshot(original: originalImage, filter: selectedFilter, brightness: brightness, contrast: contrast, saturation: saturation, zoomScale: zoomScale, offset: offset)
    }

    private func processImageAsync() async -> UIImage {
        let s = await MainActor.run { makeSnapshot() }
        return await withCheckedContinuation { cont in
            DispatchQueue.global(qos: .userInitiated).async {
                var img = s.original.normalizedUp()
                img = s.filter.apply(to: img)
                let proc = ImageProcessor()
                img = proc.adjustImage(img, brightness: s.brightness, contrast: s.contrast, saturation: s.saturation)
                let result = ImageCropper.crop(img, to: .init(width: 400, height: 400), zoomScale: s.zoomScale, offset: s.offset)
                cont.resume(returning: result)
            }
        }
    }

    private func resetAdjustments() {
        brightness = 0; contrast = 1; saturation = 1
        zoomScale = 1; lastZoomScale = 1
        offset = .zero; lastOffset = .zero
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

// Crop helper para preview → imagen final
extension ImageCropper {
    static func crop(_ image: UIImage, to targetSize: CGSize, zoomScale: CGFloat, offset: CGSize) -> UIImage {
        let base = min(targetSize.width, targetSize.height)
        let canvas = CGSize(width: base, height: base)
        let renderer = UIGraphicsImageRenderer(size: canvas)
        return renderer.image { ctx in
            ctx.cgContext.setFillColor(UIColor.clear.cgColor)
            ctx.cgContext.fill(CGRect(origin: .zero, size: canvas))

            let imgSize = image.size
            let scaleToFill = max(canvas.width / imgSize.width, canvas.height / imgSize.height)
            let baseW = imgSize.width * scaleToFill
            let baseH = imgSize.height * scaleToFill
            let z = max(0.5, min(3.0, zoomScale))

            // Origen centrado + offset transformado desde preview (200pt) a canvas
            let center = CGPoint(x: canvas.width/2, y: canvas.height/2)
            let scaleFactor = canvas.width / 200.0
            let tOffset = CGSize(width: offset.width * scaleFactor, height: offset.height * scaleFactor)

            let newW = baseW * z, newH = baseH * z
            let drawRect = CGRect(x: center.x - newW/2 + tOffset.width,
                                  y: center.y - newH/2 + tOffset.height,
                                  width: newW, height: newH)
            image.draw(in: drawRect)
        }
    }
}
