import SwiftUI

struct ShareOptionsView: View {
    let onSystemShare: () -> Void
    let onWhatsApp: () -> Void
    let onInstagram: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Compartir")
                .font(.headline)
                .padding(.top, 12)

            VStack(spacing: 12) {
                Button {
                    onSystemShare()
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Hoja de compartir (iOS)")
                        Spacer()
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)

                Button {
                    onWhatsApp()
                } label: {
                    HStack {
                        Image(systemName: "message.circle.fill")
                        Text("WhatsApp")
                        Spacer()
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)

                Button {
                    onInstagram()
                } label: {
                    HStack {
                        Image(systemName: "camera.viewfinder")
                        Text("Instagram Stories")
                        Spacer()
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }

            Spacer(minLength: 8)
        }
        .padding()
    }
}
