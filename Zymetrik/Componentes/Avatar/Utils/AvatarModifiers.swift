import SwiftUI

struct AvatarStyle: ViewModifier {
    let isOnline: Bool
    let showActivity: Bool
    func body(content: Content) -> some View {
        content.overlay(
            Group {
                if showActivity {
                    Circle().fill(isOnline ? Color.green : Color.gray)
                        .frame(width: 12, height: 12)
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                }
            }, alignment: .bottomTrailing
        )
    }
}

struct AvatarPulse: ViewModifier {
    @State private var isAnimating = false
    func body(content: Content) -> some View {
        content
            .scaleEffect(isAnimating ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isAnimating)
            .onAppear { isAnimating = true }
    }
}

struct AvatarSelection: ViewModifier {
    let isSelected: Bool
    func body(content: Content) -> some View {
        content.overlay(
            Circle()
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
                .scaleEffect(isSelected ? 1.1 : 1.0)
                .animation(.spring(response: 0.3), value: isSelected)
        )
    }
}

extension View {
    func avatarStyle(isOnline: Bool = false, showActivity: Bool = false) -> some View {
        modifier(AvatarStyle(isOnline: isOnline, showActivity: showActivity))
    }
    func avatarPulse() -> some View { modifier(AvatarPulse()) }
    func avatarSelection(isSelected: Bool) -> some View { modifier(AvatarSelection(isSelected: isSelected)) }
}
