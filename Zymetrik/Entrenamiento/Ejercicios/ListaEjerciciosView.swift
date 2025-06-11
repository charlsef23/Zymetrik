import SwiftUI

struct ListaEjerciciosView: View {
    @State private var ejerciciosSeleccionados: [UUID] = []
    @State private var tipoSeleccionado: TipoEjercicio = .gimnasio
    @State private var textoBusqueda: String = ""
    @State private var listaEjercicios: [Ejercicio] = [
        Ejercicio(nombre: "Ejercicio 1", descripcion: "Ejercicio para pierna", categoria: "Pierna", tipo: .gimnasio),
        Ejercicio(nombre: "Ejercicio 2", descripcion: "Ejercicio de fuerza", categoria: "Pierna", tipo: .funcional),
        Ejercicio(nombre: "Espalda Alta", descripcion: "Ejercicio para espalda", categoria: "Espalda", tipo: .gimnasio),
        Ejercicio(nombre: "Correr", descripcion: "Cardio al aire libre", categoria: "Cardio", tipo: .cardio)
    ]

    // Colores según tipo
    func colorTarjeta(_ tipo: TipoEjercicio) -> Color {
        switch tipo {
        case .gimnasio: return Color(red: 240/255, green: 248/255, blue: 255/255)
        case .cardio: return Color(red: 255/255, green: 245/255, blue: 235/255)
        case .funcional: return Color(red: 245/255, green: 255/255, blue: 245/255)
        }
    }

    // Ejercicios filtrados por tipo y búsqueda
    var ejerciciosFiltrados: [String: [Ejercicio]] {
        let filtrados = listaEjercicios.filter {
            $0.tipo == tipoSeleccionado &&
            (textoBusqueda.isEmpty || $0.nombre.localizedCaseInsensitiveContains(textoBusqueda))
        }

        return Dictionary(grouping: filtrados) { $0.categoria }
    }

    // Favoritos dentro del tipo seleccionado
    var favoritos: [Ejercicio] {
        listaEjercicios.filter { $0.tipo == tipoSeleccionado && $0.esFavorito }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {

                    // Barra de búsqueda
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Buscar ejercicio", text: $textoBusqueda)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                        if !textoBusqueda.isEmpty {
                            Button(action: { textoBusqueda = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)

                    // Selector de tipo
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(TipoEjercicio.allCases, id: \.self) { tipo in
                                Button(action: {
                                    withAnimation { tipoSeleccionado = tipo }
                                }) {
                                    Text(tipo.rawValue.capitalized)
                                        .font(.subheadline)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(
                                            tipoSeleccionado == tipo ? Color.black : Color(.systemGray5)
                                        )
                                        .foregroundColor(tipoSeleccionado == tipo ? .white : .primary)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    // FAVORITOS
                    if !favoritos.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("FAVORITOS")
                                .font(.footnote)
                                .fontWeight(.semibold)
                                .foregroundColor(.orange)
                                .padding(.horizontal)

                            ForEach(favoritos) { ejercicio in
                                tarjetaEjercicio(ejercicio)
                            }
                        }
                    }

                    // Agrupados por categoría
                    ForEach(ejerciciosFiltrados.keys.sorted(), id: \.self) { categoria in
                        VStack(alignment: .leading, spacing: 12) {
                            Text(categoria.uppercased())
                                .font(.footnote)
                                .fontWeight(.medium)
                                .foregroundColor(.gray)
                                .padding(.horizontal)

                            ForEach(ejerciciosFiltrados[categoria] ?? []) { ejercicio in
                                tarjetaEjercicio(ejercicio)
                            }
                        }
                    }

                    Spacer(minLength: 60)
                }
                .padding(.top, 12)
            }
            .background(Color.white)
            .navigationTitle("Ejercicios")
        }
    }

    // Vista individual de tarjeta de ejercicio
    @ViewBuilder
    func tarjetaEjercicio(_ ejercicio: Ejercicio) -> some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 12) {
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
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(colorTarjeta(ejercicio.tipo))
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
            )

            // Favorito + Añadir al post en una misma columna
            VStack(spacing: 6) {
                Button(action: {
                    if let index = listaEjercicios.firstIndex(where: { $0.id == ejercicio.id }) {
                        listaEjercicios[index].esFavorito.toggle()
                    }
                }) {
                    Image(systemName: ejercicio.esFavorito ? "star.fill" : "star")
                        .foregroundColor(ejercicio.esFavorito ? .yellow : .black)
                        .padding(8)
                }

                Button(action: {
                    if ejerciciosSeleccionados.contains(ejercicio.id) {
                        ejerciciosSeleccionados.removeAll { $0 == ejercicio.id }
                    } else {
                        ejerciciosSeleccionados.append(ejercicio.id)
                    }
                }) {
                    Image(systemName: ejerciciosSeleccionados.contains(ejercicio.id) ? "checkmark.circle.fill" : "plus.circle")
                        .font(.system(size: 20))
                        .foregroundColor(ejerciciosSeleccionados.contains(ejercicio.id) ? .green : .black)
                }
            }
            .padding([.top, .trailing], 10)
        }
        .padding(.horizontal)
    }
}

#Preview {
    ListaEjerciciosView()
}
