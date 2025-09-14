import SwiftUI

public struct ListaSeguidosView: View {
    public let userID: String
    @State private var searchText = ""
    @State private var seguidos: [PerfilResumen] = []
    @State private var isLoading = true

    // Ajustes de espaciado
    private let rowSpacing: CGFloat = 12
    private let searchBottomGap: CGFloat = 16

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
                SearchField(
                    placeholder: "Buscar seguidos",
                    text: $searchText,
                    bottomSpacing: searchBottomGap
                )

                if isLoading {
                    ProgressView().padding()
                } else {
                    ScrollView {
                        LazyVStack(spacing: rowSpacing) {
                            ForEach(filtrados) { perfil in
                                VStack(spacing: 8) {
                                    PerfilRow(perfil: perfil, showFollowButton: true)
                                    Divider()
                                        .padding(.leading, 72)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 12)
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
