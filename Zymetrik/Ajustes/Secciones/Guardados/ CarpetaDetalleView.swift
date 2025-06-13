import SwiftUI

struct CarpetaDetalleView: View {
    let carpeta: CarpetaGuardado

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if carpeta.posts.isEmpty {
                    Text("No hay posts en esta carpeta.")
                        .foregroundColor(.gray)
                        .padding(.top, 40)
                } else {
                    ForEach(carpeta.posts, id: \.id) { post in
                        PostView(post: post)
                    }
                }
            }
            .padding()
        }
        .navigationTitle(carpeta.nombre)
    }
}
