import SwiftUI
import Supabase

struct DMNewChatView: View {
    var onCreated: (UUID, PerfilLite) -> Void = { _, _ in }

    @Environment(\.dismiss) private var dismiss

    @State private var query: String = ""
    @State private var results: [PerfilLite] = []
    @State private var loading = false
    @State private var searchTask: Task<Void, Never>?

    // Igual que DMInboxView
    @State private var showingSearch = true

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(.systemBackground),
                        Color(.systemBackground).opacity(0.95)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                Group {
                    if query.isEmpty {
                        initialStateView
                    } else {
                        resultsList
                    }
                }
            }
            .navigationTitle("Nuevo mensaje")
            .navigationBarTitleDisplayMode(.large)
            .searchable(
                text: $query,
                isPresented: $showingSearch,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Buscar usuarios..."
            )
            .onSubmit(of: .search) { performSearch() }
            .onChange(of: query) { _, newValue in
                searchTask?.cancel()
                let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)

                guard !trimmed.isEmpty else {
                    results = []
                    return
                }

                searchTask = Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 350_000_000) // 350ms debounce
                    await search(text: trimmed)
                }
            }
            .task { showingSearch = true }
        }
    }

    private var initialStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "text.bubble.fill")
                .symbolRenderingMode(.hierarchical)
                .font(.system(size: 64))
                .foregroundStyle(.blue)
                .padding(.top, 24)

            VStack(spacing: 8) {
                Text("Inicia una conversación")
                    .font(.title2.weight(.semibold))
                Text("Busca por nombre de usuario para empezar un chat.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding()
    }

    private var resultsList: some View {
        List {
            ForEach(results) { user in
                UserResultRow(user: user) {
                    Task { await startChat(with: user) }
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                // 🔧 Fix de tipo explícito:
                .listRowSeparator(Visibility.hidden)
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
        }

        defer {
            Task { @MainActor in loading = false }
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
            // Removed errorText assignment per instructions
        }
    }
}

// MARK: - User Result Row (inclúyelo si no lo tienes en otro archivo)
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

                    Text("Toca para iniciar chat")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                ZStack {
                    // Subtle gradient background for the card
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(.secondarySystemBackground),
                                    Color(.secondarySystemBackground).opacity(0.85)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .opacity(isPressed ? 0.9 : 1.0)

                    // Border stroke
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.black.opacity(0.06), lineWidth: 0.5)
                }
            )
            .shadow(color: Color.black.opacity(isPressed ? 0.05 : 0.08), radius: isPressed ? 2 : 6, x: 0, y: isPressed ? 1 : 3)
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
