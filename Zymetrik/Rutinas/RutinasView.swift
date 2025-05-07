import SwiftUI
import SwiftData

struct RutinasView: View {
    @Environment(\.modelContext) private var context
    @Query private var rutinas: [Routine]

    @State private var mostrarFormulario = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                VStack {
                    if rutinas.isEmpty {
                        ContentUnavailableView {
                            Label("Sin rutinas", systemImage: "list.bullet.rectangle")
                        } description: {
                            Text("Crea plantillas de entrenamiento para reutilizarlas fácilmente.")
                        }
                    } else {
                        List {
                            ForEach(rutinas) { rutina in
                                NavigationLink(destination: DetalleRutinaView(rutina: rutina)) {
                                    VStack(alignment: .leading) {
                                        Text(rutina.name)
                                            .font(.headline)
                                        Text("\(rutina.exercises.count) ejercicios")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                            .onDelete(perform: eliminarRutina)
                        }
                        .listStyle(.insetGrouped)
                    }
                }
                .navigationTitle("Rutinas")

                // BOTÓN FLOTANTE
                Button {
                    mostrarFormulario = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .clipShape(Circle())
                        .shadow(radius: 5)
                }
                .padding()
            }
            .sheet(isPresented: $mostrarFormulario) {
                FormularioRutinaView()
            }
        }
    }

    func eliminarRutina(at offsets: IndexSet) {
        for index in offsets {
            let rutina = rutinas[index]
            context.delete(rutina)
        }
        try? context.save()
    }
}
