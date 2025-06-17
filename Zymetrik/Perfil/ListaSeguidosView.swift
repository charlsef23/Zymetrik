import SwiftUI

struct ListaSeguidosView: View {
    @State private var searchText = ""
    @State private var seguidos: [String] = []
    @State private var isLoading = true
    
    var seguidosFiltrados: [String] {
        searchText.isEmpty ? seguidos : seguidos.filter {
            $0.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Buscar seguidos", text: $searchText)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                    if !searchText.isEmpty {
                        Button { searchText = "" } label: {
                            Image(systemName: "xmark.circle.fill").foregroundColor(.gray)
                        }
                    }
                }
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
                .padding(.top, 8)
                
                if isLoading {
                    ProgressView()
                        .padding()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(seguidosFiltrados, id: \.self) { username in
                                NavigationLink(destination: UserProfileView(username: username)) {
                                    HStack(spacing: 14) {
                                        Image(systemName: "person.circle.fill")
                                            .resizable()
                                            .frame(width: 44, height: 44)
                                            .foregroundColor(.gray)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(username)
                                                .font(.headline)
                                            Text("Ver perfil")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                        
                                        Spacer()
                                    }
                                    .padding(.vertical, 12)
                                    .padding(.horizontal)
                                }
                                .buttonStyle(.plain)
                                
                                Divider().padding(.leading, 72)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Seguidos")
            .onAppear {
                Task { await cargarSeguidos() }
            }
        }
    }
    
    func cargarSeguidos() async {
        guard let userID = try? await SupabaseManager.shared.client.auth.session.user.id.uuidString else { return }

        do {
            let response = try await SupabaseManager.shared.client
                .rpc("get_following_usernames", params: ["user_id": userID])
                .execute()

            if let jsonArray = try? JSONSerialization.jsonObject(with: response.data) as? [[String: Any]] {
                self.seguidos = jsonArray.compactMap { $0["username"] as? String }
            }
        } catch {
            print("❌ Error al cargar seguidos: \(error)")
        }

        isLoading = false
    }
}
