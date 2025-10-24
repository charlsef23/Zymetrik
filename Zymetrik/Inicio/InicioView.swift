import SwiftUI

struct InicioView: View {
    @EnvironmentObject private var feedStore: FeedStore

    enum FeedSelection: String, CaseIterable, Identifiable {
        case paraTi = "Para ti"
        case siguiendo = "Siguiendo"
        var id: String { rawValue }
    }

    @State private var selectedFeed: FeedSelection = .paraTi

    private var posts: [Post] {
        switch selectedFeed {
        case .paraTi:   return feedStore.paraTiPosts
        case .siguiendo:return feedStore.siguiendoPosts
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if let msg = feedStore.errorMessage {
                    Text(msg)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                        .padding(.top, 8)
                }

                ScrollView {
                    LazyVStack(spacing: 24) {
                        ForEach(posts) { post in
                            PostView(post: post, feedKey: selectedFeed)
                        }
                    }
                    .id(selectedFeed.rawValue)
                    .padding(.top)
                }
                .refreshable {
                    await feedStore.reload(selection: selectedFeed)
                }
            }
            .ignoresSafeArea(edges: .bottom)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Picker("Feed", selection: $selectedFeed) {
                            ForEach(FeedSelection.allCases) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text(selectedFeed.rawValue).font(.headline)
                            Image(systemName: "chevron.down")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .contentShape(Rectangle())
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 20) {
                        NavigationLink(destination: AlertasView()) { Image(systemName: "bell.fill") }
                        NavigationLink(destination: DMInboxView()) { Image(systemName: "paperplane.fill") }
                    }
                    .font(.system(size: 16, weight: .medium))
                }
            }
        }
    }
}
