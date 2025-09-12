import SwiftUI

struct ComposerBar: View {
    @Binding var text: String
    var onSend: () -> Void
    
    @State private var isExpanded = false
    @FocusState private var isTextFieldFocused: Bool
    
    private var isEmpty: Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Separador sutil
            Rectangle()
                .fill(.quaternary)
                .frame(height: 0.5)
            
            HStack(alignment: .bottom, spacing: 12) {
                // Campo de texto expandible
                VStack {
                    TextField("Mensaje...", text: $text, axis: .vertical)
                        .focused($isTextFieldFocused)
                        .textInputAutocapitalization(.sentences)
                        .autocorrectionDisabled(false)
                        .lineLimit(1...6)
                        .font(.body)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(.secondarySystemBackground))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(
                                            isTextFieldFocused ? .blue.opacity(0.3) : .clear,
                                            lineWidth: 1
                                        )
                                )
                        )
                        .overlay(alignment: .trailing) {
                            if !isEmpty {
                                Button {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        text = ""
                                    }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.tertiary)
                                        .font(.system(size: 16))
                                }
                                .padding(.trailing, 10)
                                .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .onChange(of: text) { _, newValue in
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isExpanded = !newValue.isEmpty
                            }
                        }
                }
                
                // Botón de envío
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        onSend()
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors:
                                        isEmpty
                                        ? [Color(.tertiarySystemBackground), Color(.tertiarySystemBackground)]
                                        : [Color.blue, Color.blue.opacity(0.8)]
                                    ),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: "arrow.up")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(isEmpty ? .secondary : .white)
                            .scaleEffect(isEmpty ? 0.8 : 1.0)
                    }
                    .scaleEffect(isEmpty ? 0.9 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isEmpty)
                }
                .disabled(isEmpty)
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.regularMaterial)
        }
        .animation(.easeInOut(duration: 0.2), value: isTextFieldFocused)
    }
}
