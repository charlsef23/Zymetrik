import SwiftUI

struct LogroDetailView: View {
    let logro: LogroConEstado
    @State private var showShareSheet = false
    @State private var showProgressDetails = false
    @State private var achievementProgress: AchievementProgressResponse?
    @Environment(\.dismiss) private var dismiss

    private var color: Color {
        Color.fromHex(logro.color) ?? .accentColor
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                headerSection
                contentSection
                progressSection
                actionsSection
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                shareButton
            }
        }
        .task {
            await loadProgressData()
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: 20) {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.3), color.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 200)

                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(logro.desbloqueado ? color.opacity(0.2) : Color.gray.opacity(0.2))
                            .frame(width: 100, height: 100)

                        Image(systemName: logro.icono_nombre)
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(logro.desbloqueado ? color : .gray)

                        if !logro.desbloqueado {
                            Image(systemName: "lock.fill")
                                .font(.headline.bold())
                                .foregroundColor(.white)
                                .padding(8)
                                .background(.gray, in: Circle())
                                .offset(x: 35, y: -35)
                        }

                        if logro.desbloqueado {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [Color.white.opacity(0.4), Color.clear],
                                        center: .topLeading,
                                        startRadius: 0,
                                        endRadius: 50
                                    )
                                )
                                .frame(width: 100, height: 100)
                        }
                    }

                    if logro.desbloqueado {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                            Text("Desbloqueado").font(.headline.bold()).foregroundColor(.green)
                        }
                    } else {
                        HStack(spacing: 6) {
                            Image(systemName: "clock").foregroundColor(.orange)
                            Text("Pendiente").font(.headline.bold()).foregroundColor(.orange)
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.top)
    }

    // MARK: - Content
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 12) {
                Text(logro.titulo)
                    .font(.largeTitle.bold())
                    .foregroundColor(.primary)

                Text(logro.descripcion)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineSpacing(2)
            }

            if logro.desbloqueado {
                VStack(spacing: 16) {
                    if let fecha = logro.fecha {
                        InfoRow(
                            icon: "calendar",
                            title: "Fecha de desbloqueo",
                            value: fecha.achievementDateFormat,
                            color: color
                        )
                    }

                    InfoRow(
                        icon: "clock.arrow.circlepath",
                        title: "Tiempo desde desbloqueo",
                        value: timeSinceUnlocked,
                        color: color
                    )
                }
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
            }

            VStack(spacing: 16) {
                InfoRow(
                    icon: "tag",
                    title: "Categoría",
                    value: logro.categoria.rawValue,
                    color: .blue
                )

                InfoRow(
                    icon: "star",
                    title: "Dificultad",
                    value: difficultyText,
                    color: difficultyColor
                )

                InfoRow(
                    icon: "person.2",
                    title: "Rango",
                    value: rarityText,
                    color: .purple
                )
            }
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
        .padding(.horizontal)
        .padding(.top, 24)
    }

    // MARK: - Progress
    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Tu progreso")
                    .font(.title2.bold())
                    .foregroundColor(.primary)

                Spacer()

                Button(action: { showProgressDetails.toggle() }) {
                    Image(systemName: showProgressDetails ? "chevron.up" : "chevron.down")
                        .foregroundColor(color)
                }
            }

            if showProgressDetails {
                if let progress = achievementProgress {
                    VStack(spacing: 16) {
                        ProgressDetailRow(
                            title: "Entrenamientos completados",
                            current: progress.total_workouts,
                            target: targetForWorkouts,
                            unit: "entrenamientos"
                        )

                        ProgressDetailRow(
                            title: "Peso total levantado",
                            current: Int(progress.total_weight),
                            target: 1000,
                            unit: "kg"
                        )

                        ProgressDetailRow(
                            title: "Días activo",
                            current: progress.days_active,
                            target: 30,
                            unit: "días"
                        )
                    }
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                } else {
                    ProgressView("Cargando progreso...")
                        .frame(maxWidth: .infinity)
                        .padding()
                }
            } else {
                VStack(spacing: 12) {
                    if logro.desbloqueado {
                        HStack {
                            Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                            Text("¡Logro completado!").font(.headline).foregroundColor(.green)
                            Spacer()
                        }
                        .padding()
                        .background(Color.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                    } else {
                        VStack(spacing: 8) {
                            Text("En progreso…").font(.headline).foregroundColor(.orange)
                            Text("Continúa entrenando para desbloquear este logro")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        .background(Color.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 24)
    }

    // MARK: - Actions
    private var actionsSection: some View {
        VStack(spacing: 16) {
            if logro.desbloqueado {
                shareAchievementButton
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "lightbulb").foregroundColor(.yellow)
                        Text("Consejo para desbloquearlo")
                            .font(.headline).foregroundColor(.primary)
                    }
                    Text(achievementTip)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .lineSpacing(2)
                }
                .padding()
                .background(Color.yellow.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
            }
        }
        .padding(.horizontal)
        .padding(.top, 24)
        .padding(.bottom, 32)
    }

    private var shareButton: some View {
        Button(action: { showShareSheet = true }) {
            Image(systemName: "square.and.arrow.up")
                .foregroundColor(color)
        }
        .disabled(!logro.desbloqueado)
    }

    // MARK: - Helpers (texto, colores, etc.)
    private var timeSinceUnlocked: String {
        guard let fecha = logro.fecha else { return "N/A" }
        let interval = Date().timeIntervalSince(fecha)
        if interval < 3600 {
            return "Hace \(Int(interval / 60)) min"
        } else if interval < 86400 {
            return "Hace \(Int(interval / 3600)) h"
        } else {
            return "Hace \(Int(interval / 86400)) días"
        }
    }

    private var difficultyText: String {
        let t = logro.titulo.lowercased()
        if t.contains("primer") { return "Principiante" }
        if t.contains("maestro") || t.contains("veterano") { return "Experto" }
        if t.contains("popular") { return "Difícil" }
        return "Intermedio"
    }

    private var difficultyColor: Color {
        switch difficultyText {
        case "Principiante": return .green
        case "Intermedio": return .orange
        case "Difícil": return .red
        case "Experto": return .purple
        default: return .blue
        }
    }

    private var rarityText: String {
        switch difficultyText {
        case "Principiante": return "Común (90%)"
        case "Intermedio": return "Poco común (60%)"
        case "Difícil": return "Raro (25%)"
        case "Experto": return "Legendario (5%)"
        default: return "Desconocido"
        }
    }

    private var achievementTip: String {
        let t = logro.titulo.lowercased()
        if t.contains("primer entrenamiento") { return "Completa tu primer entrenamiento." }
        if t.contains("5 entrenamientos") { return "Entrena 2–3 veces/semana para llegar." }
        if t.contains("1000kg") { return "Prioriza compuestos y registra tus sets." }
        if t.contains("sociable") { return "Sigue a 10 personas." }
        if t.contains("popular") { return "Publica contenido útil y constante." }
        if t.contains("constante") { return "Mantén la racha diaria, aunque sea corta." }
        return "Mantente activo y constante: cada paso cuenta."
    }

    private var shareText: String {
        let emoji = logro.desbloqueado ? "🏆" : "🎯"
        return "\(emoji) ¡He desbloqueado el logro '\(logro.titulo)'! \(logro.descripcion) #Fitness #Logros"
    }

    private var targetForWorkouts: Int {
        let t = logro.titulo.lowercased()
        if t.contains("primer") { return 1 }
        if t.contains("5") { return 5 }
        if t.contains("maestro") { return 100 }
        return 1
    }

    private func loadProgressData() async {
        // Simula delay
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        await MainActor.run {
            achievementProgress = AchievementProgressResponse(
                total_workouts: Int.random(in: 0...50),
                total_weight: Double.random(in: 0...2000),
                total_likes: Int.random(in: 0...150),
                days_active: Int.random(in: 0...60)
            )
        }
    }

    // Reemplazo de hoja de compartir
    private var shareAchievementButton: some View {
        Button(action: { showShareSheet = true }) {
            HStack {
                Image(systemName: "square.and.arrow.up")
                Text("Compartir logro")
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(color, in: RoundedRectangle(cornerRadius: 12))
        }
        .sheet(isPresented: $showShareSheet) {
            SystemShareSheet(items: [shareText])
        }
    }
}

// MARK: - Utilidades UI
private struct InfoRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon).foregroundColor(color).frame(width: 20)
            Text(title).font(.subheadline).foregroundColor(.secondary)
            Spacer()
            Text(value).font(.subheadline.bold()).foregroundColor(.primary)
        }
    }
}

private struct ProgressDetailRow: View {
    let title: String
    let current: Int
    let target: Int
    let unit: String

    private var progress: Double {
        guard target > 0 else { return 0 }
        return min(Double(current) / Double(target), 1.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title).font(.subheadline).foregroundColor(.secondary)
                Spacer()
                Text("\(current)/\(target) \(unit)").font(.subheadline.bold())
            }
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(current >= target ? .green : .blue)
                        .frame(width: geometry.size.width * progress, height: 8)
                        .animation(.easeInOut, value: progress)
                }
            }
            .frame(height: 8)
        }
    }
}

// MARK: - ShareSheet genérico
struct SystemShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
