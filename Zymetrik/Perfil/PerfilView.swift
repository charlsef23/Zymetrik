import SwiftUI

struct PerfilView: View {
    @State private var selectedTab: PerfilTab = .entrenamientos
    @State private var showAjustes = false
    @State private var showEditarPerfil = false

    @State private var nombre = "Carlitos"
    @State private var username = "carlosesteve23"
    @State private var presentacion = "👨🏻‍💻 Apple Developer · SwiftUI "
    @State private var enlaces = ""
    @State private var imagenPerfil: Image? = Image(systemName: "person.circle.fill")

    let esVerificado = true

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Título y engranaje
                    HStack {
                        HStack(spacing: 6) {
                            Text(username)
                                .font(.title)
                                .fontWeight(.bold)

                            if esVerificado {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundColor(.blue)
                                    .font(.system(size: 20))
                            }
                        }

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

                    // Avatar + datos
                    VStack(spacing: 12) {
                        imagenPerfil?
                            .resizable()
                            .frame(width: 84, height: 84)
                            .clipShape(Circle())
                            .foregroundColor(.gray)

                        HStack(spacing: 6) {
                            Text(nombre)
                                .font(.title3)
                                .fontWeight(.semibold)

                            if esVerificado {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundColor(.blue)
                                    .font(.system(size: 16))
                            }
                        }

                        Text(presentacion)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)

                        HStack {
                            Button {
                                showEditarPerfil = true
                            } label: {
                                Text("Editar perfil")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 8)
                                    .background(Color.black)
                                    .foregroundColor(.white)
                                    .clipShape(Capsule())
                            }

                            NavigationLink(
                                destination: ShareProfileView(username: username, profileImage: imagenPerfil ?? Image(systemName: "person"))
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
                        }

                        // Estadísticas
                        HStack {
                            Spacer()
                            VStack {
                                Text("12").font(.headline)
                                Text("Entrenos").font(.caption).foregroundColor(.secondary)
                            }
                            Spacer()
                            NavigationLink(destination: ListaSeguidoresView()) {
                                VStack {
                                    Text("910").font(.headline)
                                    Text("Seguidores").font(.caption).foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                            NavigationLink(destination: ListaSeguidosView()) {
                                VStack {
                                    Text("562").font(.headline)
                                    Text("Siguiendo").font(.caption).foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                        }
                    }

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
                                        Capsule().fill(selectedTab == tab ? Color(.systemGray5) : Color.clear)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    // Contenido del tab
                    if selectedTab == .entrenamientos {
                        PerfilEntrenamientosView()
                    } else if selectedTab == .estadisticas {
                        PerfilEstadisticasView()
                    } else {
                        PerfilLogrosView()
                    }
                }
                .padding(.top)
            }
            .sheet(isPresented: $showEditarPerfil) {
                EditarPerfilView(
                    nombre: $nombre,
                    username: $username,
                    presentacion: $presentacion,
                    enlaces: $enlaces,
                    imagenPerfil: $imagenPerfil
                )
            }
            .sheet(isPresented: $showAjustes) {
                SettingsView()
            }
        }
    }
}
