// CrearPostEntrenamientoView.swift (versión final refinada con mejoras visuales aplicadas)
import SwiftUI
import PhotosUI
import AVKit

struct CrearPostEntrenamientoView: View {
    @Environment(\.dismiss) var dismiss

    var sesiones: [SesionEntrenamiento]
    var username: String
    var onPost: (SesionEntrenamiento, URL?) -> Void

    @State private var sesionIDSeleccionada: UUID?
    @State private var sesionSeleccionada: SesionEntrenamiento?
    @State private var selectedItem: PhotosPickerItem?
    @State private var mediaURL: URL? = nil
    @State private var previewImage: Image? = nil
    @State private var videoDurationExceeded = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Picker sesión
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .foregroundColor(.gray)
                        Text("Entrenamiento")
                            .font(.headline)
                    }
                    .padding(.horizontal)

                    Picker("Sesión", selection: $sesionIDSeleccionada) {
                        ForEach(sesiones.sorted(by: { $0.fecha > $1.fecha }), id: \ .id) { sesion in
                            Text(sesion.titulo + " - " + formatearFecha(sesion.fecha))
                                .tag(sesion.id)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .onChange(of: sesionIDSeleccionada) { _, nuevoID in
                        sesionSeleccionada = sesiones.first(where: { $0.id == nuevoID })
                    }
                }

                // Multimedia
                VStack(spacing: 12) {
                    PhotosPicker(selection: $selectedItem, matching: .any(of: [.images, .videos])) {
                        HStack(spacing: 8) {
                            Image(systemName: "photo")
                            Text(mediaURL == nil ? "Añadir imagen o video" : "Cambiar archivo")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }

                    if let url = mediaURL {
                        if url.isVideo {
                            if videoDurationExceeded {
                                Text("⚠️ Video demasiado largo").foregroundColor(.red)
                            } else {
                                VideoPlayer(player: AVPlayer(url: url))
                                    .frame(height: 220)
                                    .cornerRadius(12)
                                    .padding(.horizontal)
                                    .background(Color(.systemGray5))
                                    .cornerRadius(16)
                            }
                        } else {
                            previewImage?
                                .resizable()
                                .scaledToFill()
                                .frame(height: 220)
                                .clipped()
                                .cornerRadius(12)
                                .padding(.horizontal)
                        }
                    }
                }

                // Resumen
                if let sesionSeleccionada {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Image(systemName: "list.bullet")
                                .foregroundColor(.gray)
                            Text("Resumen")
                                .font(.headline)
                        }
                        Text("\(sesionSeleccionada.ejercicios.count) ejercicios")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }

                // Botón publicar
                Button(action: {
                    if let sesion = sesionSeleccionada {
                        onPost(sesion, mediaURL)
                        dismiss()
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "paperplane.fill")
                        Text("Publicar entrenamiento")
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(sesionSeleccionada == nil ? Color.gray : Color.black)
                    .foregroundColor(.white)
                    .cornerRadius(14)
                }
                .padding(.horizontal)
                .disabled(sesionSeleccionada == nil)
            }
            .padding(.top)
            .navigationTitle("Post de Entreno")
            .onAppear {
                if let primera = sesiones.sorted(by: { $0.fecha > $1.fecha }).first {
                    sesionIDSeleccionada = primera.id
                    sesionSeleccionada = primera
                }
            }
            .onChange(of: selectedItem) { _, newItem in
                Task {
                    guard let item = newItem else { return }

                    if let url = try? await item.loadTransferable(type: URL.self) {
                        mediaURL = url
                        if url.isVideo {
                            checkVideoDuration(url)
                        } else if let data = try? Data(contentsOf: url),
                                  let uiImage = UIImage(data: data) {
                            previewImage = Image(uiImage: uiImage)
                        }
                    }
                }
            }
        }
    }

    private func formatearFecha(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_ES")
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    private func checkVideoDuration(_ url: URL) {
        Task {
            let asset = AVAsset(url: url)
            do {
                let duration = try await asset.load(.duration)
                let durationInSeconds = CMTimeGetSeconds(duration)
                videoDurationExceeded = durationInSeconds > 60
            } catch {
                videoDurationExceeded = false
            }
        }
    }
}
