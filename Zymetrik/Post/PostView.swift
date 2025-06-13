import SwiftUI

struct PostView: View {
    let post: EntrenamientoPost

    @State private var ejercicioSeleccionado: EjercicioPost
    @State private var isLiked = false
    @State private var likeCount = 24
    @State private var isSaved = false
    @State private var showComentarios = false
    @State private var mostrarCompaneros = false

    let companerosEntrenamiento = ["@lucasfit", "@andreapower"]
    let comentariosMockeados: [ComentarioMock]

    init(post: EntrenamientoPost) {
        self.post = post
        _ejercicioSeleccionado = State(initialValue: post.ejercicios.first ?? EjercicioPost(nombre: "N/A", series: 0, repeticionesTotales: 0, pesoTotal: 0))

        self.comentariosMockeados = [
            "¡Muy buen entrenamiento!",
            "¿Cuántas repes hiciste?",
            "Brutal 💪",
            "Me lo guardo!",
            "🔥🔥🔥"
        ].map {
            ComentarioMock(username: "Carlos", avatarURL: nil, content: $0, createdAt: Date(), likes: Int.random(in: 1...10))
        }
    }

    var body: some View {
            VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 40)
                    .overlay(Text("👤"))
                Text(post.usuario)
                    .fontWeight(.semibold)

                if !companerosEntrenamiento.isEmpty {
                    Button(action: {
                        withAnimation {
                            mostrarCompaneros.toggle()
                        }
                    }) {
                        Text("+\(companerosEntrenamiento.count)")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.05))
                            .cornerRadius(12)
                    }
                }

                Spacer()

                Text("Hace 1min")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal)

            // Compañeros (mostrar en el post)
            if mostrarCompaneros {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(companerosEntrenamiento, id: \.self) { nombre in
                        NavigationLink(destination: UserProfileView(username: nombre)) {
                            HStack {
                                Image(systemName: "person.circle")
                                    .foregroundColor(.gray)
                                Text(nombre)
                                    .foregroundColor(.primary)
                                    .font(.subheadline)
                            }
                            .padding(.vertical, 4)
                            .padding(.leading, 8)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            // Estadísticas del ejercicio seleccionado
            VStack(spacing: 12) {
                Text(ejercicioSeleccionado.nombre)
                    .font(.title2)
                    .fontWeight(.bold)

                HStack(spacing: 24) {
                    StatItem(title: "Series", value: "\(ejercicioSeleccionado.series)")
                    StatItem(title: "Reps", value: "\(ejercicioSeleccionado.repeticionesTotales)")
                    StatItem(title: "Kg", value: String(format: "%.1f", ejercicioSeleccionado.pesoTotal))
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .frame(height: 250)
            .background(Color.black.opacity(0.05))
            .cornerRadius(16)
            .padding(.horizontal)

            // Carrusel de ejercicios
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(post.ejercicios, id: \.self) { ejercicio in
                        Button {
                            ejercicioSeleccionado = ejercicio
                        } label: {
                            VStack(spacing: 8) {
                                Image(systemName: "figure.strengthtraining.traditional")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 28, height: 28)
                                    .foregroundColor(.black)
                                Text(ejercicio.nombre)
                                    .font(.caption)
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(.black)
                            }
                            .padding()
                            .frame(width: 100, height: 90)
                            .background(ejercicio == ejercicioSeleccionado ? Color.black.opacity(0.1) : Color.white)
                            .cornerRadius(14)
                            .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)
                        }
                    }
                }
                .padding(.horizontal)
            }

                HStack(spacing: 16) {
                    Button {
                        isLiked.toggle()
                        likeCount += isLiked ? 1 : -1
                    } label: {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .foregroundColor(isLiked ? .red : .primary)
                            .font(.system(size: 20))
                    }

                    Button {
                        showComentarios = true
                    } label: {
                        Image(systemName: "bubble.right")
                            .font(.system(size: 20))
                    }

                    Spacer()

                    Button {
                        isSaved.toggle()
                    } label: {
                        Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                            .font(.system(size: 20))
                    }
                }
                .padding(.horizontal)

                // Me gusta
                if likeCount > 0 {
                    Text("\(likeCount) me gusta")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .padding(.horizontal)
                }

                // Comentarios rápidos (vistazo)
                if !comentariosMockeados.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(comentariosMockeados.prefix(3)) { comentario in
                            Text(comentario.content)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                        }

                        if comentariosMockeados.count > 3 {
                            Button("Ver todos los comentarios") {
                                showComentarios = true
                            }
                            .font(.caption)
                            .foregroundColor(.gray)
                        }
                    }
                    .padding(.horizontal)
                }

                Spacer(minLength: 4)
            }
            .padding(.vertical)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
            .padding(.horizontal)
            .sheet(isPresented: $showComentarios) {
                ComentariosSheetView(comentarios: comentariosMockeados, isPresented: $showComentarios)
            }
        }
    }

struct StatItem: View {
    var title: String
    var value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}
