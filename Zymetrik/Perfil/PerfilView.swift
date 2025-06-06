import SwiftUI

struct PerfilView: View {
    @State private var selectedTab: PerfilTab = .entrenamientos
    @State private var showAjustes = false
    @State private var showSeguidores = false
    @State private var showSiguiendo = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Título + botón de ajustes
                    HStack {
                        Text("Perfil")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Spacer()
                        Button {
                            showAjustes = true
                        } label: {
                            Image(systemName: "gearshape")
                                .font(.title2)
                                .foregroundColor(.black)
                        }
                    }
                    .padding(.horizontal)

                    // Foto, nombre y bio
                    VStack(spacing: 12) {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 84, height: 84)
                            .foregroundColor(.gray)

                        Text("Carlitos")
                            .font(.title3)
                            .fontWeight(.semibold)

                        Text("📱 Creador de @zymetrik.app\n👨🏻‍💻 Apple Developer · SwiftUI ")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        HStack{
                            NavigationLink(destination: EditarPerfilView()) {
                                Text("Editar perfil")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 8)
                                    .background(Color.black)
                                    .foregroundColor(.white)
                                    .clipShape(Capsule())
                            }
                            .padding(.top, 4)
                            NavigationLink(
                                destination: ShareProfileView(
                                    username: "carlos", // o una variable con el nombre real
                                    profileImage: Image("foto_perfil") // o una imagen cargada dinámicamente
                                )
                            ) {
                                Text("Compartir")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 8)
                                    .background(Color.black)
                                    .foregroundColor(.white)
                                    .clipShape(Capsule())
                            }
                            .padding(.top, 4)
                        }
                        

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
                        .padding(.top, 8)
                    }

                    // Pestañas
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

                    // Contenido modularizado
                    VStack(alignment: .leading, spacing: 12) {
                        if selectedTab == .entrenamientos {
                            PerfilEntrenamientosView()
                        } else if selectedTab == .estadisticas {
                            PerfilEstadisticasView()
                        } else if selectedTab == .logros {
                            PerfilLogrosView()
                        }
                    }
                }
                .padding(.top)
            }
            .sheet(isPresented: $showAjustes) {
                SettingsView()
            }
            .sheet(isPresented: $showSeguidores) {
                Text("Pantalla de seguidores")
            }
            .sheet(isPresented: $showSiguiendo) {
                Text("Pantalla de siguiendo")
            }
        }
    }
}

#Preview {
    PerfilView()
}
