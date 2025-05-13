import SwiftUI

struct MensajesView: View {
    @State private var searchText = ""

    let chats = ["carlafit", "gymbro", "ztrainer", "entrena_con_lu", "mari_lifts"]

    var chatsFiltrados: [String] {
        searchText.isEmpty ? chats : chats.filter {
            $0.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 🔍 Barra de búsqueda
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)

                    TextField("Buscar usuario", text: $searchText)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)

                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
                .padding(.top, 8)

                // 📋 Lista de chats
                List(chatsFiltrados, id: \.self) { usuario in
                    NavigationLink(destination: ChatView(usuario: usuario)) {
                        HStack(spacing: 14) {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: 44, height: 44)
                                .foregroundColor(.gray)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(usuario)
                                    .font(.headline)
                                Text("Último mensaje aquí...")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.vertical, 6)
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Mensajes")
        }
    }
}
