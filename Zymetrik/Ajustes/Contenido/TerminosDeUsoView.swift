import SwiftUI

struct TerminosDeUsoView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Términos de Uso (también EULA)")
                    .font(.largeTitle).bold()
                    .padding(.top)

                Text("Última actualización: 25 de octubre de 2025")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                section(title: "1. Aceptación de los términos", content:
"""
Al utilizar la aplicación Zymetrik (la \"App\"), aceptas estos Términos de Uso (los \"Términos\"), que actúan también como Acuerdo de Licencia de Usuario Final (EULA). Si no estás de acuerdo con alguno de los términos, no utilices la App.
""")

                section(title: "2. Licencia de uso (EULA)", content:
"""
Al descargar o utilizar Zymetrik, se te concede una licencia limitada, personal, no exclusiva, intransferible, revocable y no sublicenciable para usar la App conforme a estos Términos. No adquieres la propiedad de la App ni de sus componentes; solo un derecho de uso bajo licencia.
""")

                section(title: "3. Uso de la App", content:
"""
Te comprometes a utilizar la App de forma legal y responsable. No podrás: (a) realizar ingeniería inversa, descompilar o intentar extraer el código fuente; (b) usar la App para actividades fraudulentas o ilícitas; (c) interferir con la seguridad o el rendimiento del servicio.
""")

                section(title: "4. Registro y cuenta", content:
"""
Es posible que se requiera crear una cuenta para acceder a ciertas funciones. Eres responsable de mantener la confidencialidad de tus credenciales y de todas las actividades que ocurran bajo tu cuenta.
""")

                section(title: "5. Contenido y propiedad intelectual", content:
"""
Todos los derechos, títulos e intereses sobre la App y su contenido (incluyendo marcas, logotipos, interfaces y software) pertenecen a sus respectivos titulares y están protegidos por las leyes aplicables. No se te otorga ninguna licencia excepto la estrictamente necesaria para utilizar la App conforme a estos Términos.
""")

                section(title: "6. Privacidad y datos", content:
"""
Tratamos tus datos de acuerdo con nuestra Política de Privacidad. Al usar la App, consientes dicho tratamiento. Revisa la Política de Privacidad para conocer qué datos recopilamos, cómo los usamos y tus derechos: https://zymetrik.com/privacidad.html
""")

                section(title: "7. Suscripciones y pagos (si aplica)", content:
"""
Algunas funciones pueden requerir una suscripción o pago. Los precios, períodos de facturación, pruebas gratuitas y renovaciones automáticas se detallan en la pantalla de compra y en la App Store. Las gestiones de cancelación y reembolsos se realizan conforme a las políticas de Apple.
""")

                section(title: "8. Limitación de responsabilidad", content:
"""
La App se proporciona \"tal cual\" y \"según disponibilidad\". En la medida permitida por la ley, Zymetrik y sus desarrolladores no serán responsables por daños indirectos, incidentales, especiales o consecuentes derivados del uso o la imposibilidad de uso de la App.
""")

                section(title: "9. Garantías", content:
"""
No garantizamos que la App esté libre de errores, sea ininterrumpida o cumpla con tus expectativas específicas. Podremos realizar mejoras o cambios en cualquier momento.
""")

                section(title: "10. Terminación", content:
"""
Podemos suspender o terminar tu acceso a la App si incumples estos Términos o si lo consideramos necesario por razones legales, de seguridad o de operación.
""")

                section(title: "11. Modificaciones de los términos", content:
"""
Podremos actualizar estos Términos (EULA) de vez en cuando. Publicaremos la versión actualizada en la App y/o en https://zymetrik.com/terminos.html. El uso continuado después de la publicación implica la aceptación de los cambios.
""")

                section(title: "12. Legislación aplicable y jurisdicción", content:
"""
Estos Términos se regirán por las leyes aplicables en tu país o región, sin perjuicio de las normas sobre conflicto de leyes. Cualquier disputa se someterá a los tribunales competentes del domicilio del consumidor, cuando así lo prevea la normativa aplicable.
""")

                section(title: "13. Contacto", content:
"""
Si tienes preguntas sobre estos Términos (EULA), puedes contactarnos en: soportezymetrik@outlook.es
""")

                Spacer(minLength: 24)

                Button("He leído y acepto") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 24)
            }
            .padding(.horizontal)
        }
        .navigationTitle("Términos de Uso")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Cerrar") { dismiss() }
            }
        }
    }

    @ViewBuilder
    private func section(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            Text(content)
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 8)
    }
}

#Preview {
    NavigationStack {
        TerminosDeUsoView()
    }
}
