import SwiftUI

struct PostSkeletonView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 12) {
                Circle().fill(Color(.secondarySystemBackground))
                    .frame(width: 40, height: 40)
                    .overlay(ProgressView())
                VStack(alignment: .leading, spacing: 6) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(.secondarySystemBackground))
                        .frame(width: 120, height: 12)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(.secondarySystemBackground))
                        .frame(width: 80, height: 10)
                        .opacity(0.7)
                }
                Spacer()
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.secondarySystemBackground))
                    .frame(width: 22, height: 22)
            }

            // Grid stats fake
            HStack(spacing: 10) {
                ForEach(0..<3) { _ in
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color(.secondarySystemBackground))
                        .frame(height: 100)
                }
            }

            // Carrusel placeholder
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(0..<4) { _ in
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.secondarySystemBackground))
                            .frame(width: 120, height: 120)
                    }
                }
                .padding(.horizontal, 2)
                .padding(.vertical, 8)
            }

            // Actions
            HStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.secondarySystemBackground))
                    .frame(width: 26, height: 26)
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.secondarySystemBackground))
                    .frame(width: 26, height: 26)
                Spacer()
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.secondarySystemBackground))
                    .frame(width: 26, height: 26)
            }

            RoundedRectangle(cornerRadius: 6)
                .fill(Color(.secondarySystemBackground))
                .frame(width: 100, height: 12)
                .padding(.top, 2)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 6)
        )
        .redacted(reason: .placeholder)
        .shimmering()
    }
}

// Shimmer
private struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -0.6
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(stops: [
                    .init(color: .clear, location: 0.0),
                    .init(color: .white.opacity(0.45), location: 0.5),
                    .init(color: .clear, location: 1.0)
                ], startPoint: .topLeading, endPoint: .bottomTrailing)
                .mask(
                    Rectangle()
                        .fill(.linearGradient(colors: [.white, .white], startPoint: .top, endPoint: .bottom))
                        .offset(x: phase * 220)
                )
            )
            .onAppear {
                withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                    phase = 1.2
                }
            }
    }
}

private extension View {
    func shimmering() -> some View { modifier(ShimmerModifier()) }
}
