import SwiftUI

struct ConversationRow: View {
    let item: DMInboxItem
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                ZStack(alignment: .bottomTrailing) {
                    AvatarAsyncImage(
                        url: URL(string: item.otherPerfil?.avatar_url ?? ""),
                        size: 56
                    )
                    .clipShape(Circle())

                    if item.isOnline {
                        Circle()
                            .fill(.green)
                            .frame(width: 14, height: 14)
                            .overlay(Circle().stroke(.background, lineWidth: 3))
                            .offset(x: 2, y: 2)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(item.otherPerfil?.username ?? "Conversación")
                            .font(.system(size: 17, weight: item.unreadCount > 0 ? .bold : .semibold))
                            .foregroundColor(.primary)
                            .lineLimit(1)

                        if item.isMuted {
                            Label("Silenciado", systemImage: "bell.slash.fill")
                                .labelStyle(.iconOnly)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.secondary)
                                .padding(.leading, 4)
                                .accessibilityLabel("Silenciado")
                        }

                        Spacer()

                        if let date = item.lastAt {
                            Text(shortDate(date))
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                    }

                    HStack(alignment: .center, spacing: 8) {
                        // Punto de no leído
                        if item.unreadCount > 0 {
                            Circle()
                                .fill(.blue)
                                .frame(width: 8, height: 8)
                                .transition(.scale.combined(with: .opacity))
                        }

                        Text(item.lastMessagePreview ?? "Toca para escribir...")
                            .font(.system(size: 15, weight: item.unreadCount > 0 ? .semibold : .regular))
                            .foregroundStyle(item.lastMessagePreview != nil ? .secondary : .tertiary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)

                        Spacer()

                        if item.unreadCount > 0 {
                            Text("\(item.unreadCount)")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    LinearGradient(colors: [.blue, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing)
                                )
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(.white.opacity(0.25), lineWidth: 1))
                                .frame(minWidth: 28)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .buttonStyle(ScaledButtonStyle())
    }

    private func shortDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = .current
        f.doesRelativeDateFormatting = true

        if Calendar.current.isDateInToday(date) {
            f.timeStyle = .short
            f.dateStyle = .none
        } else if Calendar.current.isDate(date, equalTo: Date(), toGranularity: .weekOfYear) {
            f.dateFormat = "EEEE"
        } else {
            f.dateStyle = .short
            f.timeStyle = .none
        }
        return f.string(from: date)
    }
}

// Botón con pequeño “tap” scale
struct ScaledButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.08), value: configuration.isPressed)
    }
}

// Botón primario capsulado reutilizable
struct PrimaryCapsuleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                LinearGradient(colors: [.blue, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .shadow(color: .blue.opacity(0.25), radius: 12, x: 0, y: 6)
            .clipShape(Capsule())
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.08), value: configuration.isPressed)
    }
}
