import SwiftUI
import Supabase

struct SettingsView: View {
    @State private var mostrarShare = false
    @State private var esAdmin = false

    private var client: SupabaseClient { SupabaseManager.shared.client }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // MARK: - Zymetrik
                    SettingsSectionCard(
                        title: "Zymetrik",
                        items: [
                            .init(icon: "bookmark.fill", tint: .blue, title: "Guardados", destination: AnyView(GuardadosView())),
                            .init(icon: "bell.fill", tint: .orange, title: "Notificaciones", destination: AnyView(Text("NotificacionesView()")))
                        ]
                    )

                    // MARK: - Privacidad
                    SettingsSectionCard(
                        title: "Quién puede ver tu contenido",
                        items: [
                            .init(icon: "lock.fill", tint: .purple, title: "Privacidad de la cuenta", trailing: "Privada", destination: AnyView(Text("PrivacidadView()"))),
                            .init(icon: "hand.raised.fill", tint: .red, title: "Cuentas bloqueadas", trailing: "4", destination: AnyView(CuentasBloqueadasView()))
                        ]
                    )

                    // MARK: - Interacciones
                    SettingsSectionCard(
                        title: "Cómo pueden interactuar contigo los demás",
                        items: [
                            .init(icon: "message.fill", tint: .green, title: "Mensajes", destination: AnyView(Text("MensajesView()")))
                        ]
                    )

                    // MARK: - Soporte
                    SettingsSectionCard(
                        title: "Soporte",
                        items: [
                            .init(icon: "envelope.fill", tint: .teal, title: "Enviar feedback", destination: AnyView(FeedbackView())),
                            .init(icon: "questionmark.circle.fill", tint: .indigo, title: "Contactar con soporte", destination: AnyView(Text("SoporteView()"))),
                            .init(icon: "book.fill", tint: .brown, title: "FAQ", destination: AnyView(Text("FAQView()")))
                        ]
                    )
                    
                    // MARK: - Administración (solo admins)
                    if esAdmin {
                        SettingsSectionCard(
                            title: "Administración",
                            items: [
                                .init(
                                    icon: "tray.full.fill",
                                    tint: .cyan,
                                    title: "Feedback (Admin)",
                                    destination: AnyView(AdminFeedbackListView())
                                ),
                                .init(
                                    icon: "person.crop.circle.badge.exclam",
                                    tint: .red,
                                    title: "Moderación",
                                    destination: AnyView(Text("ModeracionView()")) // ⬅️ placeholder
                                ),
                                .init(
                                    icon: "chart.bar.fill",
                                    tint: .orange,
                                    title: "Métricas",
                                    destination: AnyView(Text("MetricasView()")) // ⬅️ placeholder
                                ),
                                .init(
                                    icon: "lock.doc.fill",
                                    tint: .purple,
                                    title: "Policies & RLS",
                                    destination: AnyView(Text("PoliciesView()")) // ⬅️ placeholder
                                )
                            ]
                        )
                    }

                    // MARK: - Cuenta
                    SettingsSectionCard(
                        title: "Cuenta",
                        items: [
                            .init(icon: "rectangle.portrait.and.arrow.forward", tint: .gray, title: "Cerrar sesión", destination: AnyView(Text("CerrarSesionView()"))),
                            .init(icon: "trash.fill", tint: .red, title: "Eliminar cuenta", destination: AnyView(Text("EliminarCuentaView()")))
                        ]
                    )
                }
                .padding(.vertical, 16)
                .padding(.horizontal)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Configuración")
            .sheet(isPresented: $mostrarShare) {
                ShareProfileView(username: "carlos", profileImage: Image("foto_perfil"))
            }
            .task {
                await cargarEsAdmin()
            }
        }
    }

    // MARK: - Helpers
    private func cargarEsAdmin() async {
        do {
            let user = try await client.auth.session.user

            let resp = try await client
                .from("perfil")
                .select("es_admin", head: false)
                .eq("id", value: user.id.uuidString)
                .limit(1)
                .execute()

            struct Row: Decodable { let es_admin: Bool }

            // En tu SDK, resp.data es Data (no opcional)
            let data = resp.data
            let rows = try JSONDecoder().decode([Row].self, from: data)
            esAdmin = rows.first?.es_admin ?? false

        } catch {
            print("Error cargando es_admin:", error.localizedDescription)
            esAdmin = false
        }
    }
}
// MARK: - Models

struct SettingsItem: Identifiable {
    let id = UUID()
    let icon: String
    let tint: Color
    let title: String
    var trailing: String? = nil
    let destination: AnyView
}

// MARK: - Components

struct SettingsSectionCard: View {
    let title: String
    let items: [SettingsItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 2)

            VStack(spacing: 0) {
                ForEach(items.indices, id: \.self) { i in
                    let item = items[i]
                    NavigationLink {
                        item.destination
                    } label: {
                        SettingsRow(
                            icon: item.icon,
                            tint: item.tint,
                            title: item.title,
                            trailing: item.trailing,
                            isFirst: i == 0,
                            isLast: i == items.count - 1
                        )
                    }
                    .buttonStyle(.plain)

                    if i < items.count - 1 {
                        Divider().padding(.leading, 56)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.black.opacity(0.04))
            )
            .shadow(color: .black.opacity(0.04), radius: 12, x: 0, y: 6)
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let tint: Color
    let title: String
    let trailing: String?
    let isFirst: Bool
    let isLast: Bool

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(tint.opacity(0.15))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(tint)
            }
            .accessibilityHidden(true)

            Text(title)
                .foregroundStyle(.primary)

            Spacer(minLength: 8)

            if let trailing {
                Text(trailing)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .clipShape(RoundedCorner(radius: 16, corners: roundedCorners))
    }

    private var roundedCorners: UIRectCorner {
        switch (isFirst, isLast) {
        case (true, true): return [.allCorners]
        case (true, false): return [.topLeft, .topRight]
        case (false, true): return [.bottomLeft, .bottomRight]
        default: return []
        }
    }
}

// MARK: - Helpers

struct RoundedCorner: Shape {
    var radius: CGFloat = 12
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}


