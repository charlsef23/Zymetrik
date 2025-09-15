import SwiftUI
import CoreImage.CIFilterBuiltins

struct ShareProfileProView: View {
    let username: String
    let profileImageURL: String?   // ahora en vez de Image, recibe URL
    
    // URL pública del perfil (ajústala si usas otro dominio o ruta)
    private var profileURL: URL {
        URL(string: "https://zymetrik.com/u/\(username)")!
    }
    
    @State private var qrUIImage: UIImage? = nil
    @State private var linkCopiado = false
    
    private let ciContext = CIContext()
    private let qrFilter = CIFilter.qrCodeGenerator()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    header
                    shareCard
                    actions
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Compartir perfil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarShareButton }
            .onAppear { generarQR() }
        }
    }
    
    // MARK: - Subvistas
    private var header: some View {
        VStack(spacing: 6) {
            Text("Comparte tu perfil")
                .font(.title3.bold())
            Text("Genera un QR y un enlace directo para que otros te encuentren en Zymetrik.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16).strokeBorder(Color.primary.opacity(0.06))
        )
    }
    
    private var shareCard: some View {
        VStack(spacing: 16) {
            // Avatar + username
            VStack(spacing: 8) {
                AvatarAsyncImage.profile(url: profileImageURL)
                    .frame(width: 84, height: 84)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.primary.opacity(0.08), lineWidth: 1))
                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
                
                Text("@\(username)")
                    .font(.headline)
            }
            
            // QR
            Group {
                if let qrUIImage {
                    Image(uiImage: qrUIImage)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 220, height: 220)
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(.systemBackground))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 6)
                } else {
                    ProgressView().padding(.vertical, 40)
                }
            }
            
            // Enlace
            VStack(spacing: 6) {
                Text("Enlace al perfil")
                    .font(.subheadline).foregroundStyle(.secondary)
                Text(profileURL.absoluteString)
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .tint(.blue)
                    .contextMenu {
                        Button {
                            copiarLink()
                        } label: {
                            Label("Copiar enlace", systemImage: "doc.on.doc")
                        }
                    }
            }
            .padding(.top, 4)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20).stroke(Color.primary.opacity(0.06))
        )
    }
    
    private var actions: some View {
        VStack(spacing: 12) {
            ShareLink(
                item: profileURL,
                subject: Text("Mi perfil en Zymetrik"),
                message: Text("Sígueme en Zymetrik: @\(username)"),
                preview: SharePreview("Perfil de @\(username)")
            ) {
                actionButtonLabel(title: "Compartir", systemImage: "square.and.arrow.up")
            }
            .buttonStyle(.plain)
            
            Button {
                copiarLink()
            } label: {
                actionButtonLabel(title: linkCopiado ? "Enlace copiado" : "Copiar enlace",
                                  systemImage: linkCopiado ? "checkmark.circle" : "doc.on.doc")
            }
            .buttonStyle(.plain)
            .disabled(linkCopiado)
        }
        .padding(.top, 4)
    }
    
    private var toolbarShareButton: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            ShareLink(item: profileURL) {
                Image(systemName: "square.and.arrow.up")
            }
        }
    }
    
    // MARK: - Helpers
    private func actionButtonLabel(title: String, systemImage: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
            Text(title).fontWeight(.semibold)
        }
        .font(.subheadline)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }
    
    private func copiarLink() {
        UIPasteboard.general.string = profileURL.absoluteString
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            linkCopiado = true
        }
        HapticManager.shared.lightImpact()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            withAnimation(.easeInOut(duration: 0.2)) {
                linkCopiado = false
            }
        }
    }
    
    private func generarQR() {
        let string = profileURL.absoluteString
        qrFilter.message = Data(string.utf8)
        qrFilter.correctionLevel = "M"
        
        guard let outputImage = qrFilter.outputImage else { return }
        let scaled = outputImage.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
        if let cgimg = ciContext.createCGImage(scaled, from: scaled.extent) {
            qrUIImage = UIImage(cgImage: cgimg)
        }
    }
}
