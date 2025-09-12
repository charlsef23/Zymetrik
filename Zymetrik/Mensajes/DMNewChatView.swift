import SwiftUI
import Supabase

struct DMNewChatView: View {
    var onCreated: (UUID, PerfilLite) -> Void = { _, _ in }

    @Environment(\.dismiss) private var dismiss

    @State private var query: String = ""
    @State private var results: [PerfilLite] = []
    @State private var loading = false
    @State private var errorText: String?
    @State private var searchTask: Task<Void, Never>?
    
    @FocusState private var searchFieldFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header con diseño mejorado
                VStack(spacing: 16) {
                    // Barra de búsqueda mejorada
                    HStack(spacing: 12) {
                        HStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(.secondary)
                            
                            TextField("Buscar por username...", text: $query)
                                .focused($searchFieldFocused)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled(true)
                                .font(.body)
                                .submitLabel(.search)
                                .onSubmit {
                                    performSearch()
                                }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.secondarySystemBackground))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(
                                            searchFieldFocused ? .blue.opacity(0.3) : .clear,
                                            lineWidth: 1
                                        )
                                )
                        )
                        
                        if loading {
                            ProgressView()
                                .scaleEffect(0.9)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .padding(.horizontal, 20)
                    .animation(.easeInOut(duration: 0.2), value: loading)
                    
                    // Contador de resultados
                    if !query.isEmpty && !loading {
                        HStack {
                            Text("\(results.count) resultado\(results.count == 1 ? "" : "s")")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .padding(.top, 8)
                .background(.regularMaterial)
                
                // Contenido principal
                ZStack {
                    // Fondo con gradiente
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(.systemBackground),
                            Color(.systemBackground).opacity(0.95)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
                    
                    if let errorText {
                        errorView(errorText)
                    } else if results.isEmpty && !query.isEmpty && !loading {
                        emptyResultsView
                    } else if query.isEmpty {
                        initialStateView
                    } else {
                        resultsList
                    }
                }
            }
            .navigationTitle("Nuevo mensaje")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                    .foregroundStyle(.blue)
                }
            }
            .onAppear {
                searchFieldFocused = true
            }
        }
        .onChange(of: query) { _, newValue in
            searchTask?.cancel()
            let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
            
            guard !trimmed.isEmpty else {
                results = []
                errorText = nil
                return
            }
            
            searchTask = Task { @MainActor in
                try? await Task.sleep(nanoseconds: 350_000_000) // 350ms debounce
                await search(text: trimmed)
            }
        }
    }
    
    private var initialStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "person.2.circle")
                .font(.system(size: 60))
                .foregroundStyle(.blue.opacity(0.6))
            
            VStack(spacing: 12) {
                Text("Buscar contactos")
                    .font(.title2.weight(.semibold))
                
                Text("Escribe el nombre de usuario de la persona con la que quieres chatear.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            // Sugerencias rápidas (opcional)
            VStack(spacing: 12) {
                Text("Sugerencias:")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.tertiary)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                    ForEach(["@usuario", "@amigo", "@contacto", "@nuevo"], id: \.self) { suggestion in
                        Button {
                            query = String(suggestion.dropFirst())
                            performSearch()
                        } label: {
                            Text(suggestion)
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(.ultraThinMaterial)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .opacity(0.7)
        }
        .padding()
    }
    
    private var emptyResultsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 50))
                .foregroundStyle(.orange.opacity(0.8))
            
            VStack(spacing: 8) {
                Text("Sin resultados")
                    .font(.headline)
                
                Text("No encontramos ningún usuario con el nombre \"\(query)\"")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Button {
                performSearch()
            } label: {
                Text("Buscar de nuevo")
                    .font(.body.weight(.medium))
                    .foregroundColor(.blue)
            }
        }
        .padding()
    }
    
    private func errorView(_ errorText: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 50))
                .foregroundStyle(.red.opacity(0.8))
            
            VStack(spacing: 8) {
                Text("Error de conexión")
                    .font(.headline)
                
                Text(errorText)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Button {
                performSearch()
            } label: {
                Text("Reintentar")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(.blue)
                    .clipShape(Capsule())
            }
        }
        .padding()
    }
    
    private var resultsList: some View {
        List {
            ForEach(results) { user in
                UserResultRow(user: user) {
                    Task { await startChat(with: user) }
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
        .animation(.easeInOut(duration: 0.3), value: results)
    }
    
    private func performSearch() {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        searchTask?.cancel()
        searchTask = Task { @MainActor in
            await search(text: trimmed)
        }
    }

    // MARK: - Data Methods
    
    private func search(text: String) async {
        await MainActor.run {
            loading = true
            errorText = nil
        }
        
        defer {
            Task { @MainActor in
                loading = false
            }
        }

        do {
            let res = try await SupabaseManager.shared.client
                .from("perfil")
                .select("id, username, avatar_url")
                .ilike("username", pattern: "%\(text)%")
                .limit(20)
                .execute()

            let searchResults = try res.decodedList(to: PerfilLite.self)
            
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.results = searchResults
                }
            }
        } catch {
            await MainActor.run {
                self.results = []
                self.errorText = error.localizedDescription
            }
        }
    }

    private func startChat(with user: PerfilLite) async {
        do {
            let convID = try await DMMessagingService.shared.getOrCreateDM(with: user.id)
            await MainActor.run {
                onCreated(convID, user)
                dismiss()
            }
        } catch {
            await MainActor.run {
                self.errorText = (error as NSError).userInfo[NSLocalizedDescriptionKey] as? String
                                  ?? error.localizedDescription
            }
        }
    }
}

// MARK: - User Result Row Component
struct UserResultRow: View {
    let user: PerfilLite
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                AvatarAsyncImage(
                    url: URL(string: user.avatar_url ?? ""),
                    size: 50
                )
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(user.username)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.tertiary)
                    }
                    
                    Text("ID: \(user.id.uuidString.prefix(8))...")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer(minLength: 0)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                .fill(isPressed ? Color(.tertiarySystemFill) : Color(.secondarySystemBackground))
                    .animation(.easeInOut(duration: 0.1), value: isPressed)
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: 0) { } onPressingChanged: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }
    }
}
