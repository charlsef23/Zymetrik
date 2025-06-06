import SwiftUI

struct IdiomasView: View {
    @State private var idiomaSeleccionado: String = "Español"

    let idiomas: [(nombre: String, codigo: String, icono: String)] = [
        ("Español", "es", "🇪🇸"),
        ("Inglés", "en", "🇬🇧"),
        ("Francés", "fr", "🇫🇷"),
        ("Alemán", "de", "🇩🇪"),
        ("Portugués", "pt", "🇵🇹"),
        ("Italiano", "it", "🇮🇹"),
        ("Sistema", "system", "🖥️")
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Selecciona un idioma")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.top, 16)

                ForEach(idiomas, id: \.codigo) { idioma in
                    Button {
                        idiomaSeleccionado = idioma.nombre
                    } label: {
                        HStack(spacing: 16) {
                            Text(idioma.icono)
                                .font(.largeTitle)

                            Text(idioma.nombre)
                                .font(.body)
                                .foregroundColor(.primary)

                            Spacer()

                            if idiomaSeleccionado == idioma.nombre {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                                    .transition(.scale)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(idiomaSeleccionado == idioma.nombre ? Color.blue.opacity(0.1) : Color(.systemGray6))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(idiomaSeleccionado == idioma.nombre ? Color.blue : Color.clear, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .animation(.easeInOut(duration: 0.2), value: idiomaSeleccionado)
                }

                Spacer()
            }
            .padding()
        }
        .navigationTitle("Idioma")
    }
}

#Preview {
    IdiomasView()
}
