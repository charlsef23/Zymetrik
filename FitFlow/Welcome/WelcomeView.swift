//
//  WelcomeView.swift
//  FitFlow
//
//  Created by Carlos Esteve Fernández on 14/4/25.
//

import SwiftUI

struct WelcomeView: View {
    @State private var fadeIn = false
    @State private var moveUp = false

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            Image("logo")
                .resizable()
                .scaledToFit()
                .frame(height: 140)
                .opacity(fadeIn ? 1 : 0)
                .animation(.easeIn(duration: 1), value: fadeIn)

            Text("FitFlow")
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .opacity(fadeIn ? 1 : 0)
                .animation(.easeIn(duration: 1).delay(0.3), value: fadeIn)

            Text("Tu compañero ideal para mantenerte en forma.")
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
                .padding(.horizontal)
                .opacity(fadeIn ? 1 : 0)
                .animation(.easeIn(duration: 1).delay(0.6), value: fadeIn)

            Spacer()

            Button(action: {
                // Navegación futura
            }) {
                Text("Empezar")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .padding(.horizontal)
            }
            .offset(y: moveUp ? 0 : 20)
            .opacity(moveUp ? 1 : 0)
            .animation(.easeOut(duration: 1).delay(1), value: moveUp)

            Spacer(minLength: 40)
        }
        .onAppear {
            fadeIn = true
            moveUp = true
        }
    }
}
