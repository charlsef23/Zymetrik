import SwiftUI

struct HeartBurst: View {
    @State private var scale: CGFloat = 0.2
    @State private var opacity: Double = 0.0

    var body: some View {
        Image(systemName: "heart.fill")
            .font(.system(size: 90))
            .foregroundColor(.red)
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
                    scale = 1.0
                    opacity = 1.0
                }
                withAnimation(.easeOut(duration: 0.25).delay(0.45)) {
                    opacity = 0.0
                    scale = 0.8
                }
            }
    }
}
