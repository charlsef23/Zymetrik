import Supabase

struct AccountDeletionService {
    let client = SupabaseManager.shared.client

    func deleteUserFiles(userId: String) async throws {
        // Ajusta nombres de buckets y rutas a tu estructura real:
        let buckets = ["avatars", "post-media"]
        for bucket in buckets {
            // Lista por prefijo (requiere política RLS de SELECT para listar)
            let list = try await client.storage
                .from(bucket)
                .list(path: userId, options: .init(limit: 1000, offset: 0, search: nil))

            // Borra en lote (requiere política RLS de DELETE y normalmente también SELECT)
            let paths = list.map { "\(userId)/\($0.name)" }
            if !paths.isEmpty {
                _ = try await client.storage.from(bucket).remove(paths: paths)
            }
        }
    }
}
