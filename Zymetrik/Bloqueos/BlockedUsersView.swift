import SwiftUI

struct BlockedUsersView: View {
    @EnvironmentObject private var blockStore: BlockStore

    @State private var search = ""
    @State private var workingID: UUID?
    @State private var errorMsg: String?

    var body: some View {
        List {
            if !blockedFiltered.isEmpty {
                ForEach(blockedFiltered) { user in
                    HStack(spacing: 12) {
                        Avatar(urlString: user.avatar_url)
                            .frame(width: 44, height: 44)
                            .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 2) {
                            Text(user.displayName).font(.headline)
                            Text("@\(user.username)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()

                        if workingID == user.id {
                            ProgressView().frame(width: 24, height: 24)
                        } else {
                            Button("Desbloquear") { Task { await unblock(user) } }
                                .buttonStyle(.bordered)
                        }
                    }
                    .padding(.vertical, 4)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) { Task { await unblock(user) } } label: {
                            Label("Desbloquear", systemImage: "hand.raised.slash")
                        }
                    }
                }
            } else if !blockStore.isLoading {
                ContentUnavailableView(
                    "Sin usuarios bloqueados",
                    systemImage: "person.crop.circle.badge.exclamationmark",
                    description: Text("Cuando bloquees a alguien aparecerá aquí.")
                )
            }
        }
        .overlay { if blockStore.isLoading { ProgressView().controlSize(.large) } }
        .navigationTitle("Usuarios bloqueados")
        .searchable(text: $search, placement: .navigationBarDrawer(displayMode: .automatic), prompt: "Buscar usuario")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { Task { await blockStore.reload() } } label: { Image(systemName: "arrow.clockwise") }
            }
        }
        .task { await blockStore.reload() }
        .refreshable { await blockStore.reload() }
        .alert("Error", isPresented: .constant(errorMsg != nil)) {
            Button("OK", role: .cancel) { errorMsg = nil }
        } message: { Text(errorMsg ?? "") }
    }

    private var blockedFiltered: [BlockedUser] {
        let q = search.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return blockStore.blocked }
        return blockStore.blocked.filter {
            $0.username.lowercased().contains(q) ||
            $0.displayName.lowercased().contains(q)
        }
    }

    private func unblock(_ user: BlockedUser) async {
        await MainActor.run { workingID = user.id }
        defer { Task { @MainActor in workingID = nil } }
        do {
            try await BlockService.shared.unblock(targetUserID: user.id.uuidString)
            await blockStore.reload()          // ← mantiene lista y contador sincronizados
        } catch {
            await MainActor.run {
                errorMsg = "No se pudo desbloquear: \(error.localizedDescription)"
            }
        }
    }
}

private struct Avatar: View {
    let urlString: String?
    var body: some View {
        Group {
            if let urlString, let url = URL(string: urlString) {
                AsyncImage(url: url) { ph in
                    switch ph {
                    case .empty: ProgressView()
                    case .success(let img): img.resizable().scaledToFill()
                    case .failure: fallback
                    @unknown default: fallback
                    }
                }
            } else { fallback }
        }
    }
    private var fallback: some View {
        Image(systemName: "person.crop.circle.fill")
            .resizable().scaledToFill().foregroundStyle(.secondary)
    }
}
