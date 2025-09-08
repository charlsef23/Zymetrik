import SwiftUI

struct LikersListView: View {
    let postID: UUID

    @State private var likers: [SupabaseService.Liker] = []
    @State private var isLoading = false
    @State private var reachedEnd = false

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(likers) { liker in
                    LikerRow(liker: liker)
                        .task {
                            if liker == likers.last, !isLoading, !reachedEnd {
                                await loadMore()
                            }
                        }
                }

                if isLoading {
                    HStack {
                        ProgressView()
                        Text("Cargando…")
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .listStyle(.plain)
            .navigationTitle("Me gusta")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cerrar") { dismiss() }
                }
            }
            .refreshable { await refresh() }
            .task { await refresh() }
        }
    }

    private func refresh() async {
        isLoading = true
        reachedEnd = false
        do {
            let page = try await SupabaseService.shared.fetchLikers(postID: postID, limit: 30, before: nil)
            await MainActor.run {
                likers = page
                isLoading = false
                reachedEnd = page.isEmpty
            }
        } catch {
            await MainActor.run { isLoading = false }
            print("❌ Error cargando likers:", error)
        }
    }

    private func loadMore() async {
        guard let last = likers.last else { return }
        isLoading = true
        do {
            let page = try await SupabaseService.shared.fetchLikers(postID: postID, limit: 30, before: last.liked_at)
            await MainActor.run {
                likers.append(contentsOf: page)
                isLoading = false
                reachedEnd = page.isEmpty
            }
        } catch {
            await MainActor.run { isLoading = false }
            print("❌ Error cargando más likers:", error)
        }
    }
}

private struct LikerRow: View {
    let liker: SupabaseService.Liker

    var body: some View {
        HStack(spacing: 12) {
            Avatar(urlString: liker.avatar_url)
                .frame(width: 44, height: 44)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(liker.nombre)
                    .font(.system(.body, design: .rounded)).fontWeight(.semibold)
                Text("@\(liker.username)")
                    .foregroundStyle(.secondary)
                    .font(.system(.subheadline, design: .rounded))
            }

            Spacer()

            Text(liker.liked_at.timeAgoDisplay())
                .foregroundStyle(.secondary)
                .font(.system(.footnote, design: .rounded))
        }
        .padding(.vertical, 4)
    }
}

private struct Avatar: View {
    let urlString: String?
    var body: some View {
        if let s = urlString, let url = URL(string: s) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    ZStack {
                        Circle().fill(Color(.systemGray5))
                        ProgressView()
                    }
                case .success(let img):
                    img.resizable().scaledToFill()
                case .failure:
                    Circle().fill(Color(.systemGray5))
                        .overlay(Image(systemName: "person.fill").foregroundStyle(.secondary))
                @unknown default:
                    Circle().fill(Color(.systemGray5))
                }
            }
        } else {
            Circle().fill(Color(.systemGray5))
                .overlay(Image(systemName: "person.fill").foregroundStyle(.secondary))
        }
    }
}
