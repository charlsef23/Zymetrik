import SwiftUI

struct EntrenamientoView: View {
    @State private var fechaSeleccionada: Date = Date()
    @State private var ejerciciosPorDia: [Date: [Ejercicio]] = [:]
    @State private var mostrarLista = false
    @State private var isMonthlyView: Bool = false  // Empieza en vista semanal

    var body: some View {
        NavigationStack {
            VStack {
                CalendarView(selectedDate: $fechaSeleccionada, isMonthlyView: $isMonthlyView)

                if let ejercicios = ejerciciosPorDia[fechaSeleccionada.stripTime()], !ejercicios.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Ejercicios del \(fechaSeleccionada.formatted(.dateTime.day().month().year()))")
                            .font(.headline)
                            .padding(.horizontal)

                        ForEach(ejercicios) { ejercicio in
                            EjercicioResumenView(ejercicio: ejercicio)
                        }
                    }
                } else {
                    Text("No hay ejercicios para esta fecha")
                        .foregroundColor(.secondary)
                        .padding()
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
