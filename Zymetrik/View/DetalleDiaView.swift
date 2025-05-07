import SwiftUI
import SwiftData
import Charts

struct DetalleDiaView: View {
    let tipo: String
    let sesiones: [WorkoutSession]

    let hoy = Date()
    let calendar = Calendar.current

    var ejerciciosDelDia: [ExerciseEntry] {
        sesiones.filter { calendar.isDate($0.date, inSameDayAs: hoy) }.flatMap(\.exercises)
    }

    var seriesDelDia: [ExerciseSet] {
        ejerciciosDelDia.flatMap(\.sets)
    }

    var volumenDelDia: Double {
        seriesDelDia.reduce(0.0) { $0 + (Double($1.reps) * $1.weight) }
    }

    struct EjercicioVolumen: Identifiable {
        let id = UUID()
        let nombre: String
        let volumen: Double
        let color: Color
    }

    var volumenPorEjercicio: [EjercicioVolumen] {
        ejerciciosDelDia.map { ejercicio in
            let volumen = ejercicio.sets.reduce(0.0) { $0 + (Double($1.reps) * $1.weight) }
            let color = colorParaNombre(ejercicio.name)
            return EjercicioVolumen(nombre: ejercicio.name, volumen: volumen, color: color)
        }
    }

    func colorParaNombre(_ nombre: String) -> Color {
        let colores: [Color] = [.blue, .green, .purple, .orange, .pink, .teal, .indigo]
        let index = abs(nombre.hashValue) % colores.count
        return colores[index]
    }

    var body: some View {
        NavigationStack {
            List {
                if tipo == "ejercicios" {
                    if ejerciciosDelDia.isEmpty {
                        Text("No hay ejercicios registrados hoy.")
                            .foregroundColor(.gray)
                    } else {
                        ForEach(ejerciciosDelDia) { ejercicio in
                            VStack(alignment: .leading) {
                                Text(ejercicio.name)
                                    .font(.headline)
                                Text("\(ejercicio.sets.count) series")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }

                if tipo == "series" {
                    if seriesDelDia.isEmpty {
                        Text("No hay series registradas hoy.")
                            .foregroundColor(.gray)
                    } else {
                        ForEach(seriesDelDia.indices, id: \.self) { i in
                            let set = seriesDelDia[i]
                            Text("Serie \(i + 1): \(set.reps) reps x \(String(format: "%.1f", set.weight)) kg")
                        }
                    }
                }

                if tipo == "volumen" {
                    if volumenDelDia == 0 {
                        Text("No hay volumen registrado hoy.")
                            .foregroundColor(.gray)
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Volumen total de hoy:")
                                .font(.headline)

                            Text("\(String(format: "%.1f", volumenDelDia)) kg")
                                .font(.largeTitle)
                                .bold()
                                .padding(.top, 4)

                            if !volumenPorEjercicio.isEmpty {
                                Chart(volumenPorEjercicio) { item in
                                    BarMark(
                                        x: .value("Ejercicio", item.nombre),
                                        y: .value("Volumen", item.volumen)
                                    )
                                    .foregroundStyle(item.color)
                                }
                                .frame(height: 220)
                                .padding(.top, 16)
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle(tituloParaTipo(tipo))
        }
    }

    func tituloParaTipo(_ tipo: String) -> String {
        switch tipo {
        case "ejercicios": return "Ejercicios de hoy"
        case "series": return "Series de hoy"
        case "volumen": return "Volumen de hoy"
        default: return "Detalle"
        }
    }
}
