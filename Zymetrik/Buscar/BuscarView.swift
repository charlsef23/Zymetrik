import SwiftUI
import Supabase

#if canImport(SwiftUI)
// Liquid Glass is part of modern SwiftUI materials on iOS 26+
#endif

// MARK: - Helpers

private extension Array {
    func unique<Key: Hashable>(by key: (Element) -> Key) -> [Element] {
        var seen = Set<Key>()
        return filter { seen.insert(key($0)).inserted }
    }
}

private func isCancelled(_ error: Error) -> Bool {
    if let urlErr = error as? URLError, urlErr.code == .cancelled { return true }
    if let nsErr = error as NSError?, nsErr.domain == NSURLErrorDomain && nsErr.code == NSURLErrorCancelled { return true }
    return (error as? CancellationError) != nil
}

@discardableResult
private func debounceTask(milliseconds: UInt64, operation: @escaping @Sendable () async -> Void) -> Task<Void, Never> {
    return Task { @MainActor in
        let delay = Duration.milliseconds(Int64(milliseconds))
        do {
            try await Task.sleep(for: delay)
        } catch {
            return
        }
        if !Task.isCancelled { await operation() }
    }
}

// MARK: - Scroll offset preference for reactive glass effect
private struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Estilo reutilizable para barra tipo MainTabView con estilo Liquid Glass iOS 26+

private struct MainTabSearchBarStyle: ViewModifier {
    var cornerRadius: CGFloat = 18
    var baseOpacity: Double = 0.30
    var gainOpacity: Double = 0.55
    var shadowBase: Double = 0.06
    var shadowGain: Double = 0.06
    var scrollOffset: CGFloat

    func body(content: Content) -> some View {
        let t = min(max(scrollOffset / 80, 0), 1)

        return content
            .background(
                ZStack {
                    // Base: solid light gray surface
                    Color(.systemGray6).opacity(0.95 - (0.55 * t))

                    if #available(iOS 26.0, *) {
                        // Glass emerges as you scroll
                        Color.clear
                            .glassEffect(
                                .regular
                                    .tint(.white.opacity(0.06 + 0.10 * t))
                                    .interactive(),
                                in: .rect(cornerRadius: cornerRadius)
                            )
                            .opacity(0.20 + 0.50 * t)

                        // Subtle material lift under glass
                        Color.clear.background(.ultraThinMaterial.opacity(0.04 + 0.16 * t))
                    } else {
                        Color.clear.background(.ultraThinMaterial.opacity(baseOpacity + gainOpacity * t))
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.22 + 0.08 * t),
                                Color.white.opacity(0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
                    .shadow(color: Color.black.opacity(shadowBase + shadowGain * t), radius: 12, x: 0, y: 6)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            )
            .animation(.easeInOut(duration: 0.2), value: t)
    }
}

private extension View {
    func mainTabSearchBarStyle(scrollOffset: CGFloat,
                               cornerRadius: CGFloat = 18) -> some View {
        self.modifier(MainTabSearchBarStyle(cornerRadius: cornerRadius, scrollOffset: scrollOffset))
    }
}

// MARK: - BuscarView estilo Instagram (barra fija arriba)

struct BuscarView: View {
    @State private var searchText = ""
    @State private var resultados: [Perfil] = []
    @State private var seguidos: Set<UUID> = []
    @State private var cargando = false

    @State private var userID: UUID? = nil
    @FocusState private var searchFocused: Bool

    @State private var perfilSeleccionado: Perfil?
    @State private var navegar = false

    @State private var historial: [Perfil] = []
    @State private var cargarHistorialTask: Task<Void, Never>? = nil
    @State private var searchTask: Task<Void, Never>? = nil
    @State private var cargandoHistorial = true
    @State private var scrollOffset: CGFloat = 0

    // Si tienes flag de verificado en DB, úsalo desde ahí.
    private let verificadosDemo: Set<UUID> = []

    var body: some View {
        NavigationStack {
            // Contenido desplazable (todo va debajo de la barra)
            ScrollView {
                GeometryReader { proxy in
                    Color.clear
                        .preference(key: ScrollOffsetKey.self, value: proxy.frame(in: .named("buscar_scroll")).minY)
                }
                .frame(height: 0)

                if searchText.isEmpty {
                    if cargandoHistorial {
                        VStack(spacing: 10) {
                            ProgressView()
                            Text("Cargando recientes…")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 16)
                    } else if !historial.isEmpty {
                        // Encabezado + lista recientes
                        SeccionHeader(
                            titulo: "Recientes",
                            accionTitulo: "Ver todo",
                            onAccion: { /* opcional */ }
                        )
                        .padding(.top, 12)

                        ListRecientes // ya es LazyVStack
                    } else {
                        EmptyStateBusqueda()
                            .padding(.top, 16)
                    }
                } else {
                    if cargando {
                        ProgressView().padding(.top, 16)
                    } else {
                        LazyVStack(spacing: 0) {
                            ForEach(resultados.unique(by: { $0.id }), id: \.id) { perfil in
                                Button {
                                    perfilSeleccionado = perfil
                                    navegar = true
                                    Task { await guardarHistorialEnSupabase(perfil: perfil) }
                                } label: {
                                    UsuarioRowView(
                                        perfil: perfil,
                                        seguidos: $seguidos,
                                        currentUserID: userID
                                    )
                                }
                                .buttonStyle(.plain)

                                Divider().padding(.leading, 72)
                            }
                        }
                        .padding(.top, 6)
                    }
                }
                // Pequeño padding inferior para que el último elemento no quede pegado
                Color.clear.frame(height: 12)
            }
            .coordinateSpace(name: "buscar_scroll")
            .onPreferenceChange(ScrollOffsetKey.self) { value in
                // Invertimos para que hacia abajo sea positivo
                scrollOffset = max(0, -value)
            }
            // Barra de búsqueda FIJA arriba (queda fuera del scroll)
            .safeAreaInset(edge: .top) {
                barraBusqueda
                    .background {
                        Color.clear.ignoresSafeArea()
                    }
            }
            // Sin título de navegación
            .navigationDestination(isPresented: $navegar) { destinoVistaPerfil() }
            .task {
                do {
                    let session = try await SupabaseManager.shared.client.auth.session
                    self.userID = session.user.id
                    cargarHistorial()
                    await cargarSeguidos(userID: session.user.id)
                } catch {
                    print("❌ Error sesión:", error)
                    cargandoHistorial = false
                }
            }
        }
    }

    // MARK: - Vistas

    @ViewBuilder
    private func destinoVistaPerfil() -> some View {
        if let seleccionado = perfilSeleccionado {
            if seleccionado.id == userID {
                PerfilView()
            } else {
                UserProfileView(username: seleccionado.username)
            }
        } else {
            EmptyView()
        }
    }

    // Barra compacta (queda fija gracias a safeAreaInset)
    private var barraBusqueda: some View {
        HStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)

                TextField("Buscar", text: $searchText)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .focused($searchFocused)
                    .task { // foco suave al entrar
                        searchFocused = true
                    }
                    .onChange(of: searchText) { _, _ in
                        // Debounce con cancelación (Clock API)
                        searchTask?.cancel()
                        searchTask = debounceTask(milliseconds: 250) {
                            await buscarUsuarios()
                        }
                    }

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                        resultados = []
                    } label: {
                        if #available(iOS 26.0, *) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.tertiary)
                        } else {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                    .accessibilityLabel("Limpiar búsqueda")
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .mainTabSearchBarStyle(scrollOffset: scrollOffset, cornerRadius: 18)
            .contentShape(Rectangle())

            if searchFocused || !searchText.isEmpty {
                Button("Cancelar") {
                    searchText = ""
                    resultados = []
                    searchFocused = false // cierra teclado
                }
                .accessibilityIdentifier("buscar.cancelar")
                .accessibilityLabel("Cancelar búsqueda")
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background {
                    if #available(iOS 26.0, *) {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.white.opacity(0.9))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Color.white.opacity(0.25), lineWidth: 0.5)
                            )
                    } else {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(.systemGray5))
                    }
                }
                .foregroundStyle(.primary)
            }
        }
        .padding(.horizontal)
        .padding(.top, 4)
        .padding(.bottom, 10)
    }

    // Ya NO es ScrollView; se usa dentro del ScrollView principal
    private var ListRecientes: some View {
        LazyVStack(spacing: 0) {
            ForEach(historial.unique(by: { $0.id }), id: \.id) { p in
                HistorialRowView(
                    perfil: p,
                    mostrandoSiguiendo: seguidos.contains(p.id),
                    esVerificado: verificadosDemo.contains(p.id),
                    onTap: {
                        perfilSeleccionado = p
                        navegar = true
                    },
                    onDelete: {
                        Task { await eliminarUnoDelHistorial(perfilID: p.id) }
                    }
                )
                Divider().padding(.leading, 72)
            }
        }
        .padding(.top, 4)
    }

    // MARK: - Data

    @MainActor
    private func buscarUsuarios() async {
        let currentQuery = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !currentQuery.isEmpty else {
            cargando = false
            resultados = []
            return
        }

        do {
            cargando = true
            let session = try await SupabaseManager.shared.client.auth.session
            let currentUserID = session.user.id

            // Si creaste la columna generada `username_lc` + índice pg_trgm,
            // usa esta línea (más rápida):
            let queryColumn = "username_lc"   // <- si NO la tienes, cambia a "username"

            let resp = try await SupabaseManager.shared.client
                .from("perfil")
                .select("id, username, nombre, avatar_url")
                .ilike(queryColumn, pattern: "%\(currentQuery.lowercased())%")
                // .neq("id", value: currentUserID.uuidString) // opcional para ocultarte
                .order("username") // orden estable; refinamos abajo
                .limit(30)
                .execute()

            var lista = try resp.decodedList(to: Perfil.self).unique(by: { $0.id })

            // Prioriza prefijo como IG
            let q = currentQuery.lowercased()
            lista.sort { a, b in
                let ap = a.username.lowercased().hasPrefix(q)
                let bp = b.username.lowercased().hasPrefix(q)
                if ap != bp { return ap && !bp }
                return a.username.lowercased() < b.username.lowercased()
            }

            // Evita pintar resultados de queries viejas
            guard currentQuery == searchText.trimmingCharacters(in: .whitespacesAndNewlines) else { return }

            resultados = lista

            if seguidos.isEmpty { await cargarSeguidos(userID: currentUserID) }
        } catch {
            if !isCancelled(error) {
                print("❌ Buscar usuarios (real): \(error)")
            }
        }

        cargando = false
    }

    private func cargarSeguidos(userID: UUID) async {
        struct FollowedOnly: Decodable { let followed_id: UUID }
        do {
            let r = try await SupabaseManager.shared.client
                .from("followers")
                .select("followed_id")
                .eq("follower_id", value: userID.uuidString)
                .execute()

            let rows = try r.decodedList(to: FollowedOnly.self)
            await MainActor.run { seguidos = Set(rows.map { $0.followed_id }) }
        } catch {
            if !isCancelled(error) {
                print("❌ Seguidos (real): \(error)")
            }
        }
    }

    @MainActor
    private func cargarHistorial() {
        cargarHistorialTask?.cancel()
        cargandoHistorial = true
        cargarHistorialTask = Task { await cargarHistorialDesdeSupabase() }
    }

    private func cargarHistorialDesdeSupabase() async {
        do {
            let session = try await SupabaseManager.shared.client.auth.session
            let uid = session.user.id.uuidString

            let response = try await SupabaseManager.shared.client
                .from("historial_busqueda")
                .select("perfil:perfil_id(id, username, nombre, avatar_url)")
                .eq("usuario_id", value: uid)
                .order("buscado_en", ascending: false)
                .limit(50)
                .execute()

            if let filas = try? response.decoded(to: [[String: Perfil]].self) {
                let perfiles = filas.compactMap { $0["perfil"] }.unique(by: { $0.id })
                await MainActor.run { historial = perfiles }
            }
        } catch {
            if !isCancelled(error) {
                print("❌ Cargar historial (real): \(error)")
            }
        }

        await MainActor.run { cargandoHistorial = false }
    }

    struct NuevoHistorial: Encodable { let usuario_id: String; let perfil_id: String }

    private func guardarHistorialEnSupabase(perfil: Perfil) async {
        guard let session = try? await SupabaseManager.shared.client.auth.session else { return }
        let uid = session.user.id.uuidString
        let data = NuevoHistorial(usuario_id: uid, perfil_id: perfil.id.uuidString)

        do {
            // try await SupabaseManager.shared.client.from("historial_busqueda").upsert(data).execute() // si tienes UNIQUE
            _ = try await SupabaseManager.shared.client
                .from("historial_busqueda")
                .delete()
                .eq("usuario_id", value: uid)
                .eq("perfil_id", value: perfil.id.uuidString)
                .execute()

            _ = try await SupabaseManager.shared.client
                .from("historial_busqueda")
                .insert(data)
                .execute()
        } catch {
            if !isCancelled(error) {
                print("❌ Guardar historial (real): \(error)")
            }
        }
    }

    private func eliminarUnoDelHistorial(perfilID: UUID) async {
        guard let session = try? await SupabaseManager.shared.client.auth.session else { return }
        let uid = session.user.id.uuidString

        do {
            _ = try await SupabaseManager.shared.client
                .from("historial_busqueda")
                .delete()
                .eq("usuario_id", value: uid)
                .eq("perfil_id", value: perfilID.uuidString)
                .execute()

            await MainActor.run {
                historial.removeAll { $0.id == perfilID }
            }
        } catch {
            if !isCancelled(error) {
                print("❌ Eliminar de historial (real): \(error)")
            }
        }
    }

    private func eliminarHistorialDesdeSupabase() async {
        guard let session = try? await SupabaseManager.shared.client.auth.session else { return }
        let uid = session.user.id.uuidString

        do {
            _ = try await SupabaseManager.shared.client
                .from("historial_busqueda")
                .delete()
                .eq("usuario_id", value: uid)
                .execute()

            await MainActor.run { historial = [] }
        } catch {
            if !isCancelled(error) {
                print("❌ Eliminar historial (real): \(error)")
            }
        }
    }
}

// MARK: - Sección encabezado (“Recientes · Ver todo”)

private struct SeccionHeader: View {
    let titulo: String
    var accionTitulo: String? = nil
    var onAccion: (() -> Void)? = nil

    var body: some View {
        HStack {
            Text(titulo)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.primary)
                .padding(.leading, 16)

            Spacer()

            if let accionTitulo, let onAccion {
                Button(accionTitulo, action: onAccion)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color(.systemBlue))
                    .padding(.trailing, 16)
            }
        }
    }
}

// MARK: - Fila de reciente con ✕ y badge

private struct HistorialRowView: View {
    let perfil: Perfil
    let mostrandoSiguiendo: Bool
    let esVerificado: Bool
    var onTap: () -> Void
    var onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            if let url = perfil.avatar_url, let imageURL = URL(string: url) {
                AsyncImage(url: imageURL) { image in
                    image.resizable()
                } placeholder: { Color.gray.opacity(0.3) }
                .frame(width: 56, height: 56)
                .clipShape(Circle())
                .accessibilityHidden(true)
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 56, height: 56)
                    .foregroundColor(.gray)
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(perfil.username)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .accessibilityLabel("Usuario \(perfil.username)")

                    if esVerificado {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 14))
                            .foregroundColor(Color(.systemBlue))
                    }
                }

                HStack(spacing: 6) {
                    if !perfil.nombre.isEmpty { Text(perfil.nombre) }
                    if mostrandoSiguiendo { Text("·"); Text("Siguiendo") }
                }
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .lineLimit(1)
            }

            Spacer()

            Button(action: onDelete) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.secondary)
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("historial.eliminar")
            .accessibilityLabel("Eliminar de recientes")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
    }
}

// MARK: - Empty state sutil

private struct EmptyStateBusqueda: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.secondary)
                .accessibilityHidden(true)
            Text("Busca personas")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview("BuscarView") {
    BuscarView()
}

