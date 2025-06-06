import SwiftUI

struct SettingsView: View {
    @State private var mostrarShare = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {

                    // ENCABEZADO: Centro de cuentas
                    HStack(spacing: 16) {
                        Image("foto_perfil") // Usa tu imagen real o sistema
                            .resizable()
                            .scaledToFill()
                            .frame(width: 56, height: 56)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.primary, lineWidth: 1))

                        Text("Centro de cuentas")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.primary)

                        Spacer()

                        Button(action: {
                            mostrarShare = true
                        }) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.primary)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(.systemBackground))
                            .shadow(color: Color.primary.opacity(0.05), radius: 5, x: 0, y: 3)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal)

                    // SECCIONES
                    VStack(spacing: 32) {
                        SectionGroup(title: "Zymetrik", items: [
                            SettingRow(icon: "bookmark.fill", title: "Guardado", destination: AnyView(GuardadosView())),
                            SettingRow(icon: "bell.fill", title: "Notificaciones", destination: AnyView(Text("NotificacionesView()")))
                        ])

                        SectionGroup(title: "Quién puede ver tu contenido", items: [
                            SettingRow(icon: "lock.fill", title: "Privacidad de la cuenta", value: "Privada", destination: AnyView(Text("PrivacidadView()"))),
                            SettingRow(icon: "square.grid.2x2", title: "Publicaciones cruzadas", destination: AnyView(Text("PublicacionesView()"))),
                            SettingRow(icon: "hand.raised.fill", title: "Cuentas bloqueadas", value: "4", destination: AnyView(CuentasBloqueadasView()))
                        ])

                        SectionGroup(title: "Cómo pueden interactuar contigo los demás", items: [
                            SettingRow(icon: "message.fill", title: "Mensajes", destination: AnyView(Text("MensajesView()"))),
                            SettingRow(icon: "at", title: "Etiquetas y menciones", destination: AnyView(Text("EtiquetasView()"))),
                            SettingRow(icon: "text.bubble.fill", title: "Comentarios", destination: AnyView(Text("ComentariosView()")))
                        ])

                        SectionGroup(title: "Soporte", items: [
                            SettingRow(icon: "envelope.fill", title: "Enviar feedback", destination: AnyView(Text("FeedbackView()"))),
                            SettingRow(icon: "questionmark.circle.fill", title: "Contactar con soporte", destination: AnyView(Text("SoporteView()"))),
                            SettingRow(icon: "book.fill", title: "FAQ", destination: AnyView(Text("FAQView()")))
                        ])

                        SectionGroup(title: "Cuenta", items: [
                            SettingRow(icon: "rectangle.portrait.and.arrow.forward", title: "Cerrar sesión", destination: AnyView(Text("CerrarSesionView()"))),
                            SettingRow(icon: "trash.fill", title: "Eliminar cuenta", destination: AnyView(Text("EliminarCuentaView()")))
                        ])

                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal)
                }
                .padding(.top, 16)
            }
            .background(Color.white)
            .navigationTitle("Configuración")
            .sheet(isPresented: $mostrarShare) {
                ShareProfileView(
                    username: "carlos",
                    profileImage: Image("foto_perfil")
                )
            }
        }
    }
}

#Preview {
    SettingsView()
}
