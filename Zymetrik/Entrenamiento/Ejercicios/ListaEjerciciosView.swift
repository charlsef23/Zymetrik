import SwiftUI

struct ListaEjerciciosView: View {
    @State private var tipoSeleccionado: TipoEjercicio = .gimnasio

    let ejercicios: [Ejercicio] = [
        Ejercicio(nombre: "Ejercicio 1", descripcion: "Descripción", categoria: "Pierna", tipo: .gimnasio),
        Ejercicio(nombre: "Ejercicio 2", descripcion: "Descripción", categoria: "Pierna", tipo: .gimnasio),
        Ejercicio(nombre: "Ejercicio 3", descripcion: "Descripción", categoria: "Espalda", tipo: .gimnasio),
        Ejercicio(nombre: "Correr", descripcion: "Cardio al aire libre", categoria: "Exterior", tipo: .cardio)
    ]

    var ejerciciosFiltrados: [String: [Ejercicio]] {
        Dictionary(grouping: ejercicios.filter { $0.tipo == tipoSeleccionado }) { $0.categoria }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Selector de tipo
                    HStack(spacing: 12) {
                        ForEach(TipoEjercicio.allCases, id: \.self) { tipo in
                            Button(action: {
                                tipoSeleccionado = tipo
                            }) {
                                Text(tipo.rawValue)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        Capsule().fill(tipoSeleccionado == tipo ? Color(.systemGray4) : Color(.systemGray6))
                                    )
                            }
                            .foregroundColor(.primary)
                        }
                    }
                    .padding(.top, 8)
                    .padding(.horizontal)

                    // Lista por categorías
                    ForEach(ejerciciosFiltrados.keys.sorted(), id: \.self) { categoria in
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Categoría \(categoria)")
                                .font(.headline)
                                .padding(.horizontal)

                            ForEach(ejerciciosFiltrados[categoria] ?? []) { ejercicio in
                                HStack(spacing: 12) {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(.systemGray5))
                                        .frame(width: 56, height: 56)
                                        .overlay(
                                            Text("IMG")
                                                .font(.caption)
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
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color(.systemGray4), lineWidth: 1)
                                )
                                .padding(.horizontal)
                            }
                        }
                    }

                    Spacer(minLength: 40)
                }
            }
            .navigationTitle("Ejercicios")
        }
    }
}
