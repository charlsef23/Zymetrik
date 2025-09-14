import SwiftUI

struct LogrosView: View {
    @StateObject private var viewModel = LogrosViewModel()
    @State private var showingSearch = false
    @State private var selectedCategory: LogroCategory = .all
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                if viewModel.isLoading {
                    loadingView
                } else {
                    contentView
                }
            }
            .navigationTitle("Logros")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    searchButton
                    filterButton
                }
            }
            .refreshable {
                await viewModel.refreshLogros()
            }
            .searchable(text: $viewModel.searchText, isPresented: $showingSearch)
            .overlay(
                newAchievementPopup
            )
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") { }
            } message: {
                Text(viewModel.errorMessage ?? "Error desconocido")
            }
        }
    }
    
    // MARK: - Vistas principales
    
    private var contentView: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                progressSection
                
                if !viewModel.filteredLogros.isEmpty {
                    achievementsGrid
                } else {
                    emptyStateView
                }
            }
            .padding()
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Cargando logros...")
                .foregroundColor(.secondary)
                .font(.headline)
        }
    }
    
    // MARK: - Sección de progreso
    
    private var progressSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Tu progreso")
                        .font(.title2.bold())
                        .foregroundColor(.primary)
                    
                    if viewModel.canShowProgress {
                        Text("\(viewModel.progressText) completados")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if viewModel.canShowProgress {
                    VStack(spacing: 4) {
                        Text(viewModel.progressPercentageText)
                            .font(.title.bold())
                            .foregroundColor(.accentColor)
                        
                        Text("completado")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            if viewModel.canShowProgress {
                progressBar
            }
            
            statsCards
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    private var progressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(.systemGray5))
                    .frame(height: 12)
                
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        LinearGradient(
                            colors: [.accentColor, .accentColor.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * viewModel.porcentajeCompletado, height: 12)
                    .animation(.spring(response: 0.8, dampingFraction: 0.8), value: viewModel.porcentajeCompletado)
            }
        }
        .frame(height: 12)
    }
    
    private var statsCards: some View {
        HStack(spacing: 12) {
            StatCard(
                title: "Total",
                value: "\(viewModel.totalLogros)",
                icon: "rosette",
                color: .blue
            )
            
            StatCard(
                title: "Completados",
                value: "\(viewModel.logrosDesbloqueados)",
                icon: "checkmark.seal.fill",
                color: .green
            )
            
            StatCard(
                title: "Pendientes",
                value: "\(viewModel.totalLogros - viewModel.logrosDesbloqueados)",
                icon: "clock",
                color: .orange
            )
        }
    }
    
    // MARK: - Grid de logros
    
    private var achievementsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ], spacing: 16) {
            ForEach(viewModel.filteredLogros) { logro in
                LogroCardModernView(logro: logro)
                    .onTapGesture {
                        // Aquí podrías agregar más detalles del logro
                    }
            }
        }
    }
    
    // MARK: - Estados vacíos
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: viewModel.searchText.isEmpty ? "rosette" : "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text(viewModel.searchText.isEmpty ? "No hay logros disponibles" : "No se encontraron logros")
                .font(.title2.bold())
                .foregroundColor(.primary)
            
            Text(viewModel.searchText.isEmpty ?
                 "Los logros aparecerán aquí cuando estén disponibles." :
                 "Intenta con otros términos de búsqueda.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            if !viewModel.searchText.isEmpty {
                Button("Limpiar búsqueda") {
                    viewModel.clearSearch()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(40)
    }
    
    // MARK: - Botones de toolbar
    
    private var searchButton: some View {
        Button(action: {
            showingSearch.toggle()
        }) {
            Image(systemName: "magnifyingglass")
        }
    }
    
    private var filterButton: some View {
        Button(action: viewModel.toggleFilter) {
            Image(systemName: viewModel.showOnlyUnlocked ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                .foregroundColor(viewModel.showOnlyUnlocked ? .accentColor : .primary)
        }
    }
    
    // MARK: - Popup de nuevos logros
    
    @ViewBuilder
    private var newAchievementPopup: some View {
        if viewModel.showNewAchievementPopup && !viewModel.newlyUnlockedAchievements.isEmpty {
            LogroDesbloqueadoMejoradoView(
                logro: viewModel.newlyUnlockedAchievements[viewModel.currentAchievementIndex],
                isLastAchievement: viewModel.currentAchievementIndex == viewModel.newlyUnlockedAchievements.count - 1,
                achievementNumber: viewModel.currentAchievementIndex + 1,
                totalAchievements: viewModel.newlyUnlockedAchievements.count
            ) {
                viewModel.showNextAchievement()
            }
            .transition(.asymmetric(
                insertion: .scale.combined(with: .opacity),
                removal: .opacity
            ))
            .zIndex(1000)
        }
    }
}

// MARK: - Vista de tarjeta estadística

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3.bold())
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Enum para categorías (para futuro uso)


// MARK: - Preview

#Preview {
    LogrosView()
}
