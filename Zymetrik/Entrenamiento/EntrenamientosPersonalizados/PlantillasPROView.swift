import SwiftUI

// MARK: - Modelo de plantilla ligera
struct WeeklyTemplateLite: Identifiable, Equatable {
    let id = UUID()
    let titulo: String
    let subtitulo: String
    let nivel: NivelEntrenamiento
    let foco: FocoPlan
    let diasSemana: Int

    static func == (lhs: WeeklyTemplateLite, rhs: WeeklyTemplateLite) -> Bool {
        lhs.id == rhs.id
    }
}

struct PlantillasPROView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var planStore: TrainingPlanStore
    @EnvironmentObject var subs: SubscriptionStore
    @EnvironmentObject var routine: RoutineTracker

    /// Catálogo de ejercicios que usará el motor (mismo modelo que ListaEjerciciosView)
    let ejerciciosCatalogo: [Ejercicio]

    // Filtros
    @State private var nivel: NivelEntrenamiento = .intermedio
    @State private var foco: FocoPlan = .hibrido
    @State private var diasPorSemana: Int = 4

    // Config de aplicación
    @State private var fechaInicio: Date = Date()
    @State private var semanas: Int = 4
    @State private var weekdaysSeleccionados: Set<Int> = [2,4,6] // L, X, V

    // Preview (weekday 1..7 → ejercicios)
    @State private var previewSemana: [Int: [Ejercicio]] = [:]

    // Estado UI
    @State private var mostrandoPaywall = false
    @State private var toastOK = false

    // Generador de plantillas según foco/nivel
    private var plantillas: [WeeklyTemplateLite] {
        [
            WeeklyTemplateLite(titulo: "Full Body \(diasPorSemana)x",
                               subtitulo: "Rutina global por patrones",
                               nivel: nivel, foco: foco, diasSemana: diasPorSemana),
            WeeklyTemplateLite(titulo: "Push / Pull / Legs",
                               subtitulo: "Fuerza por bloques",
                               nivel: nivel, foco: .fuerza, diasSemana: max(diasPorSemana, 3)),
            WeeklyTemplateLite(titulo: "Cardio Interválico",
                               subtitulo: "Tempo · Intervalos · Fondo",
                               nivel: nivel, foco: .cardio, diasSemana: diasPorSemana),
            WeeklyTemplateLite(titulo: "Híbrido Atleta",
                               subtitulo: "Fuerza + MetCon + Cardio",
                               nivel: nivel, foco: .hibrido, diasSemana: diasPorSemana)
        ]
        .filter { foco == .hibrido ? true : ($0.foco == foco) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    header
                    filtros

                    WeekdayPicker(selection: $weekdaysSeleccionados)

                    LazyVStack(spacing: 12) {
                        ForEach(plantillas) { t in
                            TemplateCard(template: t, icon: foco.icon) {
                                onTap(template: t)
                            }
                        }
                    }

                    if !previewSemana.isEmpty {
                        PreviewSemana(preview: previewSemana)
                    }

                    VStack(spacing: 10) {
                        DatePicker("Fecha de inicio", selection: $fechaInicio, displayedComponents: .date)
                            .datePickerStyle(.compact)
                        Stepper("Duración: \(semanas) semanas", value: $semanas, in: 1...16)

                        Button {
                            Task { await aplicarRutina() }
                        } label: {
                            HStack {
                                Image(systemName: "calendar.badge.plus")
                                Text("Aplicar rutina al calendario").bold()
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .disabled(previewSemana.isEmpty || !subs.isPro)
                        .opacity(previewSemana.isEmpty ? 0.6 : 1)

                        if !subs.isPro {
                            Text("Requiere Zymetrik PRO (2,99 € / mes)")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Plantillas PRO")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if let name = routine.activePlanName {
                    ToolbarItem(placement: .topBarTrailing) {
                        RoutinePillButton(title: name) { /* abrir gestión si quieres */ }
                    }
                }
            }
            .sheet(isPresented: $mostrandoPaywall) {
                PaywallViewPro()
                    .environmentObject(SubscriptionStore.shared)
                    .presentationDetents([.medium, .large])
            }
            .toast($toastOK, text: "Rutina aplicada ✅")
        }
    }

    // MARK: - UI
    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: foco.icon).font(.system(size: 22, weight: .bold))
            Text("Elige tu plan de entrenamiento").font(.headline)
            Spacer()
            if subs.isPro {
                Text("PRO").font(.caption).bold()
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Capsule().fill(Color.green.opacity(0.2)))
            } else {
                Button {
                    mostrandoPaywall = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "lock.fill")
                        Text("PRO 2,99 €")
                    }
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(Capsule().fill(Color.orange.opacity(0.2)))
                }
            }
        }
    }

    private var filtros: some View {
        VStack(spacing: 12) {
            Picker("Nivel", selection: $nivel) {
                ForEach(NivelEntrenamiento.allCases) { n in Text(n.rawValue).tag(n) }
            }
            .pickerStyle(.segmented)

            Picker("Foco", selection: $foco) {
                ForEach(FocoPlan.allCases) { f in Label(f.rawValue, systemImage: f.icon).tag(f) }
            }
            .pickerStyle(.segmented)

            Stepper("Días por semana: \(diasPorSemana)", value: $diasPorSemana, in: 1...7)
        }
    }

    // MARK: - Actions
    private func onTap(template: WeeklyTemplateLite) {
        guard subs.isPro else { mostrandoPaywall = true; return }
        previewSemana = TemplateEngineLite.buildPreview(
            catalog: ejerciciosCatalogo,
            nivel: template.nivel,
            foco: template.foco,
            dias: weekdaysSeleccionados,
            diasPorSemana: template.diasSemana
        )
    }

    @MainActor
    private func aplicarRutina() async {
        guard subs.isPro else { mostrandoPaywall = true; return }
        guard !previewSemana.isEmpty else { return }

        let affected = TemplateEngineLite.apply(
            preview: previewSemana,
            startDate: fechaInicio,
            weeks: semanas,
            planStore: planStore
        )
        routine.activePlanName = "\(foco.rawValue) \(diasPorSemana)x · \(nivel.rawValue)"
        if let first = affected.min(), let last = affected.max() {
            routine.activeRange = first...last
        }
        toastOK = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { dismiss() }
    }
}

// MARK: - Weekday Picker (1=Dom..7=Sáb; orden L..D)
private struct WeekdayPicker: View {
    @Binding var selection: Set<Int>
    private let order: [Int] = [2,3,4,5,6,7,1] // L..D
    private let label: [Int:String] = [1:"D",2:"L",3:"M",4:"X",5:"J",6:"V",7:"S"]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(order, id: \.self) { d in
                let on = selection.contains(d)
                Text(label[d] ?? "?")
                    .font(.subheadline.weight(.semibold))
                    .frame(width: 36, height: 36)
                    .background(on ? Color.accentColor : Color(.secondarySystemBackground))
                    .foregroundStyle(on ? .white : .primary)
                    .clipShape(Circle())
                    .onTapGesture {
                        if on { selection.remove(d) } else { selection.insert(d) }
                    }
            }
            Spacer()
        }
    }
}

// MARK: - Tarjeta
private struct TemplateCard: View {
    let template: WeeklyTemplateLite
    let icon: String
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(LinearGradient(colors: [.purple,.pink,.orange],
                                             startPoint: .topLeading,
                                             endPoint: .bottomTrailing).opacity(0.18))
                        .frame(width: 56, height: 56)
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .bold))
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(template.titulo).font(.headline)
                    Text(template.subtitulo).font(.subheadline).foregroundStyle(.secondary)
                    Text("\(template.nivel.rawValue) · \(template.foco.rawValue) · \(template.diasSemana)x")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.headline).foregroundStyle(.secondary)
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemBackground)))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview semanal
private struct PreviewSemana: View {
    let preview: [Int: [Ejercicio]]
    private let order = [2,3,4,5,6,7,1]
    private let label: [Int: String] = [1:"Domingo",2:"Lunes",3:"Martes",4:"Miércoles",5:"Jueves",6:"Viernes",7:"Sábado"]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Previsualización").font(.headline)
            ForEach(order, id: \.self) { d in
                let items = preview[d] ?? []
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(label[d] ?? "").font(.subheadline.weight(.semibold))
                        Spacer()
                        Text(items.isEmpty ? "Descanso" : "\(items.count) ejercicios")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    if !items.isEmpty {
                        ForEach(items) { e in
                            HStack {
                                Text(e.nombre).font(.subheadline)
                                Spacer()
                                Text(e.categoria).font(.caption).foregroundStyle(.secondary)
                            }
                            .padding(8)
                            .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemBackground)))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black.opacity(0.06)))
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 14).fill(Color(.secondarySystemBackground)))
    }
}
