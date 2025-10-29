//
//  ShelfItApp.swift
//  ShelfIt
//
//  Created by Jack Miller on 10/14/25.
//

import SwiftUI

enum ShelfItWindowID {
    static let picker = "picker"
}

@main
struct ShelfItApp: App {
    @StateObject private var sceneController = ShelfSceneController()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(sceneController)
        }
        .windowStyle(.volumetric)
        .defaultSize(width: 1.0, height: 1, depth: 0.6, in: .meters)
        
        WindowGroup(id: ShelfItWindowID.picker) {
            PickerPanel()
                .environmentObject(sceneController)
        }
        .windowStyle(.plain)
        .defaultSize(width: 640, height: 520)
    }
}
