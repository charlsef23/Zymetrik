// ToastView.swift
import SwiftUI

struct ToastView: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 14).padding(.vertical, 10)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .shadow(radius: 8)
    }
}

struct ToastModifier: ViewModifier {
    @Binding var show: Bool
    let text: String
    func body(content: Content) -> some View {
        ZStack {
            content
            if show {
                VStack { Spacer()
                    ToastView(text: text).padding(.bottom, 24)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { withAnimation { show = false } }
                }
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: show)
    }
}

extension View {
    func toast(_ show: Binding<Bool>, text: String) -> some View {
        self.modifier(ToastModifier(show: show, text: text))
    }
}
