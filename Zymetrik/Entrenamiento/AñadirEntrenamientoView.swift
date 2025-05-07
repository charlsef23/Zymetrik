import SwiftUI
import SwiftData

struct AñadirEntrenamientoView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @Query private var sesiones: [WorkoutSession]
    @Query private var favoritos: [FavoriteWorkoutTitle]

    var fecha: Date
    @State private var titulo: String = ""
    @State private var mostrarError = false
    @State private var mostrarAlertaDuplicado = false
    @State private var favoritoAEliminar: FavoriteWorkoutTitle?
    @State private var mostrarAlertaEliminar = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {

                if !favoritos.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(favoritos.sorted(by: { $0.createdAt > $1.createdAt })) { fav in
                                HStack(spacing: 4) {
                                    Button {
                                        titulo = fav.title
                                    } label: {
                                        Text(fav.title)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Color.blue.opacity(0.1))
                                            .foregroundColor(.blue)
                                            .cornerRadius(20)
                                    }

                                    Button {
                                        favoritoAEliminar = fav
                                        mostrarAlertaEliminar = true
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Fecha del entrenamiento")
                        .font(.headline)
                    HStack {
                        Image(systemName: "calendar")
                        Text(formatearFecha(fecha))
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Título")
                            .font(.headline)
                        Spacer()
                        if !titulo.isEmpty {
                            Button {
                                guardarFavorito()
                            } label: {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.orange)
                            }
                        }
                    }

                    TextField("Ej: Piernas y abdominales", text: $titulo)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)

                    if !titulo.isEmpty {
                        ForEach(sugerenciasFiltradas(), id: \.self) { sugerencia in
                            Button {
                                titulo = sugerencia
                            } label: {
                                HStack {
                                    Image(systemName: "clock.arrow.circlepath")
                                        .foregroundColor(.gray)
                                    Text(sugerencia)
                                        .foregroundColor(.blue)
                                    Spacer()
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }

                if mostrarError {
                    Text("Por favor introduce un título.")
                        .foregroundColor(.red)
                        .font(.caption)
                }

                Spacer()

                Button(action: comprobarDuplicado) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Guardar entrenamiento")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .shadow(radius: 4)
                }
            }
            .padding()
            .navigationTitle("Nuevo entrenamiento")
            .alert("¿Eliminar favorito?", isPresented: $mostrarAlertaEliminar, actions: {
                Button("Eliminar", role: .destructive) {
                    if let favorito = favoritoAEliminar {
                        context.delete(favorito)
                        try? context.save()
                    }
                }
                Button("Cancelar", role: .cancel) { }
            }, message: {
                Text("¿Seguro que quieres eliminar este nombre favorito?")
            })
            .alert("Ya hay un entrenamiento ese día", isPresented: $mostrarAlertaDuplicado, actions: {
                Button("Guardar de todos modos", role: .destructive) {
                    guardar(forzado: true)
                }
                Button("Cancelar", role: .cancel) { }
            }, message: {
                Text("¿Quieres añadir otro entrenamiento en la misma fecha?")
            })
        }
    }

    func comprobarDuplicado() {
        let tituloLimpio = titulo.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !tituloLimpio.isEmpty else {
            mostrarError = true
            return
        }

        let yaExiste = sesiones.contains { Calendar.current.isDate($0.date, inSameDayAs: fecha) }
        if yaExiste {
            mostrarAlertaDuplicado = true
        } else {
            guardar(forzado: false)
        }
    }

    func guardar(forzado: Bool) {
        let nuevo = WorkoutSession(date: fecha, title: titulo.trimmingCharacters(in: .whitespacesAndNewlines))
        context.insert(nuevo)
        try? context.save()
        dismiss()
    }

    func guardarFavorito() {
        guard !favoritos.contains(where: { $0.title.lowercased() == titulo.lowercased() }) else { return }
        let nuevo = FavoriteWorkoutTitle(title: titulo)
        context.insert(nuevo)
        try? context.save()
    }

    func formatearFecha(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.locale = Locale(identifier: "es_ES")
        return formatter.string(from: date)
    }

    func sugerenciasFiltradas() -> [String] {
        let todos = Set(sesiones.map { $0.title }).sorted()
        return todos.filter {
            $0.lowercased().contains(titulo.lowercased()) && $0 != titulo
        }
    }
}
