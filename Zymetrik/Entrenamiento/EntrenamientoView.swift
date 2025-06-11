import SwiftUI

struct EntrenamientoView: View {
    @State private var selectedDate: Date = Date()
    @State private var entrenamientos: [Entrenamiento] = []
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
                            fechasConEntrenamiento: Set(entrenamientos.map { $0.fecha })
                        )

                        // Ejercicios del día
                        if let entrenamiento = entrenamientos.first(where: { Calendar.current.isDate($0.fecha, inSameDayAs: selectedDate) }) {
                            ForEach(entrenamiento.ejercicios) { ejercicio in
                                TarjetaEjercicioView(ejercicio: ejercicio)
                            }
                        } else {
                            Text("No tienes entrenamientos para este día.")
                                .foregroundColor(.gray)
                                .font(.subheadline)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.top, 60)
                        }
                    }
                    .padding(.top)
                }

                // Botón flotante
                FloatingAddButton {
                    mostrarListaEjercicios = true
                }
            }
            .sheet(isPresented: $mostrarListaEjercicios) {
                SelectorEjerciciosEntrenamiento { seleccionados in
                    if let index = entrenamientos.firstIndex(where: { Calendar.current.isDate($0.fecha, inSameDayAs: selectedDate) }) {
                        entrenamientos[index].ejercicios.append(contentsOf: seleccionados)
                    } else {
                        let nuevo = Entrenamiento(fecha: selectedDate, ejercicios: seleccionados)
                        entrenamientos.append(nuevo)
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)
        }
    }
}

// Vista de tarjeta visual igual a la de la lista de ejercicios
struct TarjetaEjercicioView: View {
    var ejercicio: Ejercicio

    func colorTarjeta(_ tipo: TipoEjercicio) -> Color {
        switch tipo {
        case .gimnasio: return Color(red: 240/255, green: 248/255, blue: 255/255)
        case .cardio: return Color(red: 255/255, green: 245/255, blue: 235/255)
        case .funcional: return Color(red: 245/255, green: 255/255, blue: 245/255)
        }
    }

    var body: some View {
        HStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: "figure.strengthtraining.traditional")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundColor(.gray)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(ejercicio.nombre)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(ejercicio.descripcion)
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorTarjeta(ejercicio.tipo))
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
        .padding(.horizontal)
    }
}

struct SelectorEjerciciosEntrenamiento: View {
    var onEjerciciosSeleccionados: ([Ejercicio]) -> Void
    @Environment(\.dismiss) var dismiss
    @State private var seleccionados: [Ejercicio] = []

    var body: some View {
        ListaEjerciciosView(
            modoSeleccion: true,
            ejerciciosSeleccionadosBinding: $seleccionados,
            onFinalizarSeleccion: {
                onEjerciciosSeleccionados(seleccionados)
                dismiss()
            }
        )
    }
}
