import Foundation

/// Llama a esto cuando recibes un push de OneSignal.
/// Espera payload con `data.type == "dm"` y `data.chat_id`.
enum PushRouter {
    static func handleOneSignalPayload(
        _ payload: [AnyHashable: Any],
        routeToDM: (UUID) -> Void
    ) {
        guard
            let data = payload["data"] as? [String: Any],
            let type = data["type"] as? String, type == "dm",
            let chatIDString = data["chat_id"] as? String,
            let chatID = UUID(uuidString: chatIDString)
        else { return }

        routeToDM(chatID)
    }
}
