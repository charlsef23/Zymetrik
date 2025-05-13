import SwiftUI

struct UserProfileView: View {
    let username: String
    @State private var selectedTab: PerfilTab = .entrenamientos
    @State private var isFollowing = false
    @State private var showFollowers = false
    @State private var showFollowing = false

    let entrenamientos = [
        "Entreno 1: Piernas y glúteos",
        "Entreno 2: Espalda y bíceps",
        "Entreno 3: Cardio y abdominales"
    ]

    let logros: [Logro] = [
        Logro(titulo: "Primer entrenamiento", descripcion: "Completaste tu primer día", icono: "star.fill"),
        Logro(titulo: "5 entrenos", descripcion: "Llevas 5 sesiones registradas", icono: "flame.fill"),
        Logro(titulo: "Semana completa", descripcion: "Entrenaste 7 días seguidos", icono: "calendar.circle.fill")
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Foto y nombre
                VStack(spacing: 8) {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 90, height: 90)
                        .foregroundColor(.gray)

                    Text(username)
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("📍 Entrenando cada día\n💪 Fitness · Salud · Comunidad")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top)

                // Contadores
                HStack {
                    Spacer()
                    VStack {
                        Text("24")
                            .font(.headline)
                            .foregroundColor(.black)
                        Text("Entrenos")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button {
                        showFollowers = true
                    } label: {
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
                    Button {
                        showFollowing = true
                    } label: {
                        VStack {
                            Text("321")
                                .font(.headline)
                                .foregroundColor(.black)
                            Text("Siguiendo")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                }

                // Botón seguir
                Button(action: {
                    isFollowing.toggle()
                }) {
                    Text(isFollowing ? "Siguiendo" : "Seguir")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isFollowing ? Color(.systemGray5) : Color.black)
                        .foregroundColor(isFollowing ? .black : .white)
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

                // Contenido
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
        .navigationTitle(username)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showFollowers) {
            ListaSeguidoresView()
        }
        .navigationDestination(isPresented: $showFollowing) {
            ListaSeguidosView()
        }
    }
}
