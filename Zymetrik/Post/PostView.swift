import SwiftUI

struct PostView: View {
    let post: EntrenamientoPost

    @State private var ejercicioSeleccionado: EjercicioPost
    @State private var isLiked = false
    @State private var likeCount = 24
    @State private var isSaved = false
    @State private var showComentarios = false

    let comentarios = [
        "¡Muy buen entrenamiento!",
        "¿Cuántas repes hiciste?",
        "Brutal 💪",
        "Me lo guardo!",
        "🔥🔥🔥"
    ]

    init(post: EntrenamientoPost) {
        self.post = post
        _ejercicioSeleccionado = State(initialValue: post.ejercicios.first ?? EjercicioPost(nombre: "N/A", series: 0, repeticionesTotales: 0, pesoTotal: 0))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 40)
                    .overlay(Text("👤"))
                Text(post.usuario)
                    .fontWeight(.semibold)
                Spacer()
                Text("Hace 1min")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal)

            // Estadísticas
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

            // Carrusel
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

            // Botones sociales
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

            // Comentarios
            if !comentarios.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(comentarios.prefix(3), id: \.self) { comentario in
                        Text(comentario)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }

                    if comentarios.count > 3 {
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
            ComentariosView(post: post)
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

#Preview {
    let ejercicios = [
        EjercicioPost(nombre: "Press banca", series: 4, repeticionesTotales: 40, pesoTotal: 320),
        EjercicioPost(nombre: "Aperturas", series: 3, repeticionesTotales: 30, pesoTotal: 90),
        EjercicioPost(nombre: "Fondos", series: 4, repeticionesTotales: 32, pesoTotal: 0)
    ]

    let post = EntrenamientoPost(
        usuario: "@carlos",
        fecha: Date(),
        titulo: "Pecho y tríceps",
        ejercicios: ejercicios,
        mediaURL: nil
    )

    return PostView(post: post)
}
