import SwiftUI

struct EntrenamientoView: View {
    @State private var fechaSeleccionada: Date = Date()
    @State private var ejerciciosPorDia: [Date: [Ejercicio]] = [:]
    @State private var mostrarLista = false

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                // Header con día y fecha completa
                HStack {
                    Text(fechaSeleccionada.formatted(.dateTime.weekday(.wide)).capitalized)
                        .font(.title.bold())

                    if Calendar.current.isDateInToday(fechaSeleccionada) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 10, height: 10)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(fechaSeleccionada.formatted(.dateTime.month(.wide).day()))
                            .font(.subheadline)
                        Text(fechaSeleccionada.formatted(.dateTime.year()))
                            .font(.subheadline)
                    }
                }
                .padding(.horizontal)

                CalendarView(
                    selectedDate: $fechaSeleccionada,
                    ejerciciosPorDia: ejerciciosPorDia
                )

                if let ejercicios = ejerciciosPorDia[fechaSeleccionada.stripTime()], !ejercicios.isEmpty {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            ForEach(ejercicios) { ejercicio in
                                EjercicioResumenView(ejercicio: ejercicio)
                            }
                        }
                        .padding(.horizontal)
                    }
                } else {
                    HStack {
                        Spacer()
                        Text("No hay ejercicios para esta fecha")
                            .foregroundColor(.secondary)
                            .padding()
                        Spacer()
                    }
                }

                Spacer()

                if let hoy = ejerciciosPorDia[Date().stripTime()], !hoy.isEmpty,
                   fechaSeleccionada.stripTime() == Date().stripTime() {
                    NavigationLink(destination: EntrenandoView(ejercicios: hoy, fecha: fechaSeleccionada)) {
                        Text("Entrenar ahora")
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .padding()
                    }
                }
            }
            .navigationBarHidden(true)
            .overlay(
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            mostrarLista = true
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 56, height: 56)
                                .background(Color.black)
                                .clipShape(Circle())
                                .shadow(radius: 4)
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 40)
                    }
                }
            )
            .sheet(isPresented: $mostrarLista) {
                ListaEjerciciosView(
                    fecha: fechaSeleccionada,
                    onGuardar: { ejercicios in
                        let fechaKey = fechaSeleccionada.stripTime()
                        ejerciciosPorDia[fechaKey] = ejercicios
                    },
                    isPresented: $mostrarLista
                )
            }
        }
    }
}

extension Date {
    func stripTime() -> Date {
        let components = Calendar.current.dateComponents([.year, .month, .day], from: self)
        return Calendar.current.date(from: components)!
    }
}
