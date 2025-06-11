import SwiftUI

struct SettingsView: View {
    @State private var mostrarShare = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
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
