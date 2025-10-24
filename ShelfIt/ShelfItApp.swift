//
//  ShelfItApp.swift
//  ShelfIt
//
//  Created by Jack Miller on 10/14/25.
//

import SwiftUI

@main
struct ShelfItApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.volumetric)
        .defaultSize(width: 1.0, height: 0.6, depth: 0.6, in: .meters)
    }
}
