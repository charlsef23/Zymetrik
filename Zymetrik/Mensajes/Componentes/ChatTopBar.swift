import SwiftUI

struct ChatTopBar: View {
    let user: PerfilLite?
    let isTyping: Bool
    var onTap: () -> Void
    
    @State private var typingDots = ""
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                // Avatar con indicador online (opcional para futuras funciones)
                ZStack(alignment: .bottomTrailing) {
                    AvatarAsyncImage(
                        url: URL(string: user?.avatar_url ?? ""),
                        size: 32
                    )
                    .overlay(
                        Circle()
                            .stroke(.background, lineWidth: 2)
                    )
                    
                    // Indicador de estado online (placeholder)
                    Circle()
                        .fill(.green)
                        .frame(width: 12, height: 12)
                        .overlay(
                            Circle()
                                .stroke(.background, lineWidth: 2)
                        )
                        .opacity(0) // Deshabilitado por ahora
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(user?.username ?? "Usuario")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .minimumScaleFactor(0.9)
                            .allowsTightening(true)
                            .fixedSize(horizontal: false, vertical: true)
                            .layoutPriority(2)
                    }

                    // Estado de escritura con animación
                    HStack(spacing: 4) {
                        if isTyping {
                            HStack(spacing: 2) {
                                ForEach(0..<3) { index in
                                    Circle()
                                        .fill(.blue)
                                        .frame(width: 4, height: 4)
                                        .scaleEffect(typingDots.count > index ? 1.2 : 0.8)
                                        .opacity(typingDots.count > index ? 1.0 : 0.6)
                                        .animation(
                                            .easeInOut(duration: 0.6)
                                            .repeatForever(autoreverses: true)
                                            .delay(Double(index) * 0.2),
                                            value: typingDots
                                        )
                                }
                            }
                            
                            Text("escribiendo")
                                .font(.system(size: 13))
                                .lineLimit(1)
                                .minimumScaleFactor(0.9)
                                .foregroundColor(.blue)
                                .transition(.opacity.combined(with: .move(edge: .leading)))
                        } else {
                            Text("toca para ver perfil")
                                .font(.system(size: 13))
                                .lineLimit(1)
                                .minimumScaleFactor(0.9)
                                .foregroundColor(.secondary)
                                .transition(.opacity.combined(with: .move(edge: .leading)))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .animation(.easeInOut(duration: 0.3), value: isTyping)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .layoutPriority(1)
                
                Spacer(minLength: 0)
            }
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onAppear {
            if isTyping {
                startTypingAnimation()
            }
        }
        .onChange(of: isTyping) { _, newValue in
            if newValue {
                startTypingAnimation()
            } else {
                typingDots = ""
            }
        }
    }
    
    private func startTypingAnimation() {
        typingDots = ""
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
            if !isTyping {
                timer.invalidate()
                typingDots = ""
                return
            }
            
            if typingDots.count >= 3 {
                typingDots = ""
            } else {
                typingDots += "."
            }
        }
    }
}
