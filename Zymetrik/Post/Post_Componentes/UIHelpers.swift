import SwiftUI

struct ShimmerRect: View {
    @State private var phase: CGFloat = -0.6
    var body: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color(.secondarySystemBackground))
            .overlay(
                LinearGradient(stops: [
                    .init(color: .clear, location: 0.0),
                    .init(color: .white.opacity(0.45), location: 0.5),
                    .init(color: .clear, location: 1.0)
                ], startPoint: .topLeading, endPoint: .bottomTrailing)
                .mask(
                    Rectangle()
                        .fill(.linearGradient(colors: [.white, .white], startPoint: .top, endPoint: .bottom))
                        .offset(x: phase * 160)
                )
            )
            .onAppear {
                withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                    phase = 1.2
                }
            }
    }
}

struct PlaceholderRect: View {
    let icon: String
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
            Image(systemName: icon)
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(.secondary)
        }
    }
}
