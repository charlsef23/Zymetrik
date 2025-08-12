// Screens/DMNewChatView.swift
import SwiftUI

struct DMNewChatView: View {
    var onCreated: (UUID) -> Void = { _ in }
    
    @Environment(\.dismiss) private var dismiss
    @State private var query: String = ""
    @State private var results: [PerfilLite] = []
    @State private var loading = false
    @State private var errorText: String?
    
    var body: some View {
        VStack {
            HStack {
                TextField("Buscar username…", text: $query)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .padding(10)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                if loading { ProgressView() }
            }
            .padding(.horizontal)
            .padding(.top, 8)
            
            List(results) { user in
                Button {
                    Task { await startChat(with: user) }
                } label: {
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
        .onChange(of: query) { _, newValue in
            Task { await search(text: newValue) }
        }
    }
    
    private func search(text: String) async {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            results = []; return
        }
        loading = true; errorText = nil
        do {
            let res = try await SupabaseManager.shared.client
                .from("perfil")
                .select("id, username, avatar_url")
                .ilike("username", pattern: "%\(text)%")
                .limit(20)
                .execute()
            self.results = try res.decodedList(to: PerfilLite.self)
        } catch {
            errorText = error.localizedDescription
        }
        loading = false
    }
    
    private func startChat(with user: PerfilLite) async {
        do {
            let convID = try await DMMessagingService.shared.getOrCreateDM(with: user.id)
            onCreated(convID)
            dismiss()
        } catch {
            errorText = error.localizedDescription
        }
    }
}
