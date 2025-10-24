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
                if let scene = try? await Entity(named: "table", in: realityKitContentBundle) {
                    
                    
                    
                    
                    
                    
                    content.add(scene)
                    sceneController.sceneRoot = scene
                } else {
                    print("Could not load ShelfScene")
                }
            } update: { content in
                if sceneController.addNewObject {
                    sceneController.addObject(to: content)
                    sceneController.addNewObject = false
                }
            }
            
            //Front of volume UI
            VStack {
                // UI for adding objects
                Button("Add To-Do Item") {
                    sceneController.addNewObject = true
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
