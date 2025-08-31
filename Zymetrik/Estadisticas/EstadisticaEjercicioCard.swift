import SwiftUI

struct EstadisticaEjercicioCard: View {
    let ejercicio: EjercicioPostContenido
    let sesiones: [SesionEjercicio]
    @Binding var ejerciciosAbiertos: Set<UUID>

    // Computed: ¿está expandido este ejercicio?
    private var isExpanded: Bool {
        ejerciciosAbiertos.contains(ejercicio.id)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            Button(action: toggleExpanded) {
                HStack(spacing: 12) {
                    // Ícono / avatar del ejercicio
                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 40, height: 40)
                        Image(systemName: "dumbbell.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .opacity(0.85)
                    }

                    // Título + meta
                    VStack(alignment: .leading, spacing: 4) {
                        Text(ejercicio.nombre)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .lineLimit(1)

                        // Línea de meta (chips)
                        HStack(spacing: 6) {
                            Chip(text: "\(sesiones.count) sesiones")
                            // Puedes añadir más chips si quieres (p.ej. “últ. 30 días”)
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }

                    Spacer()

                    // Estado y chevron
                    HStack(spacing: 10) {
                        let estado = compararProgreso(sesiones)
                        ProgresoCirculoView(estado: estado)
                            .frame(width: 22, height: 22)

                        Image(systemName: "chevron.up")
                            .font(.system(size: 14, weight: .semibold))
                            .rotationEffect(.degrees(isExpanded ? 0 : 180))
                            .opacity(0.8)
                            .animation(.snappy(duration: 0.2), value: isExpanded)
                    }
                    .foregroundStyle(.secondary)
                }
                .contentShape(Rectangle())
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
            }
            .buttonStyle(.plain)

            // Divider con animación
            Divider()
                .opacity(isExpanded ? 1 : 0)
                .animation(.snappy(duration: 0.18), value: isExpanded)

            // Contenido expandido
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    GraficaPesoView(sesiones: sesiones)
                        .padding(.top, 4)

                    // Footer opcional (puedes quitarlo si no lo necesitas)
                    HStack {
                        Label("Histórico", systemImage: "chart.line.uptrend.xyaxis")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                }
                .padding(14)
                .transition(
                    .asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .opacity
                    )
                )
                .animation(.snappy(duration: 0.22), value: isExpanded)
            }
        }
        .background(
            // Card moderna con sutil gradiente + borde
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(.systemBackground),
                            Color(.secondarySystemBackground)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(.quaternary, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 6)
        .padding(.horizontal)
        .padding(.vertical, 4)
    }

    private func toggleExpanded() {
        if isExpanded {
            ejerciciosAbiertos.remove(ejercicio.id)
        } else {
            ejerciciosAbiertos.insert(ejercicio.id)
        }
        #if os(iOS)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }
}

// MARK: - Mini Chip
private struct Chip: View {
    let text: String
    var body: some View {
        Text(text)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule(style: .continuous)
                    .fill(.thinMaterial)
            )
            .overlay(
                Capsule(style: .continuous)
                    .strokeBorder(.quaternary, lineWidth: 1)
            )
    }
}
