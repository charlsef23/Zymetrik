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

    var body: some View {
        VStack {
            HStack {
                TextField("Buscar username…", text: $query)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .padding(10)
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
                if loading { ProgressView().padding(.leading, 4) }
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .onChange(of: query) { _, newValue in
                searchTask?.cancel()
                let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { results = []; return }
                searchTask = Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 350_000_000)
                    await search(text: trimmed)
                }
            }

            if let errorText {
                Text(errorText).foregroundColor(.secondary).padding(.horizontal)
            }

            if results.isEmpty && !query.isEmpty && !loading {
                ContentUnavailableView(
                    "Sin resultados",
                    systemImage: "magnifyingglass",
                    description: Text("Prueba con otro nombre de usuario.")
                )
                .padding(.top, 24)
            }

            List(results) { user in
                Button { Task { await startChat(with: user) } } label: {
                    HStack(spacing: 12) {
                        AvatarAsyncImage(url: URL(string: user.avatar_url ?? ""), size: 44)
                        Text(user.username).font(.headline)
                    }
                }
            }
            .listStyle(.plain)

            Spacer()
        }
        .navigationTitle("Nuevo mensaje")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) { Button("Cancelar") { dismiss() } }
        }
    }

    private func search(text: String) async {
        loading = true; errorText = nil
        do {
            let res = try await SupabaseManager.shared.client
                .from("perfil")
                .select("id, username, avatar_url")
                .ilike("username", pattern: "%\(text)%")
                .limit(20)
                .execute()
            self.results = try res.decodedList(to: PerfilLite.self)
        } catch { errorText = error.localizedDescription }
        loading = false
    }

    private func startChat(with user: PerfilLite) async {
        do {
            let convID = try await DMMessagingService.shared.getOrCreateDM(with: user.id)
            onCreated(convID, user)
            dismiss()
        } catch {
            errorText = (error as NSError).userInfo[NSLocalizedDescriptionKey] as? String
                       ?? error.localizedDescription
        }
    }
}
