import SwiftUI
import MessageUI

struct SupportView: View {
    @State private var subject: String = ""
    @State private var message: String = ""
    @State private var isSending: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""

    @State private var showMailComposer: Bool = false
    @State private var showMailFallbackAlert: Bool = false

    private let supportEmail = "soportezymetrik@outlook.es"
    private let subjectLimit = 100
    private let messageLimit = 1000

    var body: some View {
        Form {
            Section(header: Text("Asunto")) {
                HStack(alignment: .firstTextBaseline) {
                    TextField("Escribe un asunto", text: $subject)
                        .textInputAutocapitalization(.sentences)
                        .onChange(of: subject) { _, newValue in
                            if newValue.count > subjectLimit {
                                subject = String(newValue.prefix(subjectLimit))
                            }
                        }
                    Text("\(subject.count)/\(subjectLimit)")
                        .font(.caption)
                        .foregroundStyle(subject.count > subjectLimit ? .red : .secondary)
                }
            }

            Section(header: Text("Mensaje")) {
                ZStack(alignment: .topLeading) {
                    if message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("Cuéntanos con detalle tu duda o problema...")
                            .foregroundStyle(.secondary)
                            .padding(.top, 8)
                            .padding(.leading, 5)
                    }
                    TextEditor(text: $message)
                        .frame(minHeight: 180)
                        .onChange(of: message) { _, newValue in
                            if newValue.count > messageLimit {
                                message = String(newValue.prefix(messageLimit))
                            }
                        }
                }
                HStack {
                    Spacer()
                    Text("\(message.count)/\(messageLimit)")
                        .font(.caption)
                        .foregroundStyle(message.count > messageLimit ? .red : .secondary)
                }
            }
        }
        .navigationTitle("Soporte")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: send) {
                    if isSending {
                        ProgressView()
                    } else {
                        Label("Enviar", systemImage: "paperplane.fill")
                    }
                }
                .tint(.accentColor)
                .disabled(isSending || subject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .safeAreaInset(edge: .bottom) {
            Button(action: send) {
                HStack {
                    Spacer()
                    if isSending { ProgressView() }
                    Text(isSending ? "Enviando..." : "Enviar")
                        .bold()
                    Spacer()
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isSending || subject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .padding([.horizontal, .bottom])
        }
        .sheet(isPresented: $showMailComposer, onDismiss: { isSending = false }) {
            MailView(recipients: [supportEmail], subject: subject, body: message) { result in
                isSending = false
                switch result {
                case .sent:
                    alertMessage = "Tu mensaje ha sido enviado. ¡Gracias por contactarnos!"
                case .saved:
                    alertMessage = "Borrador guardado en Mail."
                case .failed:
                    alertMessage = "No se pudo enviar el correo. Inténtalo de nuevo."
                case .cancelled:
                    alertMessage = "Envío cancelado."
                @unknown default:
                    alertMessage = "Estado desconocido."
                }
                showAlert = true
                subject = ""
                message = ""
            }
        }
        .alert("", isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
        .alert("No se puede enviar correo", isPresented: $showMailFallbackAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Configura una cuenta de correo en la app Mail o inténtalo con otra app de correo.")
        }
    }

    private func send() {
        guard !isSending else { return }
        let trimmedSubject = subject.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedMessage = message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedSubject.isEmpty, !trimmedMessage.isEmpty else {
            alertMessage = "Por favor completa asunto y mensaje."
            showAlert = true
            return
        }
        isSending = true

        if MFMailComposeViewController.canSendMail() {
            showMailComposer = true
        } else {
            // Fallback: intentar abrir mailto:
            let subjectEncoded = trimmedSubject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            let bodyEncoded = trimmedMessage.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            let mailtoString = "mailto:\(supportEmail)?subject=\(subjectEncoded)&body=\(bodyEncoded)"
            if let url = URL(string: mailtoString) {
                UIApplication.shared.open(url) { success in
                    isSending = false
                    if !success {
                        showMailFallbackAlert = true
                    } else {
                        alertMessage = "Abriendo tu app de correo para enviar el mensaje."
                        showAlert = true
                        subject = ""
                        message = ""
                    }
                }
            } else {
                isSending = false
                showMailFallbackAlert = true
            }
        }
    }
}

struct MailView: UIViewControllerRepresentable {
    typealias UIViewControllerType = MFMailComposeViewController

    let recipients: [String]
    let subject: String
    let body: String
    let completion: (MFMailComposeResult) -> Void

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        vc.setToRecipients(recipients)
        vc.setSubject(subject)
        vc.setMessageBody(body, isHTML: false)
        vc.mailComposeDelegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let parent: MailView
        init(_ parent: MailView) { self.parent = parent }
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            controller.dismiss(animated: true) {
                self.parent.completion(result)
            }
        }
    }
}

struct SupportView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SupportView()
        }
    }
}
