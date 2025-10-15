import SwiftUI

struct ComposerBar: View {
    @Binding var text: String
    var onSend: () -> Void

    @FocusState private var isTextFieldFocused: Bool

    private var isEmpty: Bool { text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    var body: some View {
        VStack(spacing: 0) {
            Rectangle().fill(Color(.separator).opacity(0.4)).frame(height: 0.5)
            HStack(alignment: .bottom, spacing: 12) {
                TextField("Mensaje…", text: $text, axis: .vertical)
                    .focused($isTextFieldFocused)
                    .textInputAutocapitalization(.sentences)
                    .autocorrectionDisabled(false)
                    .lineLimit(1...6)
                    .font(.body)
                    .padding(.horizontal, 14).padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(isTextFieldFocused ? Color.accentColor.opacity(0.35) : Color.secondary.opacity(0.15), lineWidth: 1)
                            )
                    )
                    .overlay(alignment: .trailing) {
                        if !isEmpty {
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) { text = "" }
                            } label: {
                                Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary).font(.system(size: 16))
                            }
                            .padding(.trailing, 10)
                            .transition(.scale.combined(with: .opacity))
                        }
                    }

                Button {
                    withAnimation(.easeInOut(duration: 0.25)) { onSend() }
                } label: {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(gradient: Gradient(colors: isEmpty ? [Color(.secondarySystemFill), Color(.tertiarySystemFill)] : [Color.accentColor, Color.accentColor.opacity(0.85)]), startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 36, height: 36)
                        Image(systemName: "arrow.up")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(isEmpty ? .secondary : .white)
                            .scaleEffect(isEmpty ? 0.8 : 1.0)
                    }
                }
                .disabled(isEmpty)
                .buttonStyle(.plain)
                .scaleEffect(isEmpty ? 0.9 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isEmpty)
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
            .background(.regularMaterial)
        }
        .animation(.easeInOut(duration: 0.2), value: isTextFieldFocused)
        .accessibilityElement(children: .contain)
        .accessibilityHint("Escribir y enviar mensaje")
    }
}
