import SwiftUI
import Supabase

public struct ListaSeguidoresView: View {
    public let userID: String
    @State private var searchText = ""
    @State private var seguidores: [PerfilResumen] = []
    @State private var isLoading = true
    @State private var myUserID: String = ""

    // Ajustes de espaciado
    private let rowSpacing: CGFloat = 12
    private let searchBottomGap: CGFloat = 16

    public init(userID: String) { self.userID = userID }

    private var filtrados: [PerfilResumen] {
        guard !searchText.isEmpty else { return seguidores }
        return seguidores.filter {
            $0.username.localizedCaseInsensitiveContains(searchText)
            || $0.nombre.localizedCaseInsensitiveContains(searchText)
        }
    }

    private func idsEqual(_ a: String, _ b: String) -> Bool { a.caseInsensitiveCompare(b) == .orderedSame }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                SearchField(
                    placeholder: "Buscar seguidores",
                    text: $searchText,
                    bottomSpacing: searchBottomGap
                )

                if isLoading {
                    ProgressView().padding()
                } else {
                    ScrollView {
                        LazyVStack(spacing: rowSpacing) {
                            ForEach(filtrados) { perfil in
                                NavigationLink {
                                    if idsEqual(perfil.id, myUserID) {
                                        PerfilView()
                                    } else {
                                        UserProfileView(username: perfil.username)
                                    }
                                } label: {
                                    VStack(spacing: 8) {
                                        PerfilRow(perfil: perfil, showFollowButton: !idsEqual(perfil.id, myUserID))
                                        Divider()
                                            .padding(.leading, 72)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 12)
                    }
                }
            }
            .navigationTitle("Seguidores")
            .task { await cargar() }
        }
    }

    private func cargar() async {
        defer { isLoading = false }
        do {
            // Intenta obtener el usuario actual (no falla la carga si no hay sesión)
            do {
                let session = try await SupabaseManager.shared.client.auth.session
                myUserID = session.user.id.uuidString
            } catch {
                // Si la sesión caducó, intenta refrescar y recuperar
                do {
                    _ = try await SupabaseManager.shared.client.auth.refreshSession()
                    let session = try await SupabaseManager.shared.client.auth.session
                    myUserID = session.user.id.uuidString
                } catch {
                    // sin sesión; dejar myUserID vacío
                    myUserID = ""
                }
            }
            seguidores = try await FollowersService.shared.fetchFollowers(of: userID)
        } catch {
            print("❌ Error al cargar seguidores: \(error)")
            seguidores = []
        }
    }
}

