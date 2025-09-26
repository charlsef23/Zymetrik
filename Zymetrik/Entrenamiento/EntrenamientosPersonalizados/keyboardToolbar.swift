// Zymetrik/Entrenamiento/EntrenamientosPersonalizados/keyboardToolbar.swift
import SwiftUI

/// Accesorio de teclado sencillo que muestra un “pill” con el nombre de la rutina activa.
/// Úsalo así:
/// .keyboardToolbarCompat(routine.activePlanName) { /* abrir acciones */ }
extension View {
    @ViewBuilder
    func keyboardToolbarCompat(
        _ title: String?,
        onTap: @escaping () -> Void
    ) -> some View {
        // iOS 16+ tiene placement .keyboard estable
        if #available(iOS 16.0, *) {
            self.toolbar {
                if let title, !title.isEmpty {
                    ToolbarItem(placement: .keyboard) {
                        RoutineKeyboardBar(title: title, onTap: onTap)
                    }
                }
            }
        } else {
            // iOS 15 o anterior: no hay placement .keyboard → no añadimos nada
            self
        }
    }
}

struct RoutineKeyboardBar: View {
    let title: String
    let onTap: () -> Void

    var body: some View {
        HStack {
            Spacer()
            Button(action: onTap) {
                HStack(spacing: 8) {
                    Image(systemName: "figure.strengthtraining.traditional")
                    Text(title)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule().fill(Color(.secondarySystemBackground))
                )
            }
        }
        .padding(.horizontal)
    }
}
