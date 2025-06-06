import SwiftUI

struct EjercicioStat: Identifiable {
    let id = UUID()
    let nombre: String
    let pesoMax: Int
    let volumenTotal: Int
}

struct CardioStat: Identifiable {
    let id = UUID()
    let tipo: String
    let distanciaKm: Double
    let tiempoMin: Int
    let ritmoMedio: String
}

struct PerfilEstadisticasView: View {
    let ejercicios: [EjercicioStat] = [
        EjercicioStat(nombre: "Press banca", pesoMax: 100, volumenTotal: 5200),
        EjercicioStat(nombre: "Sentadilla", pesoMax: 140, volumenTotal: 8400),
        EjercicioStat(nombre: "Remo", pesoMax: 90, volumenTotal: 4700)
    ]

    let cardio: [CardioStat] = [
        CardioStat(tipo: "Correr", distanciaKm: 18.2, tiempoMin: 95, ritmoMedio: "5:12/km"),
        CardioStat(tipo: "Andar", distanciaKm: 10.6, tiempoMin: 130, ritmoMedio: "12:15/km")
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // Resumen general de entrenamientos
                VStack(alignment: .leading, spacing: 8) {
                    Text("Resumen de entrenamientos")
                        .font(.headline)
                        .padding(.horizontal)

                    HStack(spacing: 16) {
                        resumenCard(titulo: "Semana", valor: "5 sesiones", color: .blue)
                        resumenCard(titulo: "Mes", valor: "18 sesiones", color: .purple)
                        resumenCard(titulo: "Año", valor: "142 sesiones", color: .green)
                    }
                    .padding(.horizontal)
                }

                // Estadísticas por ejercicio
                VStack(alignment: .leading, spacing: 8) {
                    Text("Estadísticas por ejercicio")
                        .font(.headline)
                        .padding(.horizontal)

                    ForEach(ejercicios) { stat in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(stat.nombre)
                                .font(.subheadline)
                                .fontWeight(.semibold)

                            HStack {
                                Text("Peso máx: \(stat.pesoMax) kg")
                                Spacer()
                                Text("Volumen total: \(stat.volumenTotal) kg")
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                }

                // Estadísticas para corredores
                VStack(alignment: .leading, spacing: 8) {
                    Text("Estadísticas de running")
                        .font(.headline)
                        .padding(.horizontal)

                    ForEach(cardio) { run in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(run.tipo)
                                .font(.subheadline)
                                .fontWeight(.semibold)

                            HStack {
                                Text("Distancia: \(String(format: "%.1f", run.distanciaKm)) km")
                                Spacer()
                                Text("Tiempo: \(run.tiempoMin) min")
                                Spacer()
                                Text("Ritmo: \(run.ritmoMedio)")
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.top)
        }
    }

    private func resumenCard(titulo: String, valor: String, color: Color) -> some View {
        VStack {
            Text(valor)
                .font(.title3)
                .fontWeight(.bold)
            Text(titulo)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.2))
        .foregroundColor(.black)
        .cornerRadius(12)
    }
}

#Preview {
    PerfilEstadisticasView()
}
