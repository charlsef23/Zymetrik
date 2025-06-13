import SwiftUI

struct GuardadosView: View {
    @ObservedObject var guardados = GuardadosManager.shared

    @State private var mostrarCrearCarpeta = false
    @State private var mostrarEditarCarpeta = false
    @State private var nuevoNombreCarpeta = ""
    @State private var nombreEditado = ""
    @State private var carpetaSeleccionada: CarpetaGuardado? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // Sección general
                    if !guardados.postsGuardados.isEmpty {
                        Text("Todos los guardados")
                            .font(.headline)
                            .foregroundColor(.black)
                            .padding(.horizontal)

                        ForEach(guardados.postsGuardados, id: \.id) { post in
                            PostView(post: post)
                        }
                    }

                    // Si no hay nada
                    if guardados.postsGuardados.isEmpty && guardados.carpetas.isEmpty {
                        Text("No tienes ningún post guardado.")
                            .foregroundColor(.gray)
                            .padding(.top, 40)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }

                    // Sección de carpetas
                    if !guardados.carpetas.isEmpty {
                        Text("Carpetas")
                            .font(.headline)
                            .foregroundColor(.black)
                            .padding(.horizontal)

                        ForEach(guardados.carpetas) { carpeta in
                            HStack {
                                NavigationLink(destination: CarpetaDetalleView(carpeta: carpeta)) {
                                    HStack {
                                        Image(systemName: "folder.fill")
                                            .foregroundColor(.yellow)
                                        Text(carpeta.nombre)
                                            .foregroundColor(.black)
                                        Spacer()
                                        Text("\(carpeta.posts.count) posts")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }

                                Menu {
                                    Button("Editar nombre") {
                                        carpetaSeleccionada = carpeta
                                        nombreEditado = carpeta.nombre
                                        mostrarEditarCarpeta = true
                                    }

                                    Button("Eliminar", role: .destructive) {
                                        guardados.eliminarCarpeta(carpeta)
                                    }
                                } label: {
                                    Image(systemName: "ellipsis")
                                        .rotationEffect(.degrees(90))
                                        .foregroundColor(.gray)
                                        .padding(.leading, 8)
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                    }

                    // Botón crear carpeta
                    Button {
                        mostrarCrearCarpeta = true
                    } label: {
                        Label("Crear nueva carpeta", systemImage: "plus")
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.black)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .padding(.horizontal)
                    }
                }
                .padding(.top)
            }
            .navigationTitle("Guardados")
            .sheet(isPresented: $mostrarCrearCarpeta) {
                hojaCrearCarpeta
            }
            .sheet(isPresented: $mostrarEditarCarpeta) {
                hojaEditarCarpeta
            }
        }
    }

    // Vista para crear nueva carpeta
    var hojaCrearCarpeta: some View {
        VStack(spacing: 20) {
            Text("Nueva carpeta")
                .font(.title2)
                .bold()

            TextField("Nombre de la carpeta", text: $nuevoNombreCarpeta)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)

            Button("Crear") {
                let nombre = nuevoNombreCarpeta.trimmingCharacters(in: .whitespaces)
                if !nombre.isEmpty {
                    guardados.crearCarpeta(nombre: nombre)
                    nuevoNombreCarpeta = ""
                    mostrarCrearCarpeta = false
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.black)
            .foregroundColor(.white)
            .cornerRadius(12)

            Spacer()
        }
        .padding()
    }

    // Vista para editar nombre de carpeta
    var hojaEditarCarpeta: some View {
        VStack(spacing: 20) {
            Text("Editar carpeta")
                .font(.title2)
                .bold()

            TextField("Nuevo nombre", text: $nombreEditado)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)

            Button("Guardar") {
                if let carpeta = carpetaSeleccionada {
                    let nuevo = nombreEditado.trimmingCharacters(in: .whitespaces)
                    if !nuevo.isEmpty {
                        guardados.renombrarCarpeta(carpeta, nuevoNombre: nuevo)
                    }
                }
                mostrarEditarCarpeta = false
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.black)
            .foregroundColor(.white)
            .cornerRadius(12)

            Spacer()
        }
        .padding()
    }
}

#Preview {
    GuardadosView()
}
