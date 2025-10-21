import SwiftUI
import Supabase

struct SettingsView: View {
    // 🔗 Store global de bloqueos (para el trailing en “Cuentas bloqueadas”)
    @EnvironmentObject private var blockStore: BlockStore

    @State private var mostrarShare = false
    @State private var esAdmin = false

    // Estados para Cuenta
    @State private var mostrandoConfirmCerrarSesion = false
    @State private var cerrandoSesion = false
    @State private var mostrandoConfirmEliminar = false
    @State private var eliminandoCuenta = false
    @State private var errorCuenta: String?

    // Estados para Entrenamiento (borrado de futuros)
    @State private var confirmDeleteFuture = false
    @State private var deletingFuture = false
    @State private var deleteResultMessage: String?
    @State private var showDeleteResult = false

    private var client: SupabaseClient { SupabaseManager.shared.client }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // MARK: - Zymetrik
                    SettingsSectionCard(
                        title: "Zymetrik",
                        items: [
                            .init(icon: "bookmark.fill", tint: .blue,   title: "Guardados",      destination: AnyView(GuardadosView())),
                            .init(icon: "bell.fill",     tint: .orange, title: "Notificaciones", destination: AnyView(NotificationsSettingsView()))
                        ]
                    )

                    // MARK: - Privacidad
                    SettingsSectionCard(
                        title: "Quién puede ver tu contenido",
                        items: [
                            .init(
                                icon: "hand.raised.fill",
                                tint: .red,
                                title: "Cuentas bloqueadas",
                                trailing: "\(blockStore.count)",     // ← sincronizado con el store
                                destination: AnyView(BlockedUsersView())
                            )
                        ]
                    )

                    // MARK: - Entrenamiento
                    SettingsSectionCard(
                        title: "Entrenamiento",
                        items: [
                            .init(
                                icon: "trash.circle.fill",
                                tint: .red,
                                title: deletingFuture ? "Eliminando entrenamientos futuros…" : "Eliminar entrenamientos futuros",
                                destination: nil,
                                onTap: { confirmDeleteFuture = true }
                            )
                        ]
                    )

                    // MARK: - Soporte
                    SettingsSectionCard(
                        title: "Soporte",
                        items: [
                            .init(icon: "envelope.fill",             tint: .teal,   title: "Enviar feedback",        destination: AnyView(FeedbackView())),
                            .init(icon: "questionmark.circle.fill",  tint: .indigo, title: "Contactar con soporte",  destination: AnyView(SupportView())),
                            .init(icon: "book.fill",                 tint: .brown,  title: "FAQ",                    destination: AnyView(FAQView())),
                            .init(icon: "lock.doc.fill",             tint: .purple, title: "Política de privacidad", destination: AnyView(PrivacyPolicyView()))
                        ]
                    )

                    // MARK: - Administración (solo admins)
                    if esAdmin {
                        SettingsSectionCard(
                            title: "Administración",
                            items: [
                                .init(icon: "exclamationmark.bubble.fill", tint: .green,  title: "Reportes de posts",   destination: AnyView(AdminPostReportsView())),
                                .init(icon: "tray.full.fill",               tint: .cyan,   title: "Feedback (Admin)",     destination: AnyView(AdminFeedbackListView())),
                                .init(icon: "person.crop.circle.badge.exclam", tint: .red, title: "Moderación",        destination: AnyView(Text("ModeracionView()"))),
                                .init(icon: "chart.bar.fill",               tint: .orange, title: "Métricas",           destination: AnyView(Text("MetricasView()")))
                            ]
                        )
                    }

                    // MARK: - Cuenta
                    SettingsSectionCard(
                        title: "Cuenta",
                        items: [
                            .init(
                                icon: "rectangle.portrait.and.arrow.forward",
                                tint: .gray,
                                title: cerrandoSesion ? "Cerrando sesión…" : "Cerrar sesión",
                                destination: nil,
                                onTap: { mostrandoConfirmCerrarSesion = true }
                            ),
                            .init(
                                icon: "trash.fill",
                                tint: .red,
                                title: eliminandoCuenta ? "Eliminando…" : "Eliminar cuenta",
                                destination: nil,
                                onTap: { mostrandoConfirmEliminar = true }
                            )
                        ]
                    )

                    if let errorCuenta {
                        Text(errorCuenta)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .padding(.horizontal)
                    }
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
                // Carga rol admin y, de paso, sincroniza el contador de bloqueados
                await cargarEsAdmin()
                await blockStore.reload()
            }

            // MARK: - Confirmación cerrar sesión
            .confirmationDialog(
                "¿Cerrar sesión?",
                isPresented: $mostrandoConfirmCerrarSesion,
                titleVisibility: .visible
            ) {
                Button(cerrandoSesion ? "Cerrando…" : "Cerrar sesión", role: .destructive) {
                    cerrarSesion()
                }
                .disabled(cerrandoSesion)
                Button("Cancelar", role: .cancel) {}
            } message: {
                Text("Se cerrará tu sesión en este dispositivo.")
            }

            // MARK: - Confirmación eliminar cuenta
            .confirmationDialog(
                "¿Eliminar tu cuenta?",
                isPresented: $mostrandoConfirmEliminar,
                titleVisibility: .visible
            ) {
                Button(eliminandoCuenta ? "Eliminando…" : "Eliminar definitivamente", role: .destructive) {
                    eliminarCuenta()
                }
                .disabled(eliminandoCuenta)
                Button("Cancelar", role: .cancel) {}
            } message: {
                Text("Se eliminarán tu perfil y todos tus datos. Esta acción no se puede deshacer.")
            }

            // MARK: - Confirmación eliminar entrenamientos futuros
            .confirmationDialog(
                "¿Eliminar todos los entrenamientos futuros?",
                isPresented: $confirmDeleteFuture,
                titleVisibility: .visible
            ) {
                Button(deletingFuture ? "Eliminando…" : "Eliminar", role: .destructive) {
                    Task { await deleteFutureWorkouts() }
                }
                .disabled(deletingFuture)
                Button("Cancelar", role: .cancel) {}
            } message: {
                Text("Se eliminarán todos los entrenamientos planificados a partir de mañana. Esta acción no se puede deshacer.")
            }

            // Resultado del borrado
            .alert("Listo", isPresented: $showDeleteResult) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(deleteResultMessage ?? "Proceso completado.")
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
            let rows = try JSONDecoder().decode([Row].self, from: resp.data)
            esAdmin = rows.first?.es_admin ?? false
        } catch {
            print("Error cargando es_admin:", error.localizedDescription)
            esAdmin = false
        }
    }

    // MARK: - Cuenta: Cerrar sesión
    private func cerrarSesion() {
        guard !cerrandoSesion else { return }
        cerrandoSesion = true
        errorCuenta = nil

        Task {
            do {
                try await client.auth.signOut()
            } catch {
                await MainActor.run { errorCuenta = "No se pudo cerrar sesión: \(error.localizedDescription)" }
            }
            await MainActor.run { cerrandoSesion = false }
        }
    }

    // MARK: - Cuenta: Eliminar cuenta
    private func eliminarCuenta() {
        guard !eliminandoCuenta else { return }
        eliminandoCuenta = true
        errorCuenta = nil

        Task {
            do {
                let user = try await client.auth.session.user
                let uid = user.id.uuidString

                // 1) Borra ficheros del usuario (si los tienes)
                do {
                    try await AccountDeletionService().deleteUserFiles(userId: uid)
                } catch {
                    print("⚠️ No se pudieron borrar todos los ficheros: \(error)")
                }

                // 2) RPC backend para borrar cuenta y datos
                _ = try await client
                    .rpc("delete_my_account")
                    .execute()

                // 3) Cierra sesión local
                try? await client.auth.signOut()
            } catch {
                await MainActor.run {
                    self.errorCuenta = "No se pudo eliminar la cuenta: \(error.localizedDescription)"
                }
            }
            await MainActor.run { self.eliminandoCuenta = false }
        }
    }

    // MARK: - Entrenamiento: Eliminar entrenamientos futuros
    private func deleteFutureWorkouts() async {
        guard !deletingFuture else { return }
        deletingFuture = true
        defer { deletingFuture = false }

        do {
            let res = try await SupabaseService.shared.deleteFutureWorkouts()
            let plans  = res?.deleted_plans ?? 0
            let days   = res?.deleted_routine_days ?? 0
            let canc   = res?.canceled_routines ?? 0

            deleteResultMessage = """
            Eliminados \(plans) planes diarios, \(days) días de rutina y canceladas \(canc) rutinas.
            """
        } catch {
            deleteResultMessage = "No se pudo completar la eliminación: \(error.localizedDescription)"
        }
        showDeleteResult = true
    }
}

// MARK: - UI genérica usada arriba

struct SettingsItem: Identifiable {
    let id = UUID()
    let icon: String
    let tint: Color
    let title: String
    var trailing: String? = nil
    let destination: AnyView?
    var onTap: (() -> Void)? = nil

    init(icon: String, tint: Color, title: String, trailing: String? = nil, destination: AnyView? = nil, onTap: (() -> Void)? = nil) {
        self.icon = icon
        self.tint = tint
        self.title = title
        self.trailing = trailing
        self.destination = destination
        self.onTap = onTap
    }
}

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
                    Group {
                        if let dest = item.destination {
                            NavigationLink { dest } label: {
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
                        } else {
                            Button {
                                item.onTap?()
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
                        }
                    }

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
                .opacity( (trailing != nil) ? 1 : 0 ) // muestra chevron cuando hay destino
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
