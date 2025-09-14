import SwiftUI
import PhotosUI
import Foundation

struct FeedbackView: View {
    // UI State
    @Environment(\.dismiss) private var dismiss

    @State private var tipo: Tipo = .bug
    @State private var severidad: Severidad = .media
    @State private var titulo: String = ""
    @State private var mensaje: String = ""
    @State private var categoria: String = ""
    @State private var calificacion: Int = 5
    @State private var permitirContacto: Bool = false
    @State private var emailContacto: String = ""

    // Captura de pantalla
    @State private var pickerItem: PhotosPickerItem?
    @State private var capturaPreview: UIImage?
    @State private var capturaData: Data?

    // Estado de envío
    @State private var enviando = false
    @State private var mostrarGracias = false
    @State private var errorMsg: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Tipo") {
                    Picker("Tipo", selection: $tipo) {
                        ForEach(Tipo.allCases, id: \.self) { t in
                            Text(t.label).tag(t)
                        }
                    }
                    .pickerStyle(.segmented)

                    if tipo == .bug {
                        Picker("Severidad", selection: $severidad) {
                            ForEach(Severidad.allCases, id: \.self) { s in
                                Text(s.label).tag(s)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }

                Section("Contenido") {
                    TextField("Título corto", text: $titulo)
                        .textInputAutocapitalization(.sentences)

                    TextField("Categoría (opcional: perfil, feed, entrenos...)", text: $categoria)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Descripción")
                        TextEditor(text: $mensaje)
                            .frame(minHeight: 120)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.secondary.opacity(0.2))
                            )
                        Text("\(mensaje.count)/1000")
                            .font(.caption)
                            .foregroundColor(mensaje.count < 10 ? .red : .secondary)
                    }
                }

                Section("Valoración (opcional)") {
                    Stepper(value: $calificacion, in: 1...5) {
                        HStack {
                            Text("Calificación")
                            Spacer()
                            Text("\(calificacion) / 5")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Contacto (opcional)") {
                    Toggle("Permitir que te contactemos", isOn: $permitirContacto)
                    if permitirContacto {
                        TextField("Email de contacto", text: $emailContacto)
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    }
                }

                Section("Captura de pantalla (opcional)") {
                    PhotosPicker(selection: $pickerItem, matching: .images) {
                        HStack {
                            Image(systemName: "paperclip")
                            Text(capturaPreview == nil ? "Adjuntar imagen" : "Cambiar imagen")
                            Spacer()
                            if let capturaPreview {
                                Image(uiImage: capturaPreview)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 44, height: 44)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.secondary.opacity(0.2))
                                    )
                            }
                        }
                    }
                    if let capturaData {
                        Text(ByteCountFormatter.string(fromByteCount: Int64(capturaData.count), countStyle: .file))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Info del sistema") {
                    HStack {
                        Text("Versión app")
                        Spacer()
                        Text(FeedbackService.appVersion() ?? "—").foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Dispositivo")
                        Spacer()
                        Text(FeedbackService.deviceModel()).foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("SO")
                        Spacer()
                        Text(FeedbackService.osVersion()).foregroundStyle(.secondary)
                    }
                }

                Section {
                    Button(action: enviar) {
                        HStack {
                            if enviando { ProgressView() }
                            Text("Enviar feedback")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .disabled(!formValido || enviando)
                } footer: {
                    Text("Tu mensaje se envía de forma privada al equipo de Zymetrik. Gracias por ayudarnos a mejorar.")
                }
            }
            .navigationTitle("Enviar feedback")
            .task(id: pickerItem) { await cargarCaptura() }
            .alert("¡Gracias por tu feedback! 🖤", isPresented: $mostrarGracias) {
                Button("OK") { dismiss() }
            } message: {
                Text("Lo revisaremos cuanto antes.")
            }
            .alert("Error", isPresented: .constant(errorMsg != nil), actions: {
                Button("OK") { errorMsg = nil }
            }, message: {
                Text(errorMsg ?? "")
            })
        }
    }

    private var formValido: Bool {
        !titulo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        mensaje.trimmingCharacters(in: .whitespacesAndNewlines).count >= 10 &&
        (!permitirContacto || emailContactoEsValido(emailContacto))
    }

    private func emailContactoEsValido(_ s: String) -> Bool {
        guard !s.isEmpty else { return false }
        // Raw string para no escapar backslashes
        let pattern = #"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$"#
        let predicate = NSPredicate(format: "SELF MATCHES[c] %@", pattern)
        return predicate.evaluate(with: s)
    }

    private func enviar() {
        Task {
            enviando = true
            do {
                let userID = try await FeedbackService.shared.currentUserID()
                // Subir captura si existe
                var screenshotPath: String?
                if let data = capturaData {
                    screenshotPath = try await FeedbackService.shared.subirCaptura(data, userID: userID)
                }

                let payload = FeedbackInsert(
                    autor_id: userID,
                    tipo: tipo.rawValue,
                    titulo: titulo.trimmingCharacters(in: .whitespacesAndNewlines),
                    mensaje: mensaje.trimmingCharacters(in: .whitespacesAndNewlines),
                    categoria: categoria.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : categoria,
                    severidad: (tipo == .bug) ? severidad.rawValue : nil,
                    calificacion: calificacion,
                    email_contacto: permitirContacto ? emailContacto : nil,
                    app_version: FeedbackService.appVersion(),
                    os_version: FeedbackService.osVersion(),
                    device_model: FeedbackService.deviceModel(),
                    screenshot_path: screenshotPath
                )

                try await FeedbackService.shared.enviarFeedback(payload)
                resetForm()
                mostrarGracias = true
            } catch {
                errorMsg = "No se pudo enviar el feedback. \(error.localizedDescription)"
            }
            enviando = false
        }
    }

    private func resetForm() {
        titulo = ""
        mensaje = ""
        categoria = ""
        calificacion = 5
        severidad = .media
        tipo = .bug
        permitirContacto = false
        emailContacto = ""
        capturaPreview = nil
        capturaData = nil
        pickerItem = nil
    }

    private func cargarCaptura() async {
        guard let item = pickerItem else { return }
        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                // Comprimir a ~0.7 para que pese menos
                if let img = UIImage(data: data),
                   let jpeg = img.jpegData(compressionQuality: 0.7) {
                    await MainActor.run {
                        capturaPreview = img
                        capturaData = jpeg
                    }
                } else {
                    await MainActor.run {
                        capturaPreview = UIImage(data: data)
                        capturaData = data
                    }
                }
            }
        } catch {
            await MainActor.run {
                errorMsg = "No se pudo cargar la imagen seleccionada."
            }
        }
    }
}

// MARK: - Enums

private enum Tipo: String, CaseIterable {
    case bug, idea, ui, otro
    var label: String {
        switch self {
        case .bug: return "Bug"
        case .idea: return "Idea"
        case .ui: return "UI"
        case .otro: return "Otro"
        }
    }
}

private enum Severidad: String, CaseIterable {
    case baja, media, alta, critica
    var label: String {
        switch self {
        case .baja: return "Baja"
        case .media: return "Media"
        case .alta: return "Alta"
        case .critica: return "Crítica"
        }
    }
}
