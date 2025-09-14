import SwiftUI

struct LogroCardModernView: View {
    let logro: LogroConEstado
    @State private var isPressed = false
    
    private var color: Color {
        logro.desbloqueado ? (Color.fromHex(logro.color) ?? .accentColor) : .gray
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header con icono
            headerSection
            
            // Contenido
            contentSection
            
            // Footer con fecha si está desbloqueado
            if logro.desbloqueado {
                footerSection
            }
        }
        .background(backgroundColor)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(strokeColor, lineWidth: strokeWidth)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: shadowOffset)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .onTapGesture {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                isPressed = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isPressed = false
                }
            }
            
            // Haptic feedback
            #if os(iOS)
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            #endif
        }
    }
    
    // MARK: - Secciones de la tarjeta
    
    private var headerSection: some View {
        HStack {
            Spacer()
            
            ZStack {
                // Círculo de fondo
                Circle()
                    .fill(
                        logro.desbloqueado ?
                        LinearGradient(
                            colors: [color.opacity(0.3), color.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            colors: [Color.gray.opacity(0.2), Color.gray.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                
                // Icono principal
                Image(systemName: logro.icono_nombre)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(color)
                
                // Candado para logros no desbloqueados
                if !logro.desbloqueado {
                    Image(systemName: "lock.fill")
                        .font(.caption.bold())
                        .foregroundColor(.white)
                        .padding(4)
                        .background(.gray, in: Circle())
                        .offset(x: 20, y: -20)
                }
                
                // Brillo para logros desbloqueados
                if logro.desbloqueado {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.white.opacity(0.3), Color.clear],
                                center: .topLeading,
                                startRadius: 0,
                                endRadius: 30
                            )
                        )
                        .frame(width: 60, height: 60)
                }
            }
            
            Spacer()
        }
        .padding(.top, 20)
    }
    
    private var contentSection: some View {
        VStack(spacing: 8) {
            // Título
            Text(logro.titulo)
                .font(.headline.bold())
                .foregroundColor(logro.desbloqueado ? .primary : .secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
            
            // Descripción
            Text(logro.descripcion)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    private var footerSection: some View {
        VStack(spacing: 4) {
            Divider()
                .background(color.opacity(0.3))
            
            if let fecha = logro.fecha {
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption2)
                        .foregroundColor(color)
                    
                    Text(fecha.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption.bold())
                        .foregroundColor(color)
                }
                .padding(.vertical, 8)
            } else {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(color)
                    
                    Text("Desbloqueado")
                        .font(.caption.bold())
                        .foregroundColor(color)
                }
                .padding(.vertical, 8)
            }
        }
    }
    
    // MARK: - Computed properties para el diseño
    
    private var backgroundColor: some View {
        Group {
            if logro.desbloqueado {
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        color.opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                Color(.systemGray6)
            }
        }
    }
    
    private var strokeColor: Color {
        logro.desbloqueado ? color.opacity(0.3) : Color.gray.opacity(0.2)
    }
    
    private var strokeWidth: CGFloat {
        logro.desbloqueado ? 2 : 1
    }
    
    private var shadowColor: Color {
        logro.desbloqueado ? color.opacity(0.25) : Color.black.opacity(0.1)
    }
    
    private var shadowRadius: CGFloat {
        logro.desbloqueado ? 8 : 4
    }
    
    private var shadowOffset: CGFloat {
        logro.desbloqueado ? 4 : 2
    }
}

// MARK: - Preview

#Preview {
    let logroDesbloqueado = LogroConEstado(
        id: UUID(),
        titulo: "Primer Entrenamiento",
        descripcion: "Completa tu primer entrenamiento en la app",
        icono_nombre: "dumbbell.fill",
        desbloqueado: true,
        fecha: Date(),
        color: "#4CAF50"
    )
    
    let logroBloqueado = LogroConEstado(
        id: UUID(),
        titulo: "Maestro del Gimnasio",
        descripcion: "Completa 100 entrenamientos consecutivos",
        icono_nombre: "crown.fill",
        desbloqueado: false,
        fecha: nil,
        color: "#FFD700"
    )
    
    return ScrollView {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            LogroCardModernView(logro: logroDesbloqueado)
            LogroCardModernView(logro: logroBloqueado)
        }
        .padding()
    }
}
