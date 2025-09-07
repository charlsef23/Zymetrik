import SwiftUI
import Supabase

struct DMNewChatView: View {
    var onCreated: (UUID, PerfilLite) -> Void = { _, _ in }

    @Environment(\.dismiss) private var dismiss

    @State private var query: String = ""
    @State private var results: [PerfilLite] = []
    @State private var loading = false
    @State private var errorText: String?

    // Debounce búsqueda
    @State private var searchTask: Task<Void, Never>?

    var body: some View {
        VStack(spacing: 0) {
            // Barra de búsqueda fija arriba
            HStack(spacing: 8) {
                TextField("Buscar username…", text: $query)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.secondarySystemBackground))
                    )

                if loading {
                    ProgressView()
                        .padding(.trailing, 2)
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .onChange(of: query) { _, newValue in
                searchTask?.cancel()
                let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else {
                    results = []
                    errorText = nil
                    return
                }
                searchTask = Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 350_000_000) // 350ms
                    await search(text: trimmed)
                }
            }

            if let errorText {
                Text(errorText)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                    .padding(.top, 6)
            }

            if results.isEmpty && !query.isEmpty && !loading && errorText == nil {
                ContentUnavailableView(
                    "Sin resultados",
                    systemImage: "magnifyingglass",
                    description: Text("Prueba con otro nombre de usuario.")
                )
                .padding(.top, 20)
            }

            List(results) { user in
                Button {
                    Task { await startChat(with: user) }
                } label: {
                    HStack(spacing: 12) {
                        AvatarAsyncImage(url: URL(string: user.avatar_url ?? ""), size: 44)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(user.username)
                                .font(.headline)
                            Text(user.id.uuidString.prefix(8) + "…")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.footnote)
                            .foregroundStyle(.tertiary)
                    }
                    .contentShape(Rectangle())
                }
            }
            .listStyle(.plain)
        }
        .navigationTitle("Nuevo mensaje")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancelar") { dismiss() }
            }
        }
    }

    // MARK: - Data

    private func search(text: String) async {
        loading = true
        errorText = nil
        defer { loading = false }

        do {
            let res = try await SupabaseManager.shared.client
                .from("perfil")
                .select("id, username, avatar_url")
                .ilike("username", pattern: "%\(text)%")
                .limit(20)
                .execute()

            // Usa tus extensiones de decodificación personalizadas
            self.results = try res.decodedList(to: PerfilLite.self)
        } catch {
            self.results = []
            self.errorText = error.localizedDescription
        }
    }

    private func startChat(with user: PerfilLite) async {
        do {
            let convID = try await DMMessagingService.shared.getOrCreateDM(with: user.id)
            onCreated(convID, user)
            dismiss()
        } catch {
            self.errorText = (error as NSError).userInfo[NSLocalizedDescriptionKey] as? String
                              ?? error.localizedDescription
        }
    }
}
