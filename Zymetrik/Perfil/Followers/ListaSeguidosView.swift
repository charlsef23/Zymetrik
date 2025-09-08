import SwiftUI

public struct ListaSeguidosView: View {
    public let userID: String
    @State private var searchText = ""
    @State private var seguidos: [PerfilResumen] = []
    @State private var isLoading = true

    public init(userID: String) { self.userID = userID }

    private var filtrados: [PerfilResumen] {
        guard !searchText.isEmpty else { return seguidos }
        return seguidos.filter {
            $0.username.localizedCaseInsensitiveContains(searchText)
            || $0.nombre.localizedCaseInsensitiveContains(searchText)
        }
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                SearchField(placeholder: "Buscar seguidos", text: $searchText)
                if isLoading {
                    ProgressView().padding()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(filtrados) { perfil in
                                PerfilRow(perfil: perfil, showFollowButton: true)
                                Divider().padding(.leading, 72)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Seguidos")
            .task { await cargar() }
        }
    }

    private func cargar() async {
        defer { isLoading = false }
        do {
            seguidos = try await FollowersService.shared.fetchFollowing(of: userID)
        } catch {
            print("❌ Error al cargar seguidos: \(error)")
            seguidos = []
        }
    }
}
