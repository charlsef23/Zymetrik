import SwiftUI

struct EstadisticaEjercicioCard: View {
    let ejercicio: EjercicioPostContenido
    let perfilId: UUID?   // 👈 si nil => tu propio perfil

    @Binding var ejerciciosAbiertos: Set<UUID>
    @StateObject private var vm = ViewModel()

    // Computed: ¿está expandido este ejercicio?
    private var isExpanded: Bool { ejerciciosAbiertos.contains(ejercicio.id) }

    var body: some View {
        VStack(spacing: 0) {
            // MARK: Header
            Button(action: toggleExpanded) {
                HStack(spacing: 12) {
                    // Icono
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.primary.opacity(0.08),
                                        Color.primary.opacity(0.03)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                Circle()
                                    .strokeBorder(.quaternary, lineWidth: 1)
                            )
                            .frame(width: 44, height: 44)

                        Image(systemName: "dumbbell.fill")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.primary.opacity(0.9))
                    }

                    // Título + chips
                    VStack(alignment: .leading, spacing: 4) {
                        Text(ejercicio.nombre)
                            .font(.system(.headline, design: .rounded))
                            .fontWeight(.semibold)
                            .lineLimit(1)

                        HStack(spacing: 6) {
                            Chip(text: "\(vm.sesiones.count) sesiones")
                            if let last = vm.sesiones.last?.fecha {
                                Dot()
                                Text(last, style: .relative)
                                    .lineLimit(1)
                            }
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }

                    Spacer()

                    // Estado + chevron
                    HStack(spacing: 10) {
                        let estado = compararProgreso(vm.sesiones)
                        ProgresoCirculoView(estado: estado)
                            .frame(width: 22, height: 22)
                            .accessibilityLabel("Tendencia")

                        Image(systemName: "chevron.up")
                            .font(.system(size: 14, weight: .semibold))
                            .rotationEffect(.degrees(isExpanded ? 0 : 180))
                            .opacity(0.75)
                            .animation(.snappy(duration: 0.18), value: isExpanded)
                    }
                    .foregroundStyle(.secondary)
                }
                .contentShape(Rectangle())
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
            }
            .buttonStyle(.plain)

            // Divider con animación sutil
            Divider()
                .opacity(isExpanded ? 1 : 0)
                .animation(.snappy(duration: 0.16), value: isExpanded)

            // MARK: Contenido Expandido
            if isExpanded {
                VStack(alignment: .leading, spacing: 14) {

                    // KPIs compactos
                    KPIRow(sesiones: vm.sesiones)

                    // Gráfica
                    GraficaPesoView(sesiones: vm.sesiones)
                        .padding(.top, 2)

                    // Histórico
                    HStack {
                        Label("Histórico", systemImage: "chart.line.uptrend.xyaxis")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }

                    RecentSessionsList(sesiones: vm.sesiones)
                }
                .padding(14)
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .opacity
                ))
                .animation(.snappy(duration: 0.22), value: isExpanded)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(.quaternary, lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 6)
        .padding(.horizontal)
        .padding(.vertical, 6)
        .task {
            await vm.cargarSesiones(ejercicioID: ejercicio.id, autorId: perfilId)
        }
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

    // MARK: - ViewModel interno
    @MainActor
    final class ViewModel: ObservableObject {
        @Published var sesiones: [SesionEjercicio] = []

        func cargarSesiones(ejercicioID: UUID, autorId: UUID?) async {
            do {
                sesiones = try await SupabaseService.shared.obtenerSesionesPara(
                    ejercicioID: ejercicioID,
                    autorId: autorId
                )
            } catch {
                print("❌ Error cargando sesiones: \(error)")
            }
        }
    }
}

// MARK: - Mini Componentes

private struct Chip: View {
    let text: String
    var body: some View {
        Text(text)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule(style: .continuous).fill(.thinMaterial)
            )
            .overlay(
                Capsule(style: .continuous).strokeBorder(.quaternary, lineWidth: 1)
            )
    }
}

private struct Dot: View {
    var body: some View {
        Circle()
            .fill(.secondary)
            .frame(width: 4, height: 4)
            .opacity(0.6)
    }
}

// KPIs
private struct KPIRow: View {
    let sesiones: [SesionEjercicio]

    var body: some View {
        let kpi = KPIMetrics(sesiones: sesiones)

        Grid(horizontalSpacing: 10, verticalSpacing: 10) {
            GridRow {
                KPIItem(title: "Mejor RM", value: kpi.bestRMString, icon: "trophy.fill")
                KPIItem(title: "Volumen", value: kpi.totalVolumenString, icon: "cube.box.fill")
                KPIItem(title: "Última", value: kpi.ultimaFechaString, icon: "clock.fill")
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .contain)
    }
}

private struct KPIItem: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(value)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .minimumScaleFactor(0.8)
                .lineLimit(1)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(.quaternary, lineWidth: 1)
                )
        )
    }
}

// Mini histórico
private struct RecentSessionsList: View {
    let sesiones: [SesionEjercicio]

    var body: some View {
        if sesiones.isEmpty {
            HStack(spacing: 8) {
                Image(systemName: "tray")
                Text("Sin sesiones todavía")
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            VStack(spacing: 8) {
                ForEach(sesionesSuffix3(), id: \.id) { s in
                    HStack {
                        Text(s.fecha, style: .date)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Spacer()
                        // Ajusta estas propiedades a tu modelo
                        Text(formatoPeso(s.pesoTotal))
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.primary)
                    }
                    .padding(.vertical, 6)
                    .contentShape(Rectangle())

                    if s.id != sesionesSuffix3().last?.id {
                        Divider()
                            .opacity(0.5)
                    }
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(.quaternary, lineWidth: 1)
                    )
            )
        }
    }

    private func sesionesSuffix3() -> [SesionEjercicio] {
        let sorted = sesiones.sorted { $0.fecha > $1.fecha }
        return Array(sorted.prefix(3))
    }

    private func formatoPeso(_ v: Double) -> String {
        let f = NumberFormatter()
        f.maximumFractionDigits = 1
        f.minimumFractionDigits = 0
        return (f.string(from: NSNumber(value: v)) ?? "\(v)") + " kg"
    }
}

// MARK: - Métricas auxiliares

private struct KPIMetrics {
    let bestRM: Double
    let totalVolumen: Double
    let ultimaFecha: Date?

    init(sesiones: [SesionEjercicio]) {
        // Ajusta a tu modelo:
        // Supongo que SesionEjercicio tiene `pesoTotal` y `fecha`.
        self.bestRM = sesiones.map { $0.pesoTotal }.max() ?? 0
        self.totalVolumen = sesiones.map { $0.pesoTotal }.reduce(0, +)
        self.ultimaFecha = sesiones.sorted(by: { $0.fecha > $1.fecha }).first?.fecha
    }

    var bestRMString: String {
        number(bestRM) + " kg"
    }

    var totalVolumenString: String {
        number(totalVolumen) + " kg"
    }

    var ultimaFechaString: String {
        if let d = ultimaFecha {
            let df = DateFormatter()
            df.dateStyle = .short
            return df.string(from: d)
        } else {
            return "—"
        }
    }

    private func number(_ v: Double) -> String {
        let f = NumberFormatter()
        f.maximumFractionDigits = 1
        f.minimumFractionDigits = 0
        return f.string(from: NSNumber(value: v)) ?? "\(v)"
    }
}
