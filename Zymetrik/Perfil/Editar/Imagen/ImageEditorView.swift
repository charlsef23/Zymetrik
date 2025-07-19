import SwiftUI

struct ImageEditorView: View {
    let originalImage: UIImage
    var onConfirm: (UIImage) -> Void
    var onCancel: () -> Void

    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var rotation: Angle = .zero
    @State private var lastRotation: Angle = .zero

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                ZStack {
                    Color.black.edgesIgnoringSafeArea(.all)

                    Image(uiImage: originalImage)
                        .resizable()
                        .scaledToFit()
                        .scaleEffect(scale)
                        .rotationEffect(rotation)
                        .offset(offset)
                        .gesture(
                            SimultaneousGesture(
                                MagnificationGesture()
                                    .onChanged { value in
                                        scale = value
                                    },
                                DragGesture()
                                    .onChanged { value in
                                        offset = CGSize(
                                            width: lastOffset.width + value.translation.width,
                                            height: lastOffset.height + value.translation.height
                                        )
                                    }
                                    .onEnded { _ in
                                        lastOffset = offset
                                    }
                            )
                            .simultaneously(with:
                                RotationGesture()
                                    .onChanged { angle in
                                        rotation = lastRotation + angle
                                    }
                                    .onEnded { angle in
                                        lastRotation += angle
                                    }
                            )
                        )
                        .frame(width: geo.size.width, height: geo.size.width) // Recorte cuadrado

                    Rectangle()
                        .strokeBorder(Color.white.opacity(0.7), lineWidth: 2)
                        .frame(width: geo.size.width, height: geo.size.width)
                }
            }
            .navigationTitle("Ajustar imagen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        onCancel()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Usar") {
                        let editedImage = renderEditedImage()
                        onConfirm(editedImage)
                    }
                }
            }
        }
    }

    // Renderizar la imagen ajustada
    private func renderEditedImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 500, height: 500))
        return renderer.image { _ in
            let context = UIGraphicsGetCurrentContext()!
            context.translateBy(x: 250 + offset.width, y: 250 + offset.height)
            context.rotate(by: CGFloat(rotation.radians))
            context.scaleBy(x: scale, y: scale)

            let imageSize = originalImage.size
            let rect = CGRect(x: -imageSize.width/2, y: -imageSize.height/2, width: imageSize.width, height: imageSize.height)
            originalImage.draw(in: rect)
        }
    }
}
