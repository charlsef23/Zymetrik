import SwiftUI

struct SettingsView: View {
    @State private var mostrarShare = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // PERFIL
                    HStack(spacing: 16) {
                        Image("foto_perfil")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())

                        VStack(alignment: .leading) {
                            Text("Carlos Esteve")
                                .font(.headline)
                            Button("Compartir perfil") {
                                mostrarShare = true
                            }
                            .font(.caption)
                            .foregroundColor(.black)
                        }

                        Spacer()
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    .padding(.horizontal)

                    // SECCIONES
                    VStack(spacing: 24) {
                        settingsCard(title: "Zymetrik", items: [
                            ("bookmark.fill", "Guardado", AnyView(Text("GuardadosView()"))),
                            ("bell.fill", "Notificaciones", AnyView(Text("NotificacionesView()")))
                        ])

                        settingsCard(title: "Quién puede ver tu contenido", items: [
                            ("lock.fill", "Privacidad de la cuenta", AnyView(Text("PrivacidadView()")), "Privada"),
                            ("hand.raised.fill", "Cuentas bloqueadas", AnyView(CuentasBloqueadasView()), "4")
                        ])

                        settingsCard(title: "Cómo pueden interactuar contigo los demás", items: [
                            ("message.fill", "Mensajes", AnyView(Text("MensajesView()")))
                        ])

                        settingsCard(title: "Soporte", items: [
                            ("envelope.fill", "Enviar feedback", AnyView(Text("FeedbackView()"))),
                            ("questionmark.circle.fill", "Contactar con soporte", AnyView(Text("SoporteView()"))),
                            ("book.fill", "FAQ", AnyView(Text("FAQView()")))
                        ])

                        settingsCard(title: "Cuenta", items: [
                            ("rectangle.portrait.and.arrow.forward", "Cerrar sesión", AnyView(Text("CerrarSesionView()"))),
                            ("trash.fill", "Eliminar cuenta", AnyView(Text("EliminarCuentaView()")))
                        ])
                    }
                    .padding(.horizontal)
                    .foregroundColor(.black)
                }
                .padding(.top)
            }
            .navigationTitle("Configuración")
            .sheet(isPresented: $mostrarShare) {
                ShareProfileView(username: "carlos", profileImage: Image("foto_perfil"))
            }
        }
    }

    @ViewBuilder
    func settingsCard(title: String, items: [(String, String, AnyView, String?)]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.bottom, 8)

            VStack(spacing: 0) {
                ForEach(0..<items.count, id: \.self) { i in
                    let item = items[i]
                    NavigationLink(destination: item.2) {
                        HStack {
                            Image(systemName: item.0)
                                .foregroundColor(.black)
                                .frame(width: 24)
                            Text(item.1)
                            Spacer()
                            if let value = item.3 {
                                Text(value)
                                    .foregroundColor(.gray)
                                    .font(.caption)
                            }
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.black)
                        }
                        .padding(.vertical, 12)
                    }

                    if i < items.count - 1 {
                        Divider()
                    }
                }
            }
            .background(.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.02), radius: 1, x: 0, y: 1)
        }
    }

    // Overload para items sin valor
    func settingsCard(title: String, items: [(String, String, AnyView)]) -> some View {
        settingsCard(title: title, items: items.map { ($0.0, $0.1, $0.2, nil) })
    }
}
