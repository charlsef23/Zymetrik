import SwiftUI

struct ListaSeguidoresView: View {
    let userID: String
    
    @State private var searchText = ""
    @State private var seguidores: [String] = []
    @State private var isLoading = true
    
    var seguidoresFiltrados: [String] {
        searchText.isEmpty ? seguidores : seguidores.filter {
            $0.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Buscar seguidores", text: $searchText)
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
                            ForEach(seguidoresFiltrados, id: \.self) { username in
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
            .navigationTitle("Seguidores")
            .onAppear {
                Task { await cargarSeguidores() }
            }
        }
    }
    
    func cargarSeguidores() async {
        do {
            let response = try await SupabaseManager.shared.client
                .rpc("get_follower_usernames", params: ["user_id": userID])
                .execute()

            if let jsonArray = try? JSONSerialization.jsonObject(with: response.data) as? [[String: Any]] {
                self.seguidores = jsonArray.compactMap { $0["username"] as? String }
            }
        } catch {
            print("❌ Error al cargar seguidores: \(error)")
        }

        isLoading = false
    }
}
