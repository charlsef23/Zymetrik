import SwiftUI

struct EntrenandoView: View {
    let ejercicios: [Ejercicio]
    @State private var setsPorEjercicio: [UUID: [SetRegistro]] = [:]
    @State private var tiempo: Int = 0
    @State private var timerActivo = false
    @State private var temporizador: Timer?
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.calendar) var calendar

    // Formatters
    let intFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        return formatter
    }()

    let decimalFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        return formatter
    }()

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 🕒 CRONÓMETRO MODERNO
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.black)
                        .frame(height: 100)
                        .padding(.horizontal)
                        .shadow(radius: 4)

                    HStack(spacing: 24) {
                        Text(formatearTiempo(segundos: tiempo))
                            .font(.system(size: 32, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)

                        Button(action: {
                            if timerActivo {
                                temporizador?.invalidate()
                                timerActivo = false
                            } else {
                                temporizador = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                                    tiempo += 1
                                }
                                timerActivo = true
                            }
                        }) {
                            Image(systemName: timerActivo ? "pause.fill" : "play.fill")
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.green)
                                .clipShape(Circle())
                        }

                        Button(action: {
                            temporizador?.invalidate()
                            tiempo = 0
                            timerActivo = false
                        }) {
                            Image(systemName: "arrow.counterclockwise")
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(.top)

                // 🔁 LISTA DE EJERCICIOS
                ForEach(ejercicios) { ejercicio in
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 16) {
                            AsyncImage(url: URL(string: ejercicio.imagen_url ?? "")) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView().frame(width: 60, height: 60)
                                case .success(let image):
                                    image.resizable().scaledToFill()
                                case .failure:
                                    Image(systemName: "photo")
                                        .resizable()
                                        .scaledToFit()
                                        .padding(16)
                                        .foregroundColor(.gray)
                                @unknown default:
                                    EmptyView()
                                }
                            }
                            .frame(width: 60, height: 60)
                            .background(Color.gray.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                            VStack(alignment: .leading, spacing: 4) {
                                Text(ejercicio.nombre)
                                    .font(.headline)
                                    .foregroundColor(.black)

                                Text(ejercicio.descripcion)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }

                            Spacer()
                        }

                        // 📋 SETS DEL EJERCICIO
                        VStack(spacing: 8) {
                            ForEach(setsPorEjercicio[ejercicio.id] ?? [], id: \.id) { set in
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("Set \(set.numero)")
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundColor(.black)

                                        Spacer()

                                        HStack(spacing: 16) {
                                            HStack(spacing: 6) {
                                                Image(systemName: "repeat")
                                                    .foregroundColor(.blue)
                                                TextField("Reps", value: Binding(
                                                    get: { set.repeticiones },
                                                    set: { set.repeticiones = $0 }
                                                ), formatter: intFormatter)
                                                    .keyboardType(.numberPad)
                                                    .frame(width: 40)
                                                    .multilineTextAlignment(.center)
                                                    .foregroundColor(.black)
                                            }

                                            HStack(spacing: 6) {
                                                Image(systemName: "scalemass")
                                                    .foregroundColor(.green)
                                                TextField("Peso", value: Binding(
                                                    get: { set.peso },
                                                    set: { set.peso = $0 }
                                                ), formatter: decimalFormatter)
                                                    .keyboardType(.decimalPad)
                                                    .frame(width: 60)
                                                    .multilineTextAlignment(.center)
                                                    .foregroundColor(.black)
                                            }
                                        }
                                    }
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                            }

                            Button(action: {
                                var nuevosSets = setsPorEjercicio[ejercicio.id] ?? []
                                let nuevo = SetRegistro(
                                    numero: nuevosSets.count + 1,
                                    repeticiones: 10,
                                    peso: 0
                                )
                                nuevosSets.append(nuevo)
                                setsPorEjercicio[ejercicio.id] = nuevosSets
                            }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Añadir serie")
                                }
                                .foregroundColor(.black)
                                .padding(.vertical, 6)
                                .padding(.horizontal, 12)
                                .background(Color.white)
                                .cornerRadius(10)
                                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                            }
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                    .padding(.horizontal)
                }

                // ✅ BOTÓN PUBLICAR ENTRENAMIENTO
                Button(action: {
                    temporizador?.invalidate()
                    timerActivo = false

                    Task {
                        do {
                            try await SupabaseService.shared.publicarEntrenamiento(
                                fecha: Date(),
                                ejercicios: ejercicios,
                                setsPorEjercicio: setsPorEjercicio
                            )
                            dismiss() // Cierra EntrenandoView
                        } catch {
                            print("❌ Error al publicar entrenamiento:", error)
                        }
                    }
                }) {
                    Text("Publicar entrenamiento")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.black)
                        .cornerRadius(16)
                        .shadow(radius: 4)
                        .padding(.horizontal)
                        .padding(.top, 20)
                        .padding(.bottom, 40)
                }
            }
            .padding(.top)
        }
        .navigationTitle("Entrenando")
    }

    func formatearTiempo(segundos: Int) -> String {
        let minutos = segundos / 60
        let segundos = segundos % 60
        return String(format: "%02d:%02d", minutos, segundos)
    }
}
