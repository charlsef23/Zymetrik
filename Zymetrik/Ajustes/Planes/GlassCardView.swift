import SwiftUI

struct GlassCardView: View {
    let title: String
    let price: String
    let features: [(String, String)]
    let isActive: Bool
    var isPremium: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text(price)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }

                Spacer()

                if isActive {
                    Label("Activo", systemImage: "checkmark.seal.fill")
                        .font(.subheadline)
                        .foregroundColor(.green)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                ForEach(features, id: \.1) { icon, text in
                    HStack(spacing: 12) {
                        Image(systemName: icon)
                            .foregroundColor(.white)
                            .frame(width: 22)
                        Text(text)
                            .foregroundColor(.white)
                            .font(.subheadline)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: isPremium ? [.black.opacity(0.8), .gray.opacity(0.6)] : [.gray.opacity(0.5), .gray.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .blur(radius: 0.3)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(.white.opacity(0.1), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 4)
        .padding(.horizontal)
    }
}
