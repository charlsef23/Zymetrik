import SwiftUI
import UserNotifications
import AVFoundation

// MARK: - Vista Principal del Temporizador
struct SelectorTiempoView: View {
    @State private var tiempoRestante: TimeInterval = 0
    @State private var tiempoInicial: TimeInterval = 0
    @State private var temporizadorActivo = false
    @State private var temporizadorPausado = false
    @State private var mostrarSelector = false
    @State private var timer: Timer?
    @State private var audioPlayer: AVAudioPlayer?
    @State private var notificationManager = NotificationManager()
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Header con el título
                HStack {
                    Text("Temporizador")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                Spacer()
                
                // Círculo principal del temporizador
                ZStack {
                    // Círculo de fondo
                    Circle()
                        .stroke(
                            Color.primary.opacity(0.1),
                            style: StrokeStyle(lineWidth: 8)
                        )
                        .frame(width: min(geometry.size.width - 80, 320))
                    
                    // Círculo de progreso
                    Circle()
                        .trim(from: 0, to: progreso)
                        .stroke(
                            colorProgreso,
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: min(geometry.size.width - 80, 320))
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.3), value: progreso)
                    
                    // Display del tiempo
                    VStack(spacing: 4) {
                        Text(formatearTiempo(tiempoRestante))
                            .font(.system(size: 56, weight: .thin, design: .default))
                            .foregroundColor(.primary)
                            .monospacedDigit()
                        
                        if temporizadorActivo && !temporizadorPausado {
                            Text("restante")
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(.secondary)
                        } else if temporizadorPausado {
                            Text("pausado")
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(.orange)
                        }
                    }
                }
                
                Spacer()
                
                // Botones de control estilo Apple
                HStack(spacing: 60) {
                    // Botón izquierdo (Cancelar/Configurar)
                    Button(action: {
                        if temporizadorActivo || temporizadorPausado {
                            cancelarTemporizador()
                        } else {
                            mostrarSelector = true
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color(.systemGray5))
                                .frame(width: 80, height: 80)
                            
                            if temporizadorActivo || temporizadorPausado {
                                Text("Cancelar")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.primary)
                            } else {
                                Image(systemName: "plus")
                                    .font(.system(size: 24, weight: .medium))
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                    .scaleEffect(temporizadorActivo || temporizadorPausado ? 1.0 : 0.9)
                    .animation(.easeInOut(duration: 0.2), value: temporizadorActivo || temporizadorPausado)
                    
                    // Botón principal (Iniciar/Pausar/Reanudar)
                    Button(action: {
                        if temporizadorActivo && !temporizadorPausado {
                            pausarTemporizador()
                        } else {
                            iniciarTemporizador()
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(botonPrincipalActivo ? Color.orange : Color(.systemGray5))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: iconoBotonPrincipal)
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(botonPrincipalActivo ? .white : .primary)
                        }
                    }
                    .disabled(tiempoRestante <= 0 && !temporizadorPausado)
                    .scaleEffect(botonPrincipalActivo ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: botonPrincipalActivo)
                }
                .padding(.bottom, 40)
            }
        }
        .background(Color(.systemBackground))
        .onAppear {
            configurarAudio()
            Task {
                await notificationManager.solicitarPermisos()
            }
        }
        .sheet(isPresented: $mostrarSelector) {
            SelectorTiempoAppleStyle { horas, minutos, segundos in
                configurarTiempo(horas: horas, minutos: minutos, segundos: segundos)
            }
        }
    }
    
    // MARK: - Propiedades Calculadas
    private var progreso: Double {
        guard tiempoInicial > 0 else { return 0 }
        return 1.0 - (tiempoRestante / tiempoInicial)
    }
    
    private var colorProgreso: Color {
        if tiempoRestante <= 60 && temporizadorActivo {
            return .red
        } else if temporizadorPausado {
            return .orange
        } else {
            return .orange
        }
    }
    
    private var botonPrincipalActivo: Bool {
        return (temporizadorActivo && !temporizadorPausado) || temporizadorPausado
    }
    
    private var iconoBotonPrincipal: String {
        if temporizadorPausado {
            return "play.fill"
        } else if temporizadorActivo {
            return "pause.fill"
        } else {
            return "play.fill"
        }
    }
    
    // MARK: - Funciones del Temporizador
    private func configurarTiempo(horas: Int, minutos: Int, segundos: Int) {
        let tiempoTotal = TimeInterval(horas * 3600 + minutos * 60 + segundos)
        tiempoRestante = tiempoTotal
        tiempoInicial = tiempoTotal
        temporizadorPausado = false
    }
    
    private func iniciarTemporizador() {
        guard tiempoRestante > 0 else { return }
        
        temporizadorActivo = true
        temporizadorPausado = false
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if tiempoRestante > 0 {
                tiempoRestante -= 1
            } else {
                temporizadorFinalizó()
            }
        }
        
        // Programar notificación
        Task {
            await notificationManager.programarNotificacion(
                tiempoRestante: tiempoRestante
            )
        }
    }
    
    private func pausarTemporizador() {
        temporizadorPausado = true
        timer?.invalidate()
        timer = nil
        
        // Cancelar notificación programada
        notificationManager.cancelarNotificaciones()
    }
    
    private func cancelarTemporizador() {
        temporizadorActivo = false
        temporizadorPausado = false
        timer?.invalidate()
        timer = nil
        tiempoRestante = 0
        tiempoInicial = 0
        
        notificationManager.cancelarNotificaciones()
    }
    
    private func temporizadorFinalizó() {
        temporizadorActivo = false
        temporizadorPausado = false
        timer?.invalidate()
        timer = nil
        reproducirSonido()
        
        // Mostrar notificación local si la app está en primer plano
        Task {
            await notificationManager.mostrarNotificacionLocal()
        }
    }
    
    // MARK: - Funciones de Audio
    private func configurarAudio() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Error configurando sesión de audio: \(error)")
        }
    }
    
    private func reproducirSonido() {
        AudioServicesPlaySystemSound(1005)
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }
    
    // MARK: - Utilidades
    private func formatearTiempo(_ tiempo: TimeInterval) -> String {
        let horas = Int(tiempo) / 3600
        let minutos = (Int(tiempo) % 3600) / 60
        let segundos = Int(tiempo) % 60
        
        if horas > 0 {
            return String(format: "%d:%02d:%02d", horas, minutos, segundos)
        } else {
            return String(format: "%d:%02d", minutos, segundos)
        }
    }
}

// MARK: - Selector de Tiempo Estilo Apple
struct SelectorTiempoAppleStyle: View {
    @Environment(\.dismiss) var dismiss
    @State private var horas = 0
    @State private var minutos = 1
    @State private var segundos = 0
    
    var onGuardar: (Int, Int, Int) -> Void
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    // Título
                    Text("Temporizador")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding(.top, 20)
                    
                    Spacer()
                    
                    // Selectores estilo Apple Watch/iPhone
                    HStack(spacing: 0) {
                        Spacer()
                        
                        // Selector de Horas
                        VStack(spacing: 8) {
                            Text("horas")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                                .textCase(.lowercase)
                            
                            Picker("Horas", selection: $horas) {
                                ForEach(0...23, id: \.self) { hour in
                                    Text("\(hour)")
                                        .font(.system(size: 22, weight: .regular, design: .default))
                                        .monospacedDigit()
                                        .tag(hour)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 80, height: 180)
                            .clipped()
                            .scaleEffect(0.8)
                        }
                        
                        Spacer()
                        
                        // Selector de Minutos
                        VStack(spacing: 8) {
                            Text("min")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                                .textCase(.lowercase)
                            
                            Picker("Minutos", selection: $minutos) {
                                ForEach(0...59, id: \.self) { minute in
                                    Text("\(minute)")
                                        .font(.system(size: 22, weight: .regular, design: .default))
                                        .monospacedDigit()
                                        .tag(minute)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 80, height: 180)
                            .clipped()
                            .scaleEffect(0.8)
                        }
                        
                        Spacer()
                        
                        // Selector de Segundos
                        VStack(spacing: 8) {
                            Text("seg")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                                .textCase(.lowercase)
                            
                            Picker("Segundos", selection: $segundos) {
                                ForEach(0...59, id: \.self) { second in
                                    Text("\(second)")
                                        .font(.system(size: 22, weight: .regular, design: .default))
                                        .monospacedDigit()
                                        .tag(second)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 80, height: 180)
                            .clipped()
                            .scaleEffect(0.8)
                        }
                        
                        Spacer()
                    }
                    
                    Spacer()
                    
                    // Presets rápidos estilo Apple
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                        ForEach(presetsRapidos, id: \.tiempo) { preset in
                            Button(action: {
                                let h = preset.tiempo / 3600
                                let m = (preset.tiempo % 3600) / 60
                                let s = preset.tiempo % 60
                                horas = h
                                minutos = m
                                segundos = s
                            }) {
                                VStack(spacing: 4) {
                                    Text(preset.label)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                                .frame(height: 60)
                                .frame(maxWidth: .infinity)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            }
                            .foregroundColor(.primary)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                    .foregroundColor(.orange)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Iniciar") {
                        onGuardar(horas, minutos, segundos)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.orange)
                    .disabled(horas == 0 && minutos == 0 && segundos == 0)
                }
            }
        }
        .presentationDragIndicator(.visible)
    }
    
    private let presetsRapidos: [(tiempo: Int, label: String)] = [
        (60, "1 min"),
        (300, "5 min"),
        (600, "10 min"),
        (900, "15 min"),
        (1200, "20 min"),
        (1800, "30 min"),
        (2700, "45 min"),
        (3600, "1 hora")
    ]
}

// MARK: - Manager de Notificaciones
@MainActor
class NotificationManager: ObservableObject {
    
    func solicitarPermisos() async {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound]
            )
            print("Permisos de notificación: \(granted)")
        } catch {
            print("Error solicitando permisos: \(error)")
        }
    }
    
    func programarNotificacion(tiempoRestante: TimeInterval) async {
        cancelarNotificaciones()
        
        let content = UNMutableNotificationContent()
        content.title = "Temporizador"
        content.body = "¡El tiempo ha terminado!"
        content.sound = UNNotificationSound.default
        content.categoryIdentifier = "TIMER_CATEGORY"
        
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: tiempoRestante,
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "timer_notification",
            content: content,
            trigger: trigger
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("Error programando notificación: \(error)")
        }
    }
    
    func cancelarNotificaciones() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["timer_notification"]
        )
    }
    
    func mostrarNotificacionLocal() async {
        print("¡Temporizador finalizado!")
    }
}

