import SwiftUI

struct UsuarioRowView: View {
    let perfil: Perfil
    @Binding var seguidos: Set<UUID>

    var body: some View {
        HStack(spacing: 14) {
            if let url = perfil.avatar_url, let imageURL = URL(string: url) {
                AsyncImage(url: imageURL) { image in
                    image.resizable()
                } placeholder: {
                    Color.gray.opacity(0.3)
                }
                .frame(width: 44, height: 44)
                .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 44, height: 44)
                    .foregroundColor(.gray)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(perfil.username)
                    .font(.headline)
                Text(perfil.nombre)
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()

            Button {
                if seguidos.contains(perfil.id) {
                    seguidos.remove(perfil.id)
                } else {
                    seguidos.insert(perfil.id)
                }
            } label: {
                Text(seguidos.contains(perfil.id) ? "Siguiendo" : "Seguir")
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(seguidos.contains(perfil.id) ? Color(.systemGray5) : Color.black)
                    .foregroundColor(seguidos.contains(perfil.id) ? .black : .white)
                    .cornerRadius(20)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 12)
        .padding(.horizontal)
    }
}
