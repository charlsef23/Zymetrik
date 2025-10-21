import Foundation
import SwiftUI

@MainActor
final class BlockStore: ObservableObject {
    @Published var blocked: [BlockedUser] = []
    @Published var count: Int = 0
    @Published var isLoading = false
    @Published var error: String?

    func reload() async {
        isLoading = true
        error = nil
        do {
            async let list = BlockService.shared.listBlocked()
            async let c = BlockService.shared.countBlocked()
            let (l, n) = try await (list, c)
            self.blocked = l
            self.count = n
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func refreshCount() async {
        do { self.count = try await BlockService.shared.countBlocked() }
        catch { self.error = error.localizedDescription }
    }

    func unblock(id: String) async {
        do {
            try await BlockService.shared.unblock(targetUserID: id)

            // ✅ Convertir String a UUID antes de comparar
            if let uuid = UUID(uuidString: id),
               let idx = blocked.firstIndex(where: { $0.id == uuid }) {
                blocked.remove(at: idx)
            }

            count = max(0, count - 1)
        } catch {
            self.error = error.localizedDescription
        }
    }
}
