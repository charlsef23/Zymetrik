import SwiftUI
import UIKit
import ImageIO
import MobileCoreServices

struct CarruselEjerciciosView: View {
    let ejercicios: [EjercicioPostContenido]
    @Binding var ejercicioSeleccionado: EjercicioPostContenido?

    /// Cache opcional de imágenes precargadas: key = id de ejercicio
    var preloadedImages: [UUID: UIImage] = [:]

    init(
        ejercicios: [EjercicioPostContenido],
        ejercicioSeleccionado: Binding<EjercicioPostContenido?>,
        preloadedImages: [UUID: UIImage] = [:]
    ) {
        self.ejercicios = ejercicios
        self._ejercicioSeleccionado = ejercicioSeleccionado
        self.preloadedImages = preloadedImages
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                ForEach(ejercicios) { ejercicioItem in
                    Button {
                        withAnimation(.easeInOut) {
                            ejercicioSeleccionado = ejercicioItem
                            UISelectionFeedbackGenerator().selectionChanged()
                        }
                    } label: {
                        ThumbCard(
                            id: ejercicioItem.id,
                            urlString: ejercicioItem.imagen_url,
                            preloaded: preloadedImages[ejercicioItem.id]
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(
                                    ejercicioSeleccionado?.id == ejercicioItem.id
                                    ? Color.green
                                    : Color.gray.opacity(0.28),
                                    lineWidth: ejercicioSeleccionado?.id == ejercicioItem.id ? 3 : 1
                                )
                        )
                        .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)
                    }
                    .buttonStyle(.plain)
                    .id("ejercicio-\(ejercicioItem.id.uuidString)")
                    .accessibilityLabel(Text("\(ejercicioItem.nombre)"))
                    .accessibilityAddTraits(ejercicioSeleccionado?.id == ejercicioItem.id ? .isSelected : [])
                }
            }
            .padding(.horizontal, 2)
            .padding(.vertical, 8)
        }
    }
}

// MARK: - Thumb (con normalización de URL, downsampling y retry)
private struct ThumbCard: View {
    let id: UUID
    let urlString: String?
    let preloaded: UIImage?

    @StateObject private var loader = ImageCellLoader()

    var body: some View {
        ZStack {
            switch loader.state {
            case .idle:
                if let img = preloaded {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                } else {
                    CarruselShimmerRect()
                }
            case .loading:
                CarruselShimmerRect()
            case .success(let image):
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            case .failure:
                CarruselPlaceholderRect(icon: "dumbbell.fill")
                    .overlay(
                        VStack {
                            Spacer()
                            Text("Toca para reintentar")
                                .font(.caption2).foregroundStyle(.secondary)
                                .padding(.bottom, 6)
                        }
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        Task { await loader.retry() }   // ✅ Swift 6: await a función async
                    }
            }
        }
        .frame(width: 120, height: 120)
        .clipped()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .onAppear {
            if case .idle = loader.state {
                if let pre = preloaded {
                    loader.inject(image: pre)
                } else {
                    Task {
                        await loader.load(from: urlString, targetSize: CGSize(width: 120, height: 120)) // ✅ await
                    }
                }
            }
        }
        .onDisappear {
            loader.cancel()
        }
    }
}

// MARK: - Loader por celda (URL normalizada + downsample)
@MainActor
private final class ImageCellLoader: ObservableObject {
    enum State {
        case idle
        case loading
        case success(UIImage)
        case failure
    }

    @Published var state: State = .idle
    private var currentTask: Task<Void, Never>?
    private var lastURLString: String?

    func inject(image: UIImage) {
        state = .success(image)
    }

    /// Versión async: se **debe** invocar con `await` en Swift 6
    func load(from urlString: String?, targetSize: CGSize) async {
        guard let url = makeURL(from: urlString) else {
            state = .failure
            return
        }
        lastURLString = urlString
        state = .loading

        // Cancelar tarea anterior y lanzar nueva
        currentTask?.cancel()
        currentTask = Task { [weak self] in
            guard let self else { return }
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if Task.isCancelled { return }

                if let image = downsampleImage(data: data, to: targetSize, scale: UIScreen.main.scale) {
                    await MainActor.run { self.state = .success(image) }
                } else {
                    await MainActor.run { self.state = .failure }
                }
            } catch {
                if Task.isCancelled { return }
                await MainActor.run { self.state = .failure }
            }
        }

        // Esperar a que termine para que el caller no continúe “en seco”
        await currentTask?.value
    }

    /// Reintento async (usa la última URL)
    func retry() async {
        guard case .failure = state else { return }
        state = .idle
        await load(from: lastURLString, targetSize: CGSize(width: 120, height: 120))
    }

    func cancel() {
        currentTask?.cancel()
    }
}

// MARK: - Helpers

/// Normaliza la URL: codifica espacios/acentos y promueve http→https cuando procede.
private func makeURL(from raw: String?) -> URL? {
    guard var s = raw?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty else { return nil }

    // Promover http -> https
    if s.hasPrefix("http://") {
        s = "https://" + s.dropFirst("http://".count)
    }

    // Si ya es válida, úsala
    if let direct = URL(string: s) { return direct }

    // Codifica caracteres problemáticos (espacios, acentos, etc.)
    let allowed = CharacterSet.urlFragmentAllowed
    if let encoded = s.addingPercentEncoding(withAllowedCharacters: allowed) {
        return URL(string: encoded)
    }
    return nil
}

/// Downsampling eficiente para miniaturas
private func downsampleImage(data: Data, to pointSize: CGSize, scale: CGFloat) -> UIImage? {
    let maxDimensionInPixels = max(pointSize.width, pointSize.height) * scale
    let options: [CFString: Any] = [
        kCGImageSourceShouldCache: false,
        kCGImageSourceCreateThumbnailFromImageAlways: true,
        kCGImageSourceThumbnailMaxPixelSize: maxDimensionInPixels
    ]
    guard let source = CGImageSourceCreateWithData(data as CFData, nil),
          let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
        return UIImage(data: data) // fallback
    }
    return UIImage(cgImage: cgImage)
}

// MARK: - Placeholders ESPECÍFICOS DEL CARRUSEL (renombrados para evitar colisiones)

private struct CarruselShimmerRect: View {
    @State private var phase: CGFloat = 0
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(.systemGray5), Color(.systemGray4), Color(.systemGray5)
                    ]),
                    startPoint: .leading, endPoint: .trailing
                )
            )
            .mask(
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(stops: [
                                .init(color: .black.opacity(0.4), location: 0),
                                .init(color: .black, location: 0.5),
                                .init(color: .black.opacity(0.4), location: 1),
                            ]),
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .offset(x: phase)
            )
            .onAppear {
                withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                    phase = 240
                }
            }
    }
}

private struct CarruselPlaceholderRect: View {
    let icon: String
    var body: some View {
        ZStack {
            Rectangle().fill(Color(.tertiarySystemFill))
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.secondary)
        }
    }
}
