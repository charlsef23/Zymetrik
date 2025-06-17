import SwiftUI

struct EntrenamientoView: View {
    @State private var fechaSeleccionada: Date = Date()
    @State private var entrenamientos: [Entrenamiento] = []
    @State private var ejerciciosPorDia: [Date: [Ejercicio]] = [:]
    @State private var mostrarLista = false

    var body: some View {
        NavigationStack {
            VStack {
                CalendarView(selectedDate: $fechaSeleccionada)

                if let ejercicios = ejerciciosPorDia[fechaSeleccionada.stripTime()], !ejercicios.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Ejercicios del \(fechaSeleccionada.formatted(.dateTime.day().month().year()))")
                            .font(.headline)
                            .padding(.horizontal)

                        ForEach(ejercicios) { ejercicio in
                            HStack(spacing: 12) {
                                Text(ejercicio.nombre)
                                    .font(.subheadline)
                                Spacer()
                                Image(systemName: "chevron.right")
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                    }
                } else {
                    Text("No hay ejercicios para esta fecha")
                        .foregroundColor(.secondary)
                        .padding()
                }

                Spacer()

                if let hoy = ejerciciosPorDia[Date().stripTime()], !hoy.isEmpty, fechaSeleccionada.stripTime() == Date().stripTime() {
                    NavigationLink(destination: EntrenandoView(ejercicios: hoy)) {
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
            .navigationTitle("Entrenamiento")
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
                        ejerciciosPorDia[fechaSeleccionada.stripTime()] = ejercicios
                    },
                    isPresented: $mostrarLista  // <-- IMPORTANTE
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
