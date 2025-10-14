import SwiftUI

struct FAQItem: Identifiable, Hashable {
    let id = UUID()
    let question: String
    let answer: String
}

struct FAQView: View {
    @State private var searchText: String = ""
    @State private var expanded: Set<UUID> = []

    private var faqs: [FAQItem] = [
        FAQItem(question: "¿Cómo restablezco mi contraseña?", answer: "Ve a Configuración > Cuenta > Cambiar contraseña y sigue los pasos."),
        FAQItem(question: "¿Cómo borro mis datos?", answer: "Desde Configuración > Cuenta > Eliminar cuenta puedes solicitar el borrado completo de tus datos."),
        FAQItem(question: "¿Puedo exportar mis entrenamientos?", answer: "De momento no, pero estamos trabajando en ello."),
        FAQItem(question: "¿Cómo reporto un problema?", answer: "Usa la sección Soporte para escribirnos directamente desde la app."),
        FAQItem(question: "¿Por qué no recibo notificaciones?", answer: "Comprueba que las notificaciones estén activadas en Ajustes del sistema y dentro de la app en Configuración > Notificaciones.")
    ]

    private var filteredFAQs: [FAQItem] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return faqs }
        return faqs.filter { $0.question.localizedCaseInsensitiveContains(q) || $0.answer.localizedCaseInsensitiveContains(q) }
    }

    var body: some View {
        List {
            ForEach(filteredFAQs) { item in
                Section {
                    DisclosureGroup(isExpanded: Binding(
                        get: { expanded.contains(item.id) },
                        set: { isExpanding in
                            if isExpanding {
                                _ = expanded.insert(item.id)
                            } else {
                                expanded.remove(item.id)
                            }
                        }
                    )) {
                        Text(item.answer)
                            .foregroundStyle(.secondary)
                            .padding(.top, 4)
                    } label: {
                        Text(item.question)
                            .font(.body)
                    }
                }
            }
        }
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Buscar en FAQ")
        .navigationTitle("FAQ")
    }
}

#Preview {
    NavigationStack { FAQView() }
}
