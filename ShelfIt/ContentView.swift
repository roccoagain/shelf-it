import SwiftUI
import RealityKit
import RealityKitContent

struct ContentView: View {
    @StateObject var sceneController = ShelfSceneController()
    
    private let volumeDepth: Float = 0.60   // meters (example)
    private let frontMargin: Float = 0.02

    var body: some View {
        ZStack {
            RealityView { content in
                // Load the main scene (e.g., a table from Reality Composer Pro)
                await sceneController.initilizeScene(into: content)
                
                
            } update: { content in
            }
            .gesture(
                DragGesture()
                    .targetedToAnyEntity()
                    .onChanged({ value in
                        let entity = value.entity
                        entity.components.set(PhysicsBodyComponent(mode: .kinematic))
                        // move entity based on drag
                        entity.position = value.convert(value.location3D, from: .local, to: entity.parent!)
                    })
                    .onEnded({ value in
                        let entity = value.entity
                        entity.components.set(PhysicsBodyComponent(mode: .dynamic))
                    }))
            
            
            VStack {
                // UI for adding objects
                Button("Add To-Do Item") {
                    sceneController.addObject()
                }
                .buttonStyle(.borderedProminent)
                .padding(12)
            }.glassBackgroundEffect()
        }
        
    }
}

#Preview(windowStyle: .volumetric) {
    ContentView()
}
