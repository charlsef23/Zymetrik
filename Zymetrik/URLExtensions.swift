// URLExtensions.swift
import Foundation

extension URL {
    var isVideo: Bool {
        let videoExtensions = ["mp4", "mov", "m4v"]
        return videoExtensions.contains(self.pathExtension.lowercased())
    }
}
