import SwiftUI

// MARK: - Suscripcion (placeholder simple)
// Reemplaza por tu implementación real si ya la tienes.
final class SuscripcionStore: ObservableObject {
    @Published var esPro: Bool = false
    
    func comprarPro() {
        // TODO: Integra con tu sistema de pagos real.
        // Para pruebas:
        esPro = true
    }
}

// MARK: - Modelos auxiliares
enum NivelEntrenamiento: String, CaseIterable, Identifiable {
    case principiante = "Principiante"
    case intermedio = "Intermedio"
    case avanzado = "Avanzado"
    var id: String { rawValue }
    
    /// Una guía rápida para UI
    var sugerencia: String {
        switch self {
        case .principiante: return "2–3 ejercicios · 2–3 series"
        case .intermedio:   return "3–5 ejercicios · 3–4 series"
        case .avanzado:     return "4–6 ejercicios · 4–5 series"
        }
    }
}

enum TipoEntrenamiento: String, CaseIterable, Identifiable {
    case gimnasio = "Gimnasio"
    case cardio   = "Cardio"
    var id: String { rawValue }
    
    var icono: String {
        switch self {
        case .gimnasio: return "dumbbell"
        case .cardio:   return "figure.run"
        }
    }
}

// MARK: - EntrenamientoPersonalizadoView
struct EntrenamientoPersonalizadoView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var planStore: TrainingPlanStore
    @EnvironmentObject var suscripcion: SuscripcionStore   // <- inyecta tu store real
    
    @State private var nivel: NivelEntrenamiento = .intermedio
    @State private var tipo: TipoEntrenamiento = .gimnasio
    @State private var fecha: Date = Date()
    
    // Selección traída desde ListaEjerciciosView
    @State private var ejerciciosSeleccionados: [Ejercicio] = []
    @State private var mostrarSelectorEjercicios = false
    @State private var mostrandoPaywall = false
    @State private var guardando = false
    @State private var showConfirm = false
    @State private var toastOK = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    cabeceraPaywallSiHaceFalta
                    controlesBasicos
                    resumenSugerencias
                    selectorFecha
                    
                    bloqueSeleccionEjercicios
                    
                    if !ejerciciosSeleccionados.isEmpty {
                        listadoSeleccion
                    }
                    
                    botonGuardarPlan
                        .padding(.top, 8)
                }
                .padding(.vertical, 16)
                .padding(.horizontal)
                .overlay(alertaSoloProOverlay)
            }
            .navigationTitle("Personalizado")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $mostrarSelectorEjercicios) {
                // Usamos tu ListaEjerciciosView como selector
                ListaEjerciciosView(
                    fecha: fecha,
                    onGuardar: { ejercicios in
                        // Guardamos solo en memoria aquí; la persistencia real al pulsar "Guardar plan"
                        self.ejerciciosSeleccionados = ejercicios
                    },
                    isPresented: $mostrarSelectorEjercicios
                )
                .environmentObject(planStore)
            }
            .sheet(isPresented: $mostrandoPaywall) {
                PaywallView(onComprar: {
                    suscripcion.comprarPro()
                    mostrandoPaywall = false
                })
                .presentationDetents([.medium, .large])
            }
            .toast($toastOK, text: "Plan guardado en el calendario ✅")
        }
    }
    
    // MARK: - Secciones UI
    @ViewBuilder
    private var cabeceraPaywallSiHaceFalta: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 22, weight: .bold))
                Text("Entrenamientos Personalizados")
                    .font(.title3).bold()
                Spacer()
                if suscripcion.esPro {
                    Text("PRO")
                        .font(.caption).bold()
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Color.green.opacity(0.2))
                        .clipShape(Capsule())
                } else {
                    Text("Solo PRO")
                        .font(.caption).bold()
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Color.orange.opacity(0.2))
                        .clipShape(Capsule())
                }
            }
            Text("Crea un plan adaptado a tu nivel y tipo de entrenamiento. Se añadirá a tu calendario automáticamente.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(
            LinearGradient(colors: [.purple, .pink, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
                .opacity(0.15)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var controlesBasicos: some View {
        VStack(spacing: 12) {
            // Tipo
            HStack(spacing: 8) {
                ForEach(TipoEntrenamiento.allCases) { t in
                    Toggle(isOn: .constant(tipo == t)) {
                        Label(t.rawValue, systemImage: t.icono)
                            .font(.subheadline.weight(.semibold))
                    }
                    .toggleStyle(.button)
                    .buttonStyle(.borderedProminent)
                    .tint(tipo == t ? .blue : .gray.opacity(0.25))
                    .onChange(of: tipo == t) { _, selected in
                        if selected { tipo = t }
                    }
                }
            }
            
            // Nivel
            Picker("Nivel", selection: $nivel) {
                ForEach(NivelEntrenamiento.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
        }
    }
    
    private var resumenSugerencias: some View {
        HStack(spacing: 10) {
            Image(systemName: "info.circle")
            Text(nivel.sugerencia)
                .font(.footnote)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal, 4)
    }
    
    private var selectorFecha: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Fecha de tu plan")
                .font(.subheadline).bold()
            DatePicker("", selection: $fecha, displayedComponents: [.date])
                .datePickerStyle(.compact)
                .labelsHidden()
        }
    }
    
    private var bloqueSeleccionEjercicios: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Ejercicios")
                .font(.subheadline).bold()
            Button {
                if suscripcion.esPro {
                    mostrarSelectorEjercicios = true
                } else {
                    mostrandoPaywall = true
                }
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text(ejerciciosSeleccionados.isEmpty ? "Elegir desde la lista" : "Editar selección")
                        .fontWeight(.semibold)
                    Spacer()
                    if !ejerciciosSeleccionados.isEmpty {
                        Text("\(ejerciciosSeleccionados.count)")
                            .font(.footnote).bold()
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(Capsule().fill(Color.black.opacity(0.06)))
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
            }
            .buttonStyle(.plain)
        }
    }
    
    private var listadoSeleccion: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(ejerciciosSeleccionados) { e in
                HStack {
                    Text(e.nombre).font(.subheadline)
                    Spacer()
                    Text(e.tipo).font(.caption).foregroundStyle(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemBackground)))
                .overlay(
                    RoundedRectangle(cornerRadius: 10).stroke(Color.black.opacity(0.06), lineWidth: 1)
                )
            }
        }
    }
    
    private var botonGuardarPlan: some View {
        Button {
            if !suscripcion.esPro {
                mostrandoPaywall = true
                return
            }
            guard !ejerciciosSeleccionados.isEmpty else {
                showConfirm = true
                return
            }
            guardarPlan()
        } label: {
            HStack {
                Spacer()
                if guardando { ProgressView() }
                Text("Guardar plan en \(fecha.formatted(date: .abbreviated, time: .omitted))")
                    .bold()
                Spacer()
            }
            .padding()
            .background(guardando ? Color.gray : Color.green)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(guardando)
        .confirmationDialog("No has elegido ejercicios", isPresented: $showConfirm, titleVisibility: .visible) {
            Button("Elegir ejercicios") { mostrarSelectorEjercicios = true }
            Button("Cancelar", role: .cancel) { }
        } message: {
            Text("Selecciona al menos un ejercicio para guardar el plan.")
        }
    }
    
    // Paywall overlay (bloqueo suave del contenido si no es Pro)
    private var alertaSoloProOverlay: some View {
        Group {
            if !suscripcion.esPro {
                VStack {
                    Spacer()
                    HStack {
                        Image(systemName: "lock.fill")
                        Text("Función exclusiva PRO")
                            .font(.footnote).bold()
                        Spacer()
                        Button("Suscribirme") { mostrandoPaywall = true }
                            .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding()
            }
        }
        .allowsHitTesting(false) // Solo informa; el botón superior ya controla acceso
    }
    
    // MARK: - Guardar
    private func guardarPlan() {
        guard !ejerciciosSeleccionados.isEmpty else { return }
        guardando = true
        Task {
            // Añade al plan del día y sincroniza store → calendar/EntrenamientoView
            planStore.add(ejercicios: ejerciciosSeleccionados, para: fecha)
            // Opcional: si tu store necesita refresco explícito:
            planStore.refresh(day: fecha)
            await MainActor.run {
                guardando = false
                toastOK = true
                // Cierra tras un pequeño delay para que se vea el toast
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Paywall simple
struct PaywallView: View {
    var onComprar: () -> Void
    
    var body: some View {
        VStack(spacing: 22) {
            Image(systemName: "crown.fill")
                .font(.system(size: 44))
                .padding(14)
                .background(Circle().fill(Color.yellow.opacity(0.25)))
            
            Text("Desbloquea Entrenamientos Personalizados")
                .font(.title3).bold()
                .multilineTextAlignment(.center)
            
            VStack(alignment: .leading, spacing: 10) {
                etiqueta("Crea planes a tu medida")
                etiqueta("Añade al calendario al instante")
                etiqueta("Acceso a filtros y favoritos")
                etiqueta("Todas las mejoras futuras PRO")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Button(action: onComprar) {
                Text("Suscribirme a PRO")
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.top, 10)
            
            Text("Cancela cuando quieras. El precio y la gestión dependen del App Store.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
    
    private func etiqueta(_ text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.seal.fill")
            Text(text).font(.subheadline)
        }
    }
}

// MARK: - Preview
struct EntrenamientoPersonalizadoView_Previews: PreviewProvider {
    static var previews: some View {
        EntrenamientoPersonalizadoView()
            .environmentObject(TrainingPlanStore())
            .environmentObject(SuscripcionStore())
    }
}
