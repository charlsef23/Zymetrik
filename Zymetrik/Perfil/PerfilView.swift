import SwiftUI

struct PerfilView: View {
    @State private var selectedTab: PerfilTab = .entrenamientos
    @State private var showAjustes = false

    let entrenamientos = [
        "Pecho y tríceps",
        "Pierna completa",
        "Espalda y bíceps"
    ]

    let logros: [Logro] = [
        Logro(titulo: "Primer entrenamiento", descripcion: "Completaste tu primer día en Zymetrik", icono: "star.fill"),
        Logro(titulo: "5 entrenos", descripcion: "Has registrado 5 entrenamientos", icono: "flame.fill"),
        Logro(titulo: "Semana completa", descripcion: "Entrenaste 7 días seguidos", icono: "calendar.circle.fill")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Foto y nombre
                    VStack(spacing: 8) {
                        Image("foto_perfil")
                            .resizable()
                            .frame(width: 90, height: 90)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.secondary, lineWidth: 1))

                        Text("Carlitos")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("📱 Creador de @zymetrik.app\n👨🏻‍💻 Apple Developer · SwiftUI ")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top)

                    // Contadores con navegación
                    HStack {
                        Spacer()
                        VStack {
                            Text("12")
                                .font(.headline)
                                .foregroundColor(.black)
                            Text("Entrenos")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        NavigationLink(destination: ListaSeguidoresView()) {
                            VStack {
                                Text("910")
                                    .font(.headline)
                                    .foregroundColor(.black)
                                Text("Seguidores")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                        NavigationLink(destination: ListaSeguidosView()) {
                            VStack {
                                Text("562")
                                    .font(.headline)
                                    .foregroundColor(.black)
                                Text("Siguiendo")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                    }

                    // Botón editar perfil
                    Button(action: {
                        // Acción editar perfil
                    }) {
                        Text("Editar perfil")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray6))
                            .foregroundColor(.black)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)

                    // Tabs
                    HStack {
                        ForEach(PerfilTab.allCases, id: \.self) { tab in
                            Button {
                                selectedTab = tab
                            } label: {
                                Text(tab.rawValue)
                                    .fontWeight(selectedTab == tab ? .bold : .regular)
                                    .foregroundColor(selectedTab == tab ? .black : .gray)
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 16)
                                    .background(
                                        Capsule()
                                            .fill(selectedTab == tab ? Color(.systemGray5) : Color.clear)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 10)

                    // Contenido según tab
                    VStack(alignment: .leading, spacing: 8) {
                        switch selectedTab {
                        case .entrenamientos:
                            ForEach(entrenamientos, id: \.self) { nombre in
                                HStack {
                                    Image(systemName: "dumbbell.fill")
                                    Text(nombre)
                                    Spacer()
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            }

                        case .estadisticas:
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                                .frame(height: 180)
                                .overlay(Text("📊 Gráfico de estadísticas").foregroundColor(.secondary))

                        case .logros:
                            ForEach(logros) { logro in
                                HStack(spacing: 12) {
                                    Image(systemName: logro.icono)
                                        .foregroundColor(.yellow)
                                        .frame(width: 32, height: 32)
                                        .background(Color.yellow.opacity(0.2))
                                        .clipShape(Circle())

                                    VStack(alignment: .leading) {
                                        Text(logro.titulo)
                                            .font(.headline)
                                        Text(logro.descripcion)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                }
                                .padding()
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Perfil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAjustes = true
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundColor(.black)
                    }
                }
            }
            .sheet(isPresented: $showAjustes) {
                SettingsView()
            }
        }
    }
}
