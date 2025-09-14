import SwiftUI

struct LogroDesbloqueadoMejoradoView: View {
    let logro: LogroConEstado
    let isLastAchievement: Bool
    let achievementNumber: Int
    let totalAchievements: Int
    let onDismiss: () -> Void

    @State private var showContent = false
    @State private var showButtons = false
    @State private var animateIcon = false
    @State private var particlesOpacity = 0.0

    private var color: Color {
        Color.fromHex(logro.color) ?? .accentColor
    }

    var body: some View {
        ZStack {
            // Fondo oscurecido
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            // Partículas de celebración
            ForEach(0..<15, id: \.self) { index in
                ParticleView(color: color, delay: Double(index) * 0.1)
                    .opacity(particlesOpacity)
            }

            // Tarjeta principal
            VStack(spacing: 0) {
                headerSection
                contentSection
                buttonSection
            }
            .frame(maxWidth: 320)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24))
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(color.opacity(0.3), lineWidth: 2)
            )
            .shadow(color: color.opacity(0.3), radius: 20, x: 0, y: 10)
            .scaleEffect(showContent ? 1.0 : 0.5)
            .opacity(showContent ? 1.0 : 0.0)
        }
        .onAppear { startAnimationSequence() }
    }

    // MARK: - Secciones

    private var headerSection: some View {
        VStack(spacing: 16) {
            if totalAchievements > 1 {
                HStack(spacing: 4) {
                    ForEach(0..<totalAchievements, id: \.self) { index in
                        Circle()
                            .fill(index < achievementNumber ? color : color.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .animation(.spring(response: 0.4), value: achievementNumber)
                    }
                }
                .padding(.top, 20)
            } else {
                Spacer().frame(height: 20)
            }

            ZStack {
                // Anillos
                ForEach(0..<3) { index in
                    Circle()
                        .stroke(color.opacity(0.3 - Double(index) * 0.1), lineWidth: 3)
                        .frame(width: 120 + CGFloat(index * 30), height: 120 + CGFloat(index * 30))
                        .scaleEffect(animateIcon ? 1.2 + Double(index) * 0.1 : 0.8)
                        .opacity(animateIcon ? 0.0 : 1.0)
                        .animation(.easeOut(duration: 1.0 + Double(index) * 0.2).delay(0.3 + Double(index) * 0.1), value: animateIcon)
                }

                // Fondo icono
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [color.opacity(0.3), color.opacity(0.1)],
                            center: .center,
                            startRadius: 0, endRadius: 60
                        )
                    )
                    .frame(width: 120, height: 120)
                    .scaleEffect(animateIcon ? 1.1 : 0.9)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2), value: animateIcon)

                // Icono
                Image(systemName: logro.icono_nombre)
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(color)
                    .scaleEffect(animateIcon ? 1.0 : 0.5)
                    .rotationEffect(.degrees(animateIcon ? 0 : -180))
                    .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.4), value: animateIcon)

                // Brillo
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.white.opacity(0.4), Color.clear],
                            center: .topLeading,
                            startRadius: 0, endRadius: 60
                        )
                    )
                    .frame(width: 120, height: 120)
                    .opacity(animateIcon ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 0.8).delay(0.5), value: animateIcon)
            }
        }
        .padding(.horizontal, 24)
    }

    private var contentSection: some View {
        VStack(spacing: 16) {
            Text("¡Logro desbloqueado!")
                .font(.title.bold())
                .foregroundColor(.primary)
                .opacity(showContent ? 1.0 : 0.0)
                .offset(y: showContent ? 0 : 20)
                .animation(.spring(response: 0.6).delay(0.6), value: showContent)

            Text(logro.titulo)
                .font(.title2.weight(.semibold))
                .foregroundColor(color)
                .multilineTextAlignment(.center)
                .opacity(showContent ? 1.0 : 0.0)
                .offset(y: showContent ? 0 : 20)
                .animation(.spring(response: 0.6).delay(0.7), value: showContent)

            if !logro.descripcion.isEmpty {
                Text(logro.descripcion)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .opacity(showContent ? 1.0 : 0.0)
                    .offset(y: showContent ? 0 : 20)
                    .animation(.spring(response: 0.6).delay(0.8), value: showContent)
            }

            if let fecha = logro.fecha {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundColor(color)
                    Text("Desbloqueado el \(fecha.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .opacity(showContent ? 1.0 : 0.0)
                .animation(.spring(response: 0.6).delay(0.9), value: showContent)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
    }

    private var buttonSection: some View {
        VStack(spacing: 12) {
            Divider().background(color.opacity(0.3))

            if totalAchievements > 1 && !isLastAchievement {
                Button(action: onDismiss) {
                    HStack(spacing: 8) {
                        Text("Siguiente")
                        Image(systemName: "arrow.right")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(color, in: RoundedRectangle(cornerRadius: 12))
                }
            } else {
                Button(action: onDismiss) {
                    Text(totalAchievements > 1 ? "¡Genial!" : "Continuar")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(color, in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
        .opacity(showButtons ? 1.0 : 0.0)
        .offset(y: showButtons ? 0 : 20)
        .animation(.spring(response: 0.6).delay(1.0), value: showButtons)
    }

    // MARK: - Animación

    private func startAnimationSequence() {
        #if os(iOS)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        #endif

        withAnimation(.spring(response: 0.7, dampingFraction: 0.8)) {
            showContent = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation {
                animateIcon = true
                particlesOpacity = 1.0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.spring(response: 0.6)) {
                showButtons = true
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.easeOut(duration: 1.0)) {
                particlesOpacity = 0.0
            }
        }
    }
}

// MARK: - Partículas

struct ParticleView: View {
    let color: Color
    let delay: Double

    @State private var animate = false
    @State private var opacity = 1.0

    private let startX = Double.random(in: -150...150)
    private let startY = Double.random(in: -100...100)
    private let endY = Double.random(in: -300...(-150))
    private let rotation = Double.random(in: 0...360)
    private let size = Double.random(in: 4...12)

    var body: some View {
        Circle()
            .fill(color.opacity(0.7))
            .frame(width: size, height: size)
            .position(x: startX + 200, y: animate ? endY + 400 : startY + 400)
            .rotationEffect(.degrees(animate ? rotation * 2 : rotation))
            .opacity(opacity)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    withAnimation(.easeOut(duration: 2.0)) {
                        animate = true
                        opacity = 0.0
                    }
                }
            }
    }
}

