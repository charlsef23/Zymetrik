import Foundation
import Supabase

class SupabaseManager {
    static let shared = SupabaseManager()

    let client: SupabaseClient

    private init() {
        self.client = SupabaseClient(
            supabaseURL: URL(string: "https://eolcdkdqsoxkiaxmdgrv.supabase.co")!,
            supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVvbGNka2Rxc294a2lheG1kZ3J2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDY2OTkxNzEsImV4cCI6MjA2MjI3NTE3MX0.bCXrVgjqQKWsNM3yqn7fDHa1fYJ1SlJ5Wi-LNh9ZRRE"
        )
    }
}
