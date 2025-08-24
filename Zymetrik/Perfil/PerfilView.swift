import SwiftUI
import Supabase

struct PerfilView: View {
    @StateObject private var vm = PerfilViewModel()

    @State private var selectedTab: PerfilTab = .entrenamientos
    @State private var showAjustes = false
    @State private var showEditarPerfil = false

    let esVerificado = true

    var body: some View {
        NavigationStack {
            ZStack {
                // 🔹 Fondo personalizado
                Color("Background1")
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        HStack {
                            HStack(spacing: 6) {
                                Text(vm.username)
                                    .font(.title)
                                    .fontWeight(.bold)
                                if esVerificado {
                                    Image(systemName: "checkmark.seal.fill")
                                        .foregroundColor(.verificado)
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

                        // Avatar + nombre + presentación
                        VStack(spacing: 12) {
                            if let urlString = vm.imagenPerfilURL, let url = URL(string: urlString) {
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .empty:
                                        ProgressView()
                                            .frame(width: 84, height: 84)
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .frame(width: 84, height: 84)
                                            .clipShape(Circle())
                                    case .failure:
                                        defaultAvatar
                                    @unknown default:
                                        defaultAvatar
                                    }
                                }
                            } else {
                                defaultAvatar
                            }

                            HStack(spacing: 6) {
                                Text(vm.nombre)
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                if esVerificado {
                                    Image(systemName: "checkmark.seal.fill")
                                        .foregroundColor(.verificado)
                                        .font(.system(size: 16))
                                }
                            }

                            Text(vm.presentacion)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)

                            // Botones de acción
                            HStack {
                                Button {
                                    showEditarPerfil = true
                                } label: {
                                    Text("Editar perfil")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .padding(.horizontal, 24)
                                        .padding(.vertical, 8)
                                        .background(Color.backgroundEditarPerfil)
                                        .foregroundColor(.foregroundEditarPerfil)
                                        .clipShape(Capsule())
                                }

                                NavigationLink(
                                    destination: ShareProfileView(username: vm.username, profileImage: Image(systemName: "person"))
                                ) {
                                    Text("Compartir")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .padding(.horizontal, 24)
                                        .padding(.vertical, 8)
                                        .background(Color.backgroundCompartir)
                                        .foregroundColor(.foregroundCompartir)
                                        .clipShape(Capsule())
                                }
                            }

                            // Contadores
                            HStack {
                                Spacer()
                                VStack {
                                    Text("\(vm.numeroDePosts)").font(.headline).foregroundColor(.followNumber)
                                    Text("Entrenos").font(.caption).foregroundColor(.followNumber)
                                }
                                Spacer()
                                NavigationLink(destination: ListaSeguidoresView(userID: vm.userID)) {
                                    VStack {
                                        Text("\(vm.seguidoresCount)").font(.headline).foregroundColor(.followNumber)
                                        Text("Seguidores").font(.caption).foregroundColor(.followNumber)
                                    }
                                }
                                Spacer()
                                NavigationLink(destination: ListaSeguidosView(userID: vm.userID)) {
                                    VStack {
                                        Text("\(vm.siguiendoCount)").font(.headline).foregroundColor(.followNumber)
                                        Text("Siguiendo").font(.caption).foregroundColor(.followNumber)
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

                        // Contenido por tab
                        if selectedTab == .entrenamientos {
                            PerfilEntrenamientosView(profileID: nil)
                        } else if selectedTab == .estadisticas {
                            PerfilEstadisticasView()
                        } else {
                            PerfilLogrosView()
                        }
                    }
                    .padding(.top)
                }
            }
            .sheet(isPresented: $showEditarPerfil) {
                EditarPerfilView(
                    nombre: $vm.nombre,
                    username: $vm.username,
                    presentacion: $vm.presentacion,
                    enlaces: $vm.enlaces,
                    imagenPerfilURL: $vm.imagenPerfilURL
                )
            }
            .sheet(isPresented: $showAjustes) {
                SettingsView()
            }
            .task {
                await vm.cargarDatosCompletos()
            }
        }
    }

    private var defaultAvatar: some View {
        Image(systemName: "person.circle.fill")
            .resizable()
            .frame(width: 84, height: 84)
            .clipShape(Circle())
            .foregroundColor(.gray)
    }
}
