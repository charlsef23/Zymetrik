import SwiftUI

// MARK: - Chip base reutilizable
struct FilterChip: View {
    let text: String
    let isSelected: Bool
    let systemImage: String?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                if let systemImage { Image(systemName: systemImage).font(.footnote) }
                Text(text).font(.footnote.weight(.semibold))
            }
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(isSelected ? Color.accentColor.opacity(0.12) : Color(.systemGray6))
            .overlay(Capsule().stroke(isSelected ? Color.accentColor : Color.secondary.opacity(0.25), lineWidth: 1))
            .foregroundStyle(isSelected ? Color.accentColor : Color.primary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .contentShape(Capsule())
    }
}

// MARK: - Sección acordeón genérica
struct FilterAccordionSection<Content: View>: View {
    let title: String
    let icon: String
    let showClear: Bool
    let onClear: (() -> Void)?
    @Binding var isExpanded: Bool
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: icon).font(.subheadline)
                    Text(title).font(.subheadline.weight(.semibold))
                    Spacer()
                    if showClear, let onClear {
                        Button {
                            withAnimation(.spring()) { onClear() }
                        } label: {
                            Label("Limpiar", systemImage: "xmark.circle.fill")
                                .labelStyle(.iconOnly)
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                        .padding(.trailing, 4)
                    }
                    Image(systemName: "chevron.down")
                        .rotationEffect(.degrees(isExpanded ? 0 : -90))
                        .font(.footnote.weight(.semibold))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(.thinMaterial)
            }
            .buttonStyle(.plain)

            if isExpanded {
                Divider()
                content
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(.thinMaterial)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16).stroke(Color.secondary.opacity(0.12), lineWidth: 1)
        )
    }
}

// MARK: - Panel completo de filtros (Tipo, Categorías, Subtipo, Favoritos)
struct FilterPanel: View {
    // bindings hacia la vista padre
    @Binding var tipoSeleccionado: String
    @Binding var filtroCategorias: Set<String>
    @Binding var filtroSubtipos: Set<String>
    @Binding var soloFavoritos: Bool   // 👈 NUEVO

    // datos calculados en la vista padre
    let tipos: [String]
    let categoriasDisponibles: [String]
    let subtiposDisponibles: [String]

    // estado de despliegue
    @State private var expandTipo = true
    @State private var expandCategorias = false
    @State private var expandSubtipo = false
    @State private var expandFavoritos = false   // 👈 NUEVO

    var body: some View {
        VStack(spacing: 12) {
            // Sección: Tipo
            FilterAccordionSection(
                title: "Tipo",
                icon: "square.grid.2x2.fill",
                showClear: false,
                onClear: nil,
                isExpanded: $expandTipo
            ) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(tipos, id: \.self) { tipo in
                            let isOn = tipoSeleccionado == tipo
                            FilterChip(text: tipo,
                                       isSelected: isOn,
                                       systemImage: icon(for: tipo)) {
                                withAnimation(.spring()) {
                                    tipoSeleccionado = tipo
                                }
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
            }

            // Sección: Categorías
            if !categoriasDisponibles.isEmpty {
                FilterAccordionSection(
                    title: "Categorías",
                    icon: "list.bullet",
                    showClear: !filtroCategorias.isEmpty,
                    onClear: { filtroCategorias.removeAll() },
                    isExpanded: $expandCategorias
                ) {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 8)], spacing: 8) {
                        ForEach(categoriasDisponibles, id: \.self) { cat in
                            FilterChip(text: cat,
                                       isSelected: filtroCategorias.contains(cat),
                                       systemImage: nil) {
                                if filtroCategorias.contains(cat) { filtroCategorias.remove(cat) }
                                else { filtroCategorias.insert(cat) }
                            }
                        }
                    }
                }
            }

            // Sección: Subtipo
            if !subtiposDisponibles.isEmpty {
                FilterAccordionSection(
                    title: "Subtipo",
                    icon: "slider.horizontal.3",
                    showClear: !filtroSubtipos.isEmpty,
                    onClear: { filtroSubtipos.removeAll() },
                    isExpanded: $expandSubtipo
                ) {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 8)], spacing: 8) {
                        ForEach(subtiposDisponibles, id: \.self) { st in
                            FilterChip(text: st,
                                       isSelected: filtroSubtipos.contains(st),
                                       systemImage: nil) {
                                if filtroSubtipos.contains(st) { filtroSubtipos.remove(st) }
                                else { filtroSubtipos.insert(st) }
                            }
                        }
                    }
                }
            }

            // Sección: Favoritos (propia)
            FilterAccordionSection(
                title: "Favoritos",
                icon: "star.fill",
                showClear: soloFavoritos,
                onClear: { soloFavoritos = false },
                isExpanded: $expandFavoritos
            ) {
                Toggle("Mostrar solo favoritos", isOn: $soloFavoritos)
                    .toggleStyle(.switch)
                    .tint(.yellow)
            }
        }
    }

    // icono para los chips de Tipo
    private func icon(for tipo: String) -> String {
        switch tipo {
        case "Gimnasio": return "dumbbell"
        case "Cardio": return "heart.fill"
        case "Funcional": return "figure.strengthtraining.traditional"
        default: return "circle"
        }
    }
}
