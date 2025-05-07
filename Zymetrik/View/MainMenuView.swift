import SwiftUI
import SwiftData

struct MainMenuView: View {
    @Binding var selectedTab: String
    @Binding var fechaSeleccionada: Date
    @AppStorage("userName") var userName: String = ""
    @Query private var sesiones: [WorkoutSession]

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("¡Hola, \(userName)!")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.top)

                if let sesionHoy = entrenamientoDeHoy() {
                    Button {
                        fechaSeleccionada = Date()
                        selectedTab = "calendario"
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Entrenamiento de hoy")
                                .font(.caption)
                                .foregroundColor(.gray)

                            Text(sesionHoy.title)
                                .font(.headline)
                                .foregroundColor(.blue)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                } else {
                    Text("Hoy no tienes ningún entrenamiento")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                }

                Button {
                    selectedTab = "calendario"
                } label: {
                    HStack {
                        Image(systemName: "calendar")
                        Text("Ver calendario de entrenamientos")
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Inicio")
        }
    }

    private func entrenamientoDeHoy() -> WorkoutSession? {
        let hoy = Calendar.current.startOfDay(for: Date())
        return sesiones.first {
            Calendar.current.isDate($0.date, inSameDayAs: hoy)
        }
    }
}
