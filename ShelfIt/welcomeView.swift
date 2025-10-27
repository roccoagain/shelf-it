//
//  welcomeView.swift
//  ShelfIt
//
//  Created by Jack Miller on 10/26/25.
//

import SwiftUI

struct welcomeView: View {
    var body: some View {
            VStack {
                Text("Welcome to ShelfIt!")
                    .font(.largeTitle)
                    .padding()
                Text("this lets you organize todos.")
                    .font(.body)
                    .padding()
            }
        .glassBackgroundEffect()
            
    }
}

#Preview {
    welcomeView()
}
