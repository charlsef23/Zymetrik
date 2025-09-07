import SwiftUI

struct CommentsComposerBar: View {
    let placeholder: String
    @Binding var text: String
    var isSending: Bool
    var onSend: () -> Void
    var onCancelReply: () -> Void
    var showCancelReply: Bool

    @State private var dynamicHeight: CGFloat = 38

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if showCancelReply {
                HStack {
                    Text("Respondiendo…").font(.caption)
                    Spacer()
                    Button("Cancelar", action: onCancelReply).font(.caption)
                }
                .foregroundStyle(.secondary)
            }
            HStack(alignment: .bottom, spacing: 8) {
                GrowingTextEditor(
                    text: $text,
                    minHeight: 38,
                    maxHeight: 120,
                    placeholder: placeholder,
                    height: $dynamicHeight
                )
                Button {
                    onSend()
                } label: {
                    if isSending {
                        ProgressView()
                    } else {
                        Image(systemName: "paperplane.fill")
                    }
                }
                .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending)
            }
        }
    }
}
