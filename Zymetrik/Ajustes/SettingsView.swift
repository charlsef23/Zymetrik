import SwiftUI

struct SettingsView: View {
    @State private var isPrivateAccount = false
    @State private var notifyWorkoutReminder = true
    @State private var notifyFollowers = true
    @State private var notifyLikes = true
    @State private var notifyComments = true
    @State private var notifyShares = true
    @State private var showNotifications = false

    var body: some View {
        NavigationStack {
            List {
                // Perfil
                Section("Perfil") {
                    HStack {
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 50, height: 50)
                            .overlay(Image(systemName: "person.fill").foregroundColor(.black))

                        VStack(alignment: .leading) {
                            Text("Carlos Esteve")
                                .font(.headline)
                            Text("@carlos")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        Button(action: {}) {
                            Text("Editar")
                        }
                    }
                }

                // Privacidad
                Section("Privacidad") {
                    Toggle("Cuenta privada", isOn: $isPrivateAccount)
                    NavigationLink("Solicitudes de seguimiento") {
                        Text("Solicitudes pendientes")
                    }
                }

                // Notificaciones (acceso)
                Section {
                    NavigationLink("Notificaciones") {
                        List {
                            Section("Notificaciones") {
                                Toggle("Recordatorios para entrenar", isOn: $notifyWorkoutReminder)
                                Toggle("Nuevos seguidores", isOn: $notifyFollowers)
                                Toggle("Me gusta (fuerza)", isOn: $notifyLikes)
                                Toggle("Comentarios", isOn: $notifyComments)
                                Toggle("Compartidos", isOn: $notifyShares)
                            }
                        }
                        .navigationTitle("Notificaciones")
                    }
                }

                // Contenido
                Section("Contenido") {
                    NavigationLink("Preferencias de visualización") {
                        Text("Aquí irán las opciones de tema, diseño, etc.")
                    }
                    NavigationLink("Idioma") {
                        Text("Selecciona el idioma")
                    }
                }

                // Salud
                Section("Salud") {
                    Button("Conectar con Apple Health") {}
                }

                // Membresía
                Section("Membresía") {
                    HStack {
                        Text("Plan actual")
                        Spacer()
                        Text("Gratuito")
                            .foregroundColor(.gray)
                    }
                    Button("Ver planes y suscribirme") {}
                }

                // Soporte
                Section("Soporte") {
                    Button("Enviar feedback") {}
                    Button("Contactar con soporte") {}
                    Button("FAQ") {}
                }

                // Cuenta
                Section("Cuenta") {
                    Button("Cerrar sesión", role: .destructive) {}
                    Button("Eliminar cuenta", role: .destructive) {}
                }
            }
            .navigationTitle("Ajustes")
        }
    }
}

#Preview {
    SettingsView()
}
