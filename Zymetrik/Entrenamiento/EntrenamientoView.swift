import SwiftUI

struct EntrenamientoView: View {
    @State private var selectedDate: Date = Date()
    @State private var fechasConEntrenamiento: Set<Date> = []
    @State private var mostrarListaEjercicios = false

    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Toca Entrenar")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .padding(.horizontal)

                        // Calendario
                        CalendarioSelectorView(
                            selectedDate: $selectedDate,
                            fechasConEntrenamiento: fechasConEntrenamiento
                        )

                        // Estado del día
                        Text("No tienes entrenamientos para este día.")
                            .foregroundColor(.gray)
                            .font(.subheadline)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 60)
                    }
                    .padding(.top)
                }

                // Botón flotante
                FloatingAddButton {
                    mostrarListaEjercicios = true
                }
            }
            .sheet(isPresented: $mostrarListaEjercicios) {
                ListaEjerciciosView() // ← Aquí puedes enlazar con tu vista real
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)
        }
    }
}
