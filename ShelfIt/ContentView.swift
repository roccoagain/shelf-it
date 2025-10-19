//
//  ContentView.swift
//  ShelfIt
//
//  Created by Jack Miller on 10/14/25.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ContentView: View {

    @State private var enlarge = false
    @State private var sceneAnchor: Entity?
    @State private var sceneLoadError: String?

    private let sceneController = ShelfSceneController()

    var body: some View {
        VStack {
            RealityView { content in
                if let cachedScene = sceneAnchor {
                    if cachedScene.parent == nil {
                        content.add(cachedScene)
                    }
                    return
                }

                do {
                    let scene = try await sceneController.makeScene()
                    sceneAnchor = scene
                    content.add(scene)
                } catch {
                    sceneLoadError = error.localizedDescription
                }
            } update: { _ in
                if let scene = sceneAnchor {
                    let uniformScale: Float = enlarge ? 1.4 : 1.0
                    scene.transform.scale = [uniformScale, uniformScale, uniformScale]
                }
            }
            .gesture(TapGesture().targetedToAnyEntity().onEnded { _ in
                enlarge.toggle()
            })

            VStack {
                if let errorDescription = sceneLoadError {
                    Text(errorDescription)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 8)
                }

                Button {
                    enlarge.toggle()
                } label: {
                    Text(enlarge ? "Reduce RealityView Content" : "Enlarge RealityView Content")
                }
                .animation(.none, value: 0)
                .fontWeight(.semibold)
            }
            .padding()
            .glassBackgroundEffect()
        }
    }
}

#Preview(windowStyle: .volumetric) {
    ContentView()
}
