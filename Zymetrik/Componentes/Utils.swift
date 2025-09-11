// Utils.swift
import Foundation

extension String {
    /// Devuelve una URL http(s) válida o nil si la cadena es vacía, "n/a", etc.
    var validHTTPURL: URL? {
        let s = self.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !s.isEmpty, s.lowercased() != "n/a",
              let u = URL(string: s),
              let scheme = u.scheme?.lowercased(),
              scheme == "http" || scheme == "https"
        else { return nil }
        return u
    }
}

extension Optional where Wrapped == String {
    /// Delegamos en la versión para String para soportar tanto String? como String
    var validHTTPURL: URL? {
        switch self {
        case .some(let s): return s.validHTTPURL
        case .none: return nil
        }
    }
}
