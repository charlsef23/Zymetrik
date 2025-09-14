import SwiftUI

public struct SearchField: View {
    let placeholder: String
    @Binding var text: String
    var bottomSpacing: CGFloat = 8

    public init(placeholder: String, text: Binding<String>, bottomSpacing: CGFloat = 8) {
        self.placeholder = placeholder
        self._text = text
        self.bottomSpacing = bottomSpacing
    }

    public var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)

            TextField(placeholder, text: $text)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)

            if !text.isEmpty {
                Button { text = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
                .accessibilityLabel("Borrar búsqueda")
            }
        }
        .padding(.vertical, 12) // ↑ más alto
        .padding(.horizontal, 12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, bottomSpacing) // ← gap extra
    }
}
