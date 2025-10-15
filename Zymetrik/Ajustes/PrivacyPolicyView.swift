import SwiftUI

private struct PolicySection: Identifiable {
    let id = UUID()
    let title: String
    let body: [String]
}

struct PrivacyPolicyView: View {
    private let sections: [PolicySection] = [
        PolicySection(title: "Identidad del responsable", body: [
            "Responsable del tratamiento: Carlos Esteve",
            "Correo de contacto: soportezymetrik@outlook.es",
            "Ubicación: España",
            "Zymetrik es una aplicación móvil disponible en iOS que permite registrar entrenamientos, compartir publicaciones, interactuar con otros usuarios y acceder a funcionalidades avanzadas mediante suscripción."
        ]),
        PolicySection(title: "Datos personales que se recopilan", body: [
            "Datos de registro: correo electrónico, nombre, nombre de usuario y avatar.",
            "Datos de actividad: estadísticas de entrenamiento, ejercicios, rutinas y progresos.",
            "Datos sociales: publicaciones, comentarios, mensajes directos y seguidores.",
            "Datos de suscripción: información sobre las compras o renovaciones de Zymetrik PRO a través del sistema de pago de la App Store.",
            "Datos de notificaciones: identificadores de dispositivo necesarios para enviar notificaciones push.",
            "Zymetrik no recopila datos de localización precisa, datos biométricos ni información sensible."
        ]),
        PolicySection(title: "Finalidad del tratamiento", body: [
            "Creación y gestión de la cuenta de usuario.",
            "Sincronización y almacenamiento de datos de entrenamiento en la nube mediante Supabase e iCloud.",
            "Publicación de contenido y funcionalidades sociales (posts, comentarios, mensajes).",
            "Gestión de suscripciones y pagos a través de Apple App Store.",
            "Envío de notificaciones push, como interacciones sociales o recordatorios de entrenamiento.",
            "Mejora de la experiencia del usuario y mantenimiento del servicio."
        ]),
        PolicySection(title: "Base legal del tratamiento", body: [
            "Ejecución de un contrato: para prestar los servicios principales de la app.",
            "Consentimiento del usuario: para recibir notificaciones y comunicaciones.",
            "Cumplimiento de obligaciones legales: en materia fiscal o de facturación derivadas de las suscripciones.",
            "Interés legítimo: para garantizar la seguridad de la aplicación y prevenir fraudes o abusos."
        ]),
        PolicySection(title: "Servicios y destinatarios de los datos", body: [
            "Supabase: Base de datos, autenticación y almacenamiento de contenido (UE / Irlanda).",
            "Apple App Store / In-App Purchases: Procesamiento de pagos y gestión de suscripciones (UE / EE. UU.).",
            "iCloud / CloudKit: Sincronización y copia de seguridad local del usuario (UE).",
            "OneSignal: Envío de notificaciones push (EE. UU. — Cláusulas contractuales tipo RGPD).",
            "Zymetrik no vende ni cede datos personales a terceros con fines comerciales."
        ]),
        PolicySection(title: "Conservación de los datos", body: [
            "Los datos personales se conservarán mientras el usuario mantenga su cuenta activa.",
            "Cuando el usuario elimina su cuenta, todos los datos personales se eliminan de Supabase y de los servicios asociados en un plazo máximo de 30 días."
        ]),
        PolicySection(title: "Derechos del usuario", body: [
            "El usuario puede ejercer sus derechos de acceso, rectificación, supresión, oposición, limitación y portabilidad enviando una solicitud al correo: soportezymetrik@outlook.es.",
            "Asimismo, el usuario tiene derecho a presentar una reclamación ante la Agencia Española de Protección de Datos (AEPD)."
        ]),
        PolicySection(title: "Seguridad", body: [
            "Zymetrik aplica medidas técnicas y organizativas adecuadas para proteger la información, incluyendo cifrado, autenticación segura y control de acceso mediante Supabase y iCloud.",
            "Ningún sistema es completamente infalible; el usuario debe mantener su dispositivo y credenciales protegidos."
        ]),
        PolicySection(title: "Menores de edad", body: [
            "Zymetrik está dirigida a usuarios mayores de 16 años.",
            "No se recopila intencionadamente información de menores. Si se detecta una cuenta de un menor de edad, será eliminada inmediatamente."
        ]),
        PolicySection(title: "Cambios en esta política", body: [
            "Zymetrik podrá actualizar esta Política de Privacidad en cualquier momento para adaptarla a cambios legales o funcionales.",
            "La fecha de última actualización se indicará al inicio del documento."
        ]),
        PolicySection(title: "Contacto", body: [
            "Correo: soportezymetrik@outlook.es",
            "Responsable: Carlos Esteve — España"
        ])
    ]

    let content: String

    init(content: String = PrivacyPolicyView.sampleText) {
        self.content = content
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack(alignment: .center, spacing: 12) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(.tint)
                        .symbolRenderingMode(.hierarchical)
                    VStack(alignment: .center, spacing: 4) {
                        Text("Política de Privacidad")
                            .font(.title2).bold()
                            .multilineTextAlignment(.center)
                        Text("Lee cómo tratamos tus datos en Zymetrik")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(16)
                .background(.regularMaterial, in: .rect(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(.quaternary, lineWidth: 0.5)
                )
                

                // Content
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(sections) { section in
                        ZStack(alignment: .topLeading) {
                            // Full-width card background
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.thinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(.quaternary, lineWidth: 0.5)
                                )
                                .frame(maxWidth: .infinity)

                            // Section content
                            VStack(alignment: .leading, spacing: 8) {
                                Text(section.title)
                                    .font(.headline)
                                VStack(alignment: .leading, spacing: 6) {
                                    ForEach(section.body, id: \.self) { line in
                                        HStack(alignment: .top, spacing: 8) {
                                            Text("•").bold().accessibilityHidden(true)
                                            Text(line)
                                                .font(.body)
                                                .multilineTextAlignment(.leading)
                                        }
                                    }
                                }
                            }
                            .padding(16)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    // Footer / last updated
                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.thinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(.quaternary, lineWidth: 0.5)
                            )
                            .frame(maxWidth: .infinity)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Última actualización: 15 de octubre de 2025")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(16)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: 700)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .scrollIndicators(.visible)
        .background(.background.opacity(0.6))
        .navigationTitle("Privacidad")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(item: content) {
                    Image(systemName: "square.and.arrow.up")
                }
                .accessibilityLabel("Compartir política de privacidad")
            }
        }
    }

    static let sampleText = """
    POLÍTICA DE PRIVACIDAD DE ZYMETRIK Última actualización: 15 de octubre
    de 2025

    1.  Identidad del responsable Responsable del tratamiento: Carlos Esteve
        Correo de contacto: soportezymetrik@outlook.es Ubicación: España

    Zymetrik es una aplicación móvil disponible en iOS que permite registrar
    entrenamientos, compartir publicaciones, interactuar con otros usuarios
    y acceder a funcionalidades avanzadas mediante suscripción.

    2.  Datos personales que se recopilan Zymetrik recopila los siguientes
        tipos de datos personales cuando el usuario utiliza la app:

    -   Datos de registro: correo electrónico, nombre, nombre de usuario y
        avatar.
    -   Datos de actividad: estadísticas de entrenamiento, ejercicios,
        rutinas y progresos.
    -   Datos sociales: publicaciones, comentarios, mensajes directos y
        seguidores.
    -   Datos de suscripción: información sobre las compras o renovaciones
        de Zymetrik PRO a través del sistema de pago de la App Store.
    -   Datos de notificaciones: identificadores de dispositivo necesarios
        para enviar notificaciones push. Zymetrik no recopila datos de
        localización precisa, datos biométricos ni información sensible.

    3.  Finalidad del tratamiento Los datos personales se tratan para las
        siguientes finalidades:

    4.  Creación y gestión de la cuenta de usuario.

    5.  Sincronización y almacenamiento de datos de entrenamiento en la nube
        mediante Supabase e iCloud.

    6.  Publicación de contenido y funcionalidades sociales (posts,
        comentarios, mensajes).

    7.  Gestión de suscripciones y pagos a través de Apple App Store.

    8.  Envío de notificaciones push, como interacciones sociales o
        recordatorios de entrenamiento.

    9.  Mejora de la experiencia del usuario y mantenimiento del servicio.

    10. Base legal del tratamiento El tratamiento de los datos se realiza
        sobre las siguientes bases legales:

    -   Ejecución de un contrato: para prestar los servicios principales de
        la app.
    -   Consentimiento del usuario: para recibir notificaciones y
        comunicaciones.
    -   Cumplimiento de obligaciones legales: en materia fiscal o de
        facturación derivadas de las suscripciones.
    -   Interés legítimo: para garantizar la seguridad de la aplicación y
        prevenir fraudes o abusos.

    5.  Servicios y destinatarios de los datos Zymetrik utiliza los
        siguientes proveedores externos, todos ellos con medidas de
        seguridad adecuadas:

    -   Supabase: Base de datos, autenticación y almacenamiento de contenido
        (UE / Irlanda)
    -   Apple App Store / In-App Purchases: Procesamiento de pagos y gestión
        de suscripciones (UE / EE. UU.)
    -   iCloud / CloudKit: Sincronización y copia de seguridad local del
        usuario (UE)
    -   OneSignal: Envío de notificaciones push (EE. UU. — Cláusulas
        contractuales tipo RGPD) Zymetrik no vende ni cede datos personales
        a terceros con fines comerciales.

    6.  Conservación de los datos Los datos personales se conservarán
        mientras el usuario mantenga su cuenta activa. Cuando el usuario
        elimina su cuenta, todos los datos personales se eliminan de
        Supabase y de los servicios asociados en un plazo máximo de 30 días.

    7.  Derechos del usuario El usuario puede ejercer sus derechos de
        acceso, rectificación, supresión, oposición, limitación y
        portabilidad enviando una solicitud al correo:
        soportezymetrik@outlook.es Asimismo, el usuario tiene derecho a
        presentar una reclamación ante la Agencia Española de Protección de
        Datos (AEPD).

    8.  Seguridad Zymetrik aplica medidas técnicas y organizativas adecuadas
        para proteger la información, incluyendo cifrado, autenticación
        segura y control de acceso mediante Supabase y iCloud. Sin embargo,
        ningún sistema es completamente infalible; el usuario debe mantener
        su dispositivo y credenciales protegidos.

    9.  Menores de edad Zymetrik está dirigida a usuarios mayores de 16
        años. No se recopila intencionadamente información de menores. Si se
        detecta una cuenta de un menor de edad, será eliminada
        inmediatamente.

    10. Cambios en esta política Zymetrik podrá actualizar esta Política de
        Privacidad en cualquier momento para adaptarla a cambios legales o
        funcionales. La fecha de última actualización se indicará al inicio
        del documento.

    11. Contacto Correo: soportezymetrik@outlook.es Responsable: Carlos
        Esteve — España
    """
}
