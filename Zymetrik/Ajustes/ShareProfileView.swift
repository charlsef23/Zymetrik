import SwiftUI

struct ShareProfileView: View {
    @Environment(\.dismiss) var dismiss

    let username: String
    let profileImage: Image

    @State private var mensaje = "¡Sígueme en Zymetrik!"
    @State private var enlaceCopiado = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                
                // Tarjeta de perfil
                VStack(spacing: 12) {
                    profileImage
                        .resizable()
                        .scaledToFill()
                        .frame(width: 90, height: 90)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 3)

                    Text("@\(username)")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.primary)

                    TextField("Escribe un mensaje...", text: $mensaje)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.black.opacity(0.05), lineWidth: 1)
                        )
                        .padding(.horizontal)

                    Text("https://zymetrik.app/usuario/\(username)")
                        .font(.footnote)
                        .foregroundColor(.gray)
                        .padding(.top, 4)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)
                )
                .padding(.horizontal)

                // Botones de acción
                VStack(spacing: 14) {
                    Button {
                        UIPasteboard.general.string = "https://zymetrik.app/usuario/\(username)"
                        enlaceCopiado = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            enlaceCopiado = false
                        }
                    } label: {
                        HStack {
                            Image(systemName: enlaceCopiado ? "checkmark.circle.fill" : "doc.on.doc")
                            Text(enlaceCopiado ? "Enlace copiado" : "Copiar enlace")
                        }
                        .foregroundColor(.primary)
                        .fontWeight(.medium)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.primary.opacity(0.08))
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                        )
                        .animation(.easeInOut(duration: 0.3), value: enlaceCopiado)
                    }

                    ShareLink(item: URL(string: "https://zymetrik.app/usuario/\(username)")!) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Compartir con otras apps")
                        }
                        .foregroundColor(.primary)
                        .fontWeight(.medium)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.primary.opacity(0.08))
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal)

                Spacer()
            }
            .padding(.top)
            .navigationTitle("Compartir perfil")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
