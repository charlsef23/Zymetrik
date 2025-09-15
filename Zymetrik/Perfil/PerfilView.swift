// MARK: - PerfilView.swift
import SwiftUI

struct PerfilView: View {
    @StateObject private var vm = PerfilViewModel()
    @State private var showEditarPerfil = false
    @State private var selectedTab: PerfilTab = .entrenamientos
    @State private var showAjustes = false
    
    let esVerificado = true
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    headerBar
                        .padding(.horizontal)
                    
                    profileInfoSection
                        .padding(.horizontal)
                    
                    tabsBar
                        .padding(.horizontal)
                    
                    // Contenido de pestañas — full-bleed (sin padding horizontal)
                    tabContent
                        .padding(.vertical, 4)
                }
                .padding(.bottom, 16)
            }
            .background(Color(.systemBackground).ignoresSafeArea())
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
}

// MARK: - Subvistas

private extension PerfilView {
    // Header superior: username + verificado + ajustes
    var headerBar: some View {
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
                    .foregroundColor(.primary)
            }
            .buttonStyle(.plain)
        }
    }
    
    // Avatar + nombre + presentación + acciones + contadores
    var profileInfoSection: some View {
        VStack(spacing: 12) {
            // Avatar mejorado con todas las funcionalidades
            AvatarAsyncImage.profile(url: vm.imagenPerfilURL)
                .avatarStyle(isOnline: true, showActivity: true)
            
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
            
            if !vm.presentacion.isEmpty {
                Text(vm.presentacion)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
            
            if !vm.enlaces.isEmpty {
                if let url = URL(string: vm.enlaces.trimmingCharacters(in: .whitespacesAndNewlines)) {
                    Link(destination: url) {
                        Text(vm.enlaces)
                            .font(.subheadline)
                            .foregroundColor(.blue)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .underline()
                    }
                } else {
                    Text(vm.enlaces)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }
            }
            
            actionButtons
            
            countersRow
        }
    }
    
    // Botones: Editar perfil + Compartir
    var actionButtons: some View {
        HStack {
            Button {
                showEditarPerfil = true
                HapticManager.shared.lightImpact()
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
            .buttonStyle(.plain)
            
            NavigationLink {
                ShareProfileProView(username: vm.username, profileImageURL: vm.imagenPerfilURL)
            } label: {
                Text("Compartir")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 8)
                    .background(Color.backgroundCompartir)
                    .foregroundColor(.foregroundCompartir)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
    }
    
    // Contadores: Entrenos / Seguidores / Siguiendo
    var countersRow: some View {
        HStack {
            Spacer()
            VStack {
                Text("\(vm.numeroDePosts)")
                    .font(.headline)
                    .foregroundColor(.followNumber)
                Text("Entrenos")
                    .font(.caption)
                    .foregroundColor(.followNumber)
            }
            Spacer()
            NavigationLink {
                ListaSeguidoresView(userID: vm.userID)
            } label: {
                VStack {
                    Text("\(vm.seguidoresCount)")
                        .font(.headline)
                        .foregroundColor(.followNumber)
                    Text("Seguidores")
                        .font(.caption)
                        .foregroundColor(.followNumber)
                }
            }
            .buttonStyle(.plain)
            Spacer()
            NavigationLink {
                ListaSeguidosView(userID: vm.userID)
            } label: {
                VStack {
                    Text("\(vm.siguiendoCount)")
                        .font(.headline)
                        .foregroundColor(.followNumber)
                    Text("Siguiendo")
                        .font(.caption)
                        .foregroundColor(.followNumber)
                }
            }
            .buttonStyle(.plain)
            Spacer()
        }
    }
    
    // Tabs
    var tabsBar: some View {
        HStack {
            ForEach(PerfilTab.allCases, id: \.self) { tab in
                Button {
                    selectedTab = tab
                    HapticManager.shared.selection()
                } label: {
                    Text(tab.rawValue)
                        .fontWeight(selectedTab == tab ? .bold : .regular)
                        .foregroundColor(selectedTab == tab ? .primary : .gray)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 16)
                        .background(
                            Capsule().fill(selectedTab == tab ? Color(.systemGray5) : Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // Contenido por tab (borderless)
    @ViewBuilder
    var tabContent: some View {
        switch selectedTab {
        case .entrenamientos:
            PerfilEntrenamientosView(profileID: nil)
        case .estadisticas:
            PerfilEstadisticasView(perfilId: nil)
        case .logros:
            PerfilLogrosView(perfilId: nil)
        }
    }
}
