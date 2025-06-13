import SwiftUI

struct SeleccionCarpetaView: View {
    let post: EntrenamientoPost
    @Binding var isPresented: Bool

    @ObservedObject var guardados = GuardadosManager.shared
    @State private var nombreNuevaCarpeta = ""

    var body: some View {
        VStack(spacing: 0) {
            // Título
            Text("Guardar en carpeta")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.black)
                .padding(.top, 12)

            // Lista de carpetas
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(guardados.carpetas) { carpeta in
                        Button {
                            guardados.añadir(post: post, a: carpeta)
                            isPresented = false
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "folder.fill")
                                    .foregroundColor(.yellow)
                                    .font(.system(size: 20))

                                Text(carpeta.nombre)
                                    .foregroundColor(.black)
                                    .font(.system(size: 16))

                                Spacer()

                                if carpeta.posts.contains(post) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }

                    if guardados.carpetas.isEmpty {
                        Text("No tienes carpetas todavía.")
                            .foregroundColor(.gray)
                            .padding(.top, 30)
                    }
                }
                .padding(.top, 8)
            }
            .frame(maxHeight: 220)

            Divider()
                .padding(.top, 12)

            // Crear nueva carpeta
            VStack(spacing: 12) {
                Text("Crear nueva carpeta")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.black)

                HStack {
                    TextField("Nombre de la carpeta", text: $nombreNuevaCarpeta)
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)

                    Button(action: {
                        let nombre = nombreNuevaCarpeta.trimmingCharacters(in: .whitespaces)
                        if !nombre.isEmpty {
                            let nueva = guardados.crearCarpeta(nombre: nombre)
                            guardados.añadir(post: post, a: nueva)
                            nombreNuevaCarpeta = ""
                            isPresented = false
                        }
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.black)
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.top, 12)

            Spacer(minLength: 12)
        }
        .padding(.bottom, 20)
        .background(Color.white)
        .cornerRadius(30)
        .presentationDetents([.fraction(0.35)])
        .presentationDragIndicator(.visible)
    }
}
