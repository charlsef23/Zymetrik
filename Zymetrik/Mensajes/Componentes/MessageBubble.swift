import SwiftUI

struct MessageBubble: View {
    let message: DMMessage
    let isMine: Bool
    let seenByOther: Bool

    var onEdit: (String) -> Void
    var onDeleteForAll: () -> Void
    var onDeleteForMe: () -> Void

    @State private var editing = false
    @State private var draft = ""

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isMine { Spacer(minLength: 40) }

            VStack(alignment: .leading, spacing: 4) {
                Text(message.content + (message.edited_at != nil ? " (editado)" : ""))
                    .font(.body)
                    .padding(10)
                    .background(isMine ? Color.blue.opacity(0.15) : Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .contextMenu {
                        if isMine {
                            Button("Editar") {
                                draft = message.content
                                editing = true
                            }
                            Button("Eliminar para todos", role: .destructive) { onDeleteForAll() }
                        }
                        Button("Eliminar para mí", role: .destructive) { onDeleteForMe() }
                    }

                HStack(spacing: 6) {
                    Text(timeString(message.created_at))
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    if isMine {
                        Image(systemName: seenByOther ? "checkmark.circle.fill" : "checkmark")
                            .font(.caption2)
                            .foregroundStyle(seenByOther ? .blue : .secondary)
                            .accessibilityLabel(seenByOther ? "Visto" : "Enviado")
                    }
                }
                .padding(.leading, 6)
            }

            if !isMine { Spacer(minLength: 40) }
        }
        .padding(.vertical, 2)
        .sheet(isPresented: $editing) {
            NavigationStack {
                VStack {
                    TextEditor(text: $draft)
                        .padding()
                        .frame(minHeight: 150)
                    Spacer()
                }
                .navigationTitle("Editar mensaje")
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Cancelar") { editing = false }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Guardar") {
                            onEdit(draft.trimmingCharacters(in: .whitespacesAndNewlines))
                            editing = false
                        }
                        .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
        }
    }

    private func timeString(_ date: Date) -> String {
        let f = DateFormatter()
        f.timeStyle = .short
        f.dateStyle = .none
        return f.string(from: date)
    }
}
