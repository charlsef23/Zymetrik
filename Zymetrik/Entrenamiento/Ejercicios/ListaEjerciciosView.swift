import SwiftUI

struct ListaEjerciciosView: View {
    var modoSeleccion: Bool = false
    @Binding var ejerciciosSeleccionadosBinding: [Ejercicio]
    var onFinalizarSeleccion: (() -> Void)? = nil

    @State private var tipoSeleccionado: TipoEjercicio = .gimnasio
    @State private var textoBusqueda: String = ""
    @State private var listaEjercicios: [Ejercicio] = [
        Ejercicio(nombre: "Ejercicio 1", descripcion: "Ejercicio para pierna", categoria: "Pierna", tipo: .gimnasio),
        Ejercicio(nombre: "Ejercicio 2", descripcion: "Ejercicio de fuerza", categoria: "Pierna", tipo: .funcional),
        Ejercicio(nombre: "Espalda Alta", descripcion: "Espalda y dorsal", categoria: "Espalda", tipo: .gimnasio),
        Ejercicio(nombre: "Correr", descripcion: "Cardio al aire libre", categoria: "Cardio", tipo: .cardio)
    ]

    func colorTarjeta(_ tipo: TipoEjercicio) -> Color {
        switch tipo {
        case .gimnasio: return Color(red: 240/255, green: 248/255, blue: 255/255)
        case .cardio: return Color(red: 255/255, green: 245/255, blue: 235/255)
        case .funcional: return Color(red: 245/255, green: 255/255, blue: 245/255)
        }
    }

    var ejerciciosFiltrados: [String: [Ejercicio]] {
        let filtrados = listaEjercicios.filter {
            $0.tipo == tipoSeleccionado &&
            (textoBusqueda.isEmpty || $0.nombre.localizedCaseInsensitiveContains(textoBusqueda))
        }
        return Dictionary(grouping: filtrados) { $0.categoria }
    }

    var favoritos: [Ejercicio] {
        listaEjercicios.filter { $0.tipo == tipoSeleccionado && $0.esFavorito }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Búsqueda
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

                    // Selector horizontal
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(TipoEjercicio.allCases, id: \.self) { tipo in
                                Button {
                                    withAnimation { tipoSeleccionado = tipo }
                                } label: {
                                    Text(tipo.rawValue.capitalized)
                                        .font(.subheadline)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(tipoSeleccionado == tipo ? Color.black : Color(.systemGray5))
                                        .foregroundColor(tipoSeleccionado == tipo ? .white : .primary)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Favoritos
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

                    // Lista agrupada
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

                    if modoSeleccion {
                        Button("Finalizar selección") {
                            onFinalizarSeleccion?()
                        }
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.black)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .padding(.horizontal)
                        .padding(.bottom, 40)
                    }
                }
                .padding(.top, 12)
            }
            .background(Color.white)
            .navigationTitle("Ejercicios")
        }
    }

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

            VStack(spacing: 6) {
                // Favorito
                Button {
                    if let index = listaEjercicios.firstIndex(where: { $0.id == ejercicio.id }) {
                        listaEjercicios[index].esFavorito.toggle()
                    }
                } label: {
                    Image(systemName: ejercicio.esFavorito ? "star.fill" : "star")
                        .foregroundColor(ejercicio.esFavorito ? .yellow : .black)
                        .padding(8)
                }

                // Seleccionar si está en modo selección
                if modoSeleccion {
                    Button {
                        if ejerciciosSeleccionadosBinding.contains(where: { $0.id == ejercicio.id }) {
                            ejerciciosSeleccionadosBinding.removeAll { $0.id == ejercicio.id }
                        } else {
                            ejerciciosSeleccionadosBinding.append(ejercicio)
                        }
                    } label: {
                        Image(systemName: ejerciciosSeleccionadosBinding.contains(where: { $0.id == ejercicio.id }) ? "checkmark.circle.fill" : "plus.circle")
                            .font(.system(size: 20))
                            .foregroundColor(ejerciciosSeleccionadosBinding.contains(where: { $0.id == ejercicio.id }) ? .green : .black)
                    }
                }
            }
            .padding([.top, .trailing], 10)
        }
        .padding(.horizontal)
    }
}
