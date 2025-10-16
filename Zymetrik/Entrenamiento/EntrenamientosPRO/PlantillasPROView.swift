//
//  PlantillasPROView.swift
//  YourAppName
//
//  Created by Developer on 2025-10-16.
//

import SwiftUI
import UIKit

// MARK: - Brand Colors
private let brandGradientColors: [Color] = [.purple, .pink, .orange]
private let brandAccent: Color = .pink

// MARK: - Utilidades de día (1=Domingo ... 7=Sábado)
private let weekdayOrderLtoD: [Int] = [2,3,4,5,6,7,1] // Orden visual: L..D
private let weekdayShortLabel: [Int:String] = [1:"D",2:"L",3:"M",4:"X",5:"J",6:"V",7:"S"]
private let weekdayLongLabel:  [Int:String] = [1:"Domingo",2:"Lunes",3:"Martes",4:"Miércoles",5:"Jueves",6:"Viernes",7:"Sábado"]

// MARK: - Modelo de plantilla ligera
struct WeeklyTemplateLite: Identifiable, Equatable {
    let id = UUID()
    let titulo: String
    let subtitulo: String
    let nivel: NivelEntrenamiento
    let diasSemana: Int
    let iconName: String

    static func == (lhs: WeeklyTemplateLite, rhs: WeeklyTemplateLite) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Vista principal
struct PlantillasPROView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var planStore: TrainingPlanStore
    @EnvironmentObject var subs: SubscriptionStore
    @EnvironmentObject var routine: RoutineTracker

    /// Catálogo de ejercicios que usará el motor (mismo modelo que ListaEjerciciosView)
    let ejerciciosCatalogo: [Ejercicio]

    // Filtros
    @State private var nivel: NivelEntrenamiento = .intermedio
    @State private var diasPorSemana: Int = 4   // sincronizado visualmente con la selección de días

    // Config de aplicación
    @State private var fechaInicio: Date = Date()
    @State private var semanas: Int = 4
    @State private var weekdaysSeleccionados: Set<Int> = [2,4,6] // L, X, V

    // Preview (weekday 1..7 → ejercicios)
    @State private var previewSemana: [Int: [Ejercicio]] = [:]

    // Estado UI
    @State private var mostrandoPaywall = false
    @State private var toastOK = false
    @State private var applying = false
    @State private var selectedTemplateTitle: String? = nil

    // Métricas auxiliares de la planificación
    private var sesionesPorSemana: Int {
        previewSemana.values.filter { !$0.isEmpty }.count
    }
    private var fechaFin: Date {
        Calendar.current.date(byAdding: .day, value: semanas * 7 - 1, to: fechaInicio) ?? fechaInicio
    }
    private var selectedDaysCount: Int { weekdaysSeleccionados.count }

    // Generador de plantillas según foco/nivel, filtradas por nº de días seleccionados
    private var plantillas: [WeeklyTemplateLite] {
        CustomRoutinesLibrary.all
            .filter { $0.nivel == nivel }
            .filter { $0.diasPorSemana == max(0, selectedDaysCount) } // solo rutinas que casan con la selección
            .map { r in
                WeeklyTemplateLite(
                    titulo: r.title,
                    subtitulo: r.subtitle,
                    nivel: r.nivel,
                    diasSemana: r.diasPorSemana,
                    iconName: "dumbbell"
                )
            }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    header
                    filtros

                    WeekdayPicker(selection: $weekdaysSeleccionados)

                    LazyVStack(spacing: 12) {
                        ForEach(plantillas, id: \.titulo) { t in
                            TemplateCard(template: t, icon: t.iconName) {
                                onTap(template: t)
                            }
                        }
                        if plantillas.isEmpty {
                            Text("No hay plantillas de \(selectedDaysCount) día(s) para el nivel \(nivel.rawValue).")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .padding(.top, 4)
                        }
                    }

                    if !previewSemana.isEmpty {
                        PreviewSemana(preview: previewSemana)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    // ====== Configuración de calendario / aplicar ======
                    VStack(spacing: 10) {
                        HStack(spacing: 12) {
                            Image(systemName: "calendar")
                                .font(.headline)
                                .foregroundStyle(brandAccent)
                                .frame(width: 28, height: 28)
                                .background(Circle().fill(Color(.tertiarySystemBackground)))
                            DatePicker("Fecha de inicio", selection: $fechaInicio, displayedComponents: .date)
                                .datePickerStyle(.compact)
                                .tint(brandAccent)
                            Spacer(minLength: 0)
                        }
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black.opacity(0.06)))

                        HStack(spacing: 12) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.headline)
                                .foregroundStyle(brandAccent)
                                .frame(width: 28, height: 28)
                                .background(Circle().fill(Color(.tertiarySystemBackground)))
                            Stepper("Duración: \(semanas) semanas", value: $semanas, in: 1...16)
                                .tint(brandAccent)
                        }
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black.opacity(0.06)))

                        if sesionesPorSemana > 0 {
                            HStack(spacing: 8) {
                                Label("\(sesionesPorSemana * semanas) sesiones totales", systemImage: "checklist")
                                    .font(.caption.weight(.semibold))
                                Spacer()
                                Text("\(fechaInicio.formatted(date: .abbreviated, time: .omitted)) – \(fechaFin.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(RoundedRectangle(cornerRadius: 10).fill(Color(.tertiarySystemBackground)))
                        }

                        Button {
                            guard !applying else { return }
                            let gen = UIImpactFeedbackGenerator(style: .medium)
                            gen.impactOccurred()
                            applying = true
                            Task {
                                await aplicarRutina()
                                applying = false
                            }
                        } label: {
                            HStack {
                                if applying {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "calendar.badge.plus")
                                }
                                Text(applying ? "Aplicando..." : "Aplicar rutina al calendario").bold()
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(LinearGradient(colors: brandGradientColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                            .foregroundStyle(.white)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.25)))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(color: brandGradientColors.first!.opacity(0.25), radius: 10, x: 0, y: 6)
                            .overlay(alignment: .topTrailing) {
                                if !subs.isPro {
                                    HStack(spacing: 6) {
                                        Image(systemName: "lock.fill")
                                        Text("PRO").bold()
                                    }
                                    .font(.caption2)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Capsule().fill(Color.white.opacity(0.15)))
                                    .padding(8)
                                }
                            }
                        }
                        .disabled(previewSemana.isEmpty || !subs.isPro || applying)
                        .opacity((previewSemana.isEmpty || applying) ? 0.6 : 1)

                        if !subs.isPro {
                            Text("Requiere Zymetrik PRO (2,99 € / mes)")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding()
                .animation(.easeInOut(duration: 0.25), value: previewSemana.isEmpty)
                .animation(.spring(response: 0.3, dampingFraction: 0.85), value: weekdaysSeleccionados)
            }
            .background(
                LinearGradient(colors: [brandGradientColors.first!.opacity(0.08), Color(.systemBackground)],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            )
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
            // Mantén sincronizado el contador visible con la selección de días
            .onChange(of: weekdaysSeleccionados) { oldValue, newValue in
                diasPorSemana = max(1, selectedDaysCount)
                // Si ya hay una preview activa, re-mapéala al nuevo patrón de días
                if let title = selectedTemplateTitle,
                   let routineDef = CustomRoutinesLibrary.all.first(where: { $0.title == title }) {
                    let mapped = routineDef.mapToEjercicios(from: ejerciciosCatalogo)
                    previewSemana = remapPreviewDays(mapped, to: weekdaysSeleccionados)
                }
            }
        }
    }

    // MARK: - UI
    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: brandGradientColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 44, height: 44)
                Image(systemName: "dumbbell")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Elige tu plan de entrenamiento").font(.headline)
                Text("Personaliza nivel y días").font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            if subs.isPro {
                Text("PRO").font(.caption).bold()
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(Capsule().fill(Color.green.opacity(0.2)))
            } else {
                Button {
                    mostrandoPaywall = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                        Text("PRO 2,99 €")
                    }
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(
                        LinearGradient(colors: brandGradientColors.map { $0.opacity(0.25) }, startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                }
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(LinearGradient(colors: [brandGradientColors.first!.opacity(0.12), Color(.secondarySystemBackground)], startPoint: .topLeading, endPoint: .bottomTrailing)))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.black.opacity(0.05)))
    }

    private var filtros: some View {
        VStack(spacing: 12) {
            Picker("Nivel", selection: $nivel) {
                ForEach(NivelEntrenamiento.allCases) { n in Text(n.rawValue).tag(n) }
            }
            .pickerStyle(.segmented)

            // Texto informativo sincronizado con el picker de días
            HStack {
                Text("Días por semana: \(selectedDaysCount)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(LinearGradient(colors: [Color(.secondarySystemBackground), brandGradientColors.first!.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing)))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.black.opacity(0.05)))
    }

    // MARK: - Actions
    private func onTap(template: WeeklyTemplateLite) {
        guard subs.isPro else { mostrandoPaywall = true; return }
        guard let routineDef = CustomRoutinesLibrary.all.first(where: { $0.title == template.titulo }) else { return }
        let mapped = routineDef.mapToEjercicios(from: ejerciciosCatalogo)

        // Remapear los días de la rutina elegida a los días seleccionados por el usuario
        let remapped = remapPreviewDays(mapped, to: weekdaysSeleccionados)
        previewSemana = remapped
        selectedTemplateTitle = template.titulo
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
        routine.activePlanName = selectedTemplateTitle ?? "Rutina"
        if let first = affected.min(), let last = affected.max() {
            routine.activeRange = first...last
        }
        toastOK = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { dismiss() }
    }

    /// Remapea los días de una rutina (clave 1..7) a los días seleccionados por el usuario.
    /// Mantiene el orden L..D, rellena el resto como descanso (arrays vacíos) para que Preview lo muestre.
    private func remapPreviewDays(_ original: [Int: [Ejercicio]],
                                  to selected: Set<Int>) -> [Int: [Ejercicio]] {
        // Diccionario base con todos los días vacíos
        var out = Dictionary(uniqueKeysWithValues: weekdayOrderLtoD.map { ($0, [Ejercicio]()) })

        // Orden de días definidos por la rutina
        let routineDays = original.keys.sorted {
            weekdayOrderLtoD.firstIndex(of: $0)! < weekdayOrderLtoD.firstIndex(of: $1)!
        }

        // Orden de los días seleccionados por el usuario
        let selectedDays = selected.sorted {
            weekdayOrderLtoD.firstIndex(of: $0)! < weekdayOrderLtoD.firstIndex(of: $1)!
        }

        // Asignación 1 a 1 en orden: Día1 rutina → Primer día seleccionado, etc.
        for (srcDay, dstDay) in zip(routineDays, selectedDays) {
            out[dstDay] = original[srcDay] ?? []
        }
        return out
    }
}

// MARK: - Weekday Picker (1=Dom..7=Sáb; orden L..D)
private struct WeekdayPicker: View {
    @Binding var selection: Set<Int>

    var body: some View {
        HStack(spacing: 8) {
            ForEach(weekdayOrderLtoD, id: \.self) { d in
                let on = selection.contains(d)
                Text(weekdayShortLabel[d] ?? "?")
                    .font(.subheadline.weight(.semibold))
                    .frame(width: 36, height: 36)
                    .background {
                        if on {
                            LinearGradient(colors: brandGradientColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                        } else {
                            Color(.secondarySystemBackground)
                        }
                    }
                    .foregroundStyle(on ? .white : .primary)
                    .overlay(Circle().strokeBorder(on ? Color.white.opacity(0.6) : Color.black.opacity(0.08), lineWidth: 1))
                    .shadow(color: on ? brandGradientColors.first!.opacity(0.25) : .clear, radius: 8, x: 0, y: 4)
                    .clipShape(Circle())
                    .scaleEffect(on ? 1.05 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.85), value: selection)
                    .onTapGesture {
                        let gen = UIImpactFeedbackGenerator(style: .light)
                        gen.impactOccurred()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                            if on { selection.remove(d) } else { selection.insert(d) }
                        }
                    }
            }
            Spacer()
        }
    }
}

// MARK: - Tarjeta
private struct InfoChip: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Capsule().fill(Color(.secondarySystemBackground)))
            .overlay(Capsule().stroke(Color.black.opacity(0.06)))
    }
}

private struct PressableCardStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

private struct TemplateCard: View {
    let template: WeeklyTemplateLite
    let icon: String
    var onTap: () -> Void

    private var gradientColors: [Color] { brandGradientColors }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(LinearGradient(colors: gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing).opacity(0.18))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.black.opacity(0.06)))
                        .shadow(color: (gradientColors.first ?? .pink).opacity(0.35), radius: 12, x: 0, y: 6)
                        .frame(width: 64, height: 64)
                    Image(systemName: icon.isEmpty ? "bolt.fill" : icon)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(LinearGradient(colors: gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text(template.titulo).font(.headline)
                    Text(template.subtitulo).font(.subheadline).foregroundStyle(.secondary)
                    HStack(spacing: 6) {
                        InfoChip(text: template.nivel.rawValue)
                        InfoChip(text: "\(template.diasSemana)x")
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(Color(.tertiarySystemBackground)))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(LinearGradient(colors: [Color(.secondarySystemBackground), Color(.systemBackground)], startPoint: .topLeading, endPoint: .bottomTrailing))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(colors: [gradientColors.first!.opacity(0.35), gradientColors.last!.opacity(0.35)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: 1
                    )
            )
            .overlay(alignment: .topLeading) {
                if !SubscriptionStore.shared.isPro {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                        Text("Mejor valor")
                    }
                    .font(.caption2.weight(.bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule().fill(
                            LinearGradient(colors: gradientColors.map { $0.opacity(0.9) }, startPoint: .leading, endPoint: .trailing)
                        )
                    )
                    .foregroundStyle(.white)
                    .padding(8)
                }
            }
            .shadow(color: (gradientColors.first ?? Color.black).opacity(0.12), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(PressableCardStyle())
    }
}

// MARK: - Preview semanal
private struct PreviewSemana: View {
    let preview: [Int: [Ejercicio]]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Previsualización").font(.headline).foregroundStyle(brandAccent)
            ForEach(weekdayOrderLtoD, id: \.self) { d in
                let items = preview[d] ?? []
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(weekdayLongLabel[d] ?? "").font(.subheadline.weight(.semibold))
                        Spacer()
                        Text(items.isEmpty ? "Descanso" : "\(items.count) ejercicios")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    if !items.isEmpty {
                        ForEach(items) { e in
                            HStack(spacing: 10) {
                                Text(e.nombre).font(.subheadline)
                                Spacer()
                                Text(e.categoria)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Capsule().fill(LinearGradient(colors: [Color(.secondarySystemBackground), brandGradientColors.first!.opacity(0.06)], startPoint: .leading, endPoint: .trailing)))
                            }
                            .padding(8)
                            .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemBackground)))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black.opacity(0.06)))
                            .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemBackground)))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.black.opacity(0.05)))
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 6)
    }
}
