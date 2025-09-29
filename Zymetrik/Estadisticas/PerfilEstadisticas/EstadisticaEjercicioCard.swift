import SwiftUI

struct EstadisticaEjercicioCard: View {
    let ejercicio: EjercicioPostContenido
    let perfilId: UUID?   // nil => estadísticas del usuario autenticado
    
    @Binding var ejerciciosAbiertos: Set<UUID>
    @StateObject private var vm = ViewModel()
    
    @Environment(\.sizeCategory) private var sizeCategory
    @Environment(\.horizontalSizeClass) private var hSizeClass
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    private var chartHeight: CGFloat {
        if sizeCategory.isAccessibilityCategory { return 460 }
        switch hSizeClass {
        case .some(.regular): return 400
        case .some(.compact): return 320
        default: return 360
        }
    }
    
    private var outerHorizontalPadding: CGFloat {
        return 8
    }
    
    private var isExpanded: Bool { ejerciciosAbiertos.contains(ejercicio.id) }
    
    var body: some View {
        VStack(spacing: 0) {
            heroHeader
            if isExpanded { expandedContent.transition(.asymmetric(insertion: .move(edge: .top).combined(with: .opacity), removal: .opacity)) }
        }
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(.quaternary.opacity(scheme == .dark ? 0.35 : 0.5), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(scheme == .dark ? 0.25 : 0.08), radius: 16, x: 0, y: 8)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, outerHorizontalPadding)
        .padding(.vertical, 8)
        .animation(reduceMotion ? nil : .snappy(duration: 0.22), value: isExpanded)
        .task { await vm.cargarSesiones(ejercicioID: ejercicio.id, autorId: perfilId) }
    }
    
    private var heroHeader: some View {
        Button(action: toggleExpanded) {
            HStack(alignment: .center, spacing: 14) {
                ZStack {
                    // Base gradient (shows behind while loading or if no image)
                    Circle().fill(
                        LinearGradient(
                            colors: [Color.accentColor.opacity(0.22), Color.accentColor.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    
                    if let urlString = ejercicio.imagen_url, let url = URL(string: urlString) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .scaleEffect(0.7)
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                            case .failure:
                                Image(systemName: "photo")
                                    .resizable()
                                    .scaledToFit()
                                    .padding(10)
                                    .foregroundStyle(.secondary)
                            @unknown default:
                                EmptyView()
                            }
                        }
                        .clipShape(Circle())
                    } else {
                        Image(systemName: "photo")
                            .resizable()
                            .scaledToFit()
                            .padding(10)
                            .foregroundStyle(.secondary)
                    }
                }
                .overlay(Circle().strokeBorder(.white.opacity(0.25), lineWidth: 0.5))
                .frame(width: 44, height: 44)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(ejercicio.nombre)
                        .font(.system(.headline, design: .rounded)).fontWeight(.semibold)
                        .lineLimit(1).minimumScaleFactor(0.85)
                    
                    HStack(spacing: 8) {
                        Pill(text: "\(vm.sesiones.count) sesiones")
                        if let last = vm.sesiones.last?.fecha { Pill(text: relativeDate(last), icon: "clock") }
                    }
                    .font(.caption).foregroundStyle(.secondary)
                }
                
                Spacer(minLength: 8)
                
                HStack(spacing: 10) {
                    let estado = compararProgreso(vm.sesiones)
                    ProgresoCirculoView(estado: estado).frame(width: 22, height: 22).accessibilityLabel("Tendencia")
                    Image(systemName: "chevron.up")
                        .font(.system(size: 14, weight: .semibold))
                        .rotationEffect(.degrees(isExpanded ? 0 : 180))
                        .opacity(0.9)
                }
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 14)
            .background(heroBackground)
            .overlay(
                Rectangle()
                    .fill(Color.white.opacity(scheme == .dark ? 0.04 : 0.14))
                    .frame(height: 1)
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .opacity(isExpanded ? 1 : 0)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }
    
    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            ResponsiveKPIs(sesiones: vm.sesiones)
                .padding(.horizontal, 8)
                .padding(.top, 12)
            
            ResponsiveChart(sesiones: vm.sesiones, sizeCategory: sizeCategory, hSizeClass: hSizeClass)
                .frame(maxWidth: .infinity)
                .frame(minHeight: chartHeight)
                .padding(.horizontal, 8)
                .padding(.bottom, 12)
        }
    }
    
    private var heroBackground: some View {
        LinearGradient(
            colors: scheme == .dark
            ? [Color.accentColor.opacity(0.18), Color(.secondarySystemBackground).opacity(0.25)]
            : [Color.accentColor.opacity(0.15), Color.white.opacity(0.8)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
        .overlay(LinearGradient(colors: [Color.white.opacity(0.25), .clear], startPoint: .top, endPoint: .bottom))
    }
    
    private var cardBackground: some View {
        LinearGradient(
            colors: scheme == .dark
            ? [Color(.secondarySystemBackground), Color(.systemBackground)]
            : [Color(.systemBackground), Color(.secondarySystemBackground)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }
    
    private func toggleExpanded() {
        if isExpanded { ejerciciosAbiertos.remove(ejercicio.id) } else { ejerciciosAbiertos.insert(ejercicio.id) }
#if os(iOS)
        if !reduceMotion { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
#endif
    }
    
    @MainActor
    final class ViewModel: ObservableObject {
        @Published var sesiones: [SesionEjercicio] = []
        private var isLoading = false
        private var loadedFor: UUID?

        func cargarSesiones(ejercicioID: UUID, autorId: UUID?) async {
            if loadedFor == ejercicioID || isLoading { return }
            isLoading = true
            defer { isLoading = false }

            if let autorId {
                let res = await SupabaseService.shared.obtenerSesionesParaCached(ejercicioID: ejercicioID, autorId: autorId)
                self.sesiones = res
            } else {
                let res = await SupabaseService.shared.obtenerSesionesParaSafe(ejercicioID: ejercicioID, autorId: nil)
                self.sesiones = res
            }
            self.loadedFor = ejercicioID
        }
    }

    // 👇👇 AÑADE ESTO DENTRO DEL struct EstadisticaEjercicioCard
    private func relativeDate(_ date: Date) -> String {
        let f = RelativeDateTimeFormatter()
        f.locale = .current
        f.unitsStyle = .short   // .abbreviated también vale si prefieres “h”/“min”
        return f.localizedString(for: date, relativeTo: Date())
    }
}

