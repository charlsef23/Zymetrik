import SwiftUI

struct InicioView: View {
    @State private var posts: [Post] = []
    @State private var seleccion = "Para ti"
    @State private var cargando = true

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Inicio")
                        .font(.largeTitle.bold())
                    Spacer()
                    HStack(spacing: 20) {
                        NavigationLink(destination: AlertasView()) {
                            Image(systemName: "bell.fill")
                        }
                        NavigationLink(destination: DMInboxView()) {
                            Image(systemName: "paperplane.fill")
                        }
                    }
                    .font(.title2)
                }
                .padding(.horizontal)
                .padding(.top, 20)

                // Selector "Para ti" / "Siguiendo"
                HStack {
                    ForEach(["Para ti", "Siguiendo"], id: \.self) { opcion in
                        VStack {
                            Text(opcion)
                                .foregroundColor(seleccion == opcion ? .black : .gray)
                                .fontWeight(seleccion == opcion ? .semibold : .regular)
                            if seleccion == opcion {
                                Capsule()
                                    .fill(Color.black)
                                    .frame(height: 3)
                            } else {
                                Color.clear.frame(height: 3)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .onTapGesture {
                            seleccion = opcion
                            cargarPosts()
                        }
                    }
                }
                .padding(.top, 16)
                .padding(.horizontal)

                // Lista de posts
                if cargando {
                    ProgressView().padding()
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            ForEach(posts) { post in
                                PostView(post: post)
                            }
                        }
                        .padding(.top)
                    }
                }

                Spacer()
            }
            .onAppear {
                cargarPosts()
            }
        }
    }

    func cargarPosts() {
        Task {
            do {
                cargando = true
                posts = try await SupabaseService.shared.fetchPosts()
                cargando = false
            } catch {
                print("Error al cargar feed: \(error)")
                cargando = false
            }
        }
    }
}
