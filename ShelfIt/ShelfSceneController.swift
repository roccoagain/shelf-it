import Foundation
import RealityKit
import RealityKitContent
import SwiftUI
import Combine

class ShelfSceneController: ObservableObject {
    // MARK: - Published State
    @Published var addNewObject = false
    
    // MARK: - Scene References
    var sceneRoot: Entity?
    var objectCount = 0
    
    // MARK: - Add New Object to Scene
    func addObject(to content: RealityViewContent) {
        guard let root = sceneRoot else {
            print("Scene root not available")
            return
        }

        let radius: Float = 0.05
        let color = UIColor(hue: CGFloat.random(in: 0...1), saturation: 0.6, brightness: 0.85, alpha: 1.0)
        let material = SimpleMaterial(color: color, isMetallic: false)
        let mesh = MeshResource.generateSphere(radius: radius)
        
        let entity = ModelEntity(mesh: mesh, materials: [material])
        entity.name = "todo-\(objectCount)"
        
        // Place randomly on the table
        entity.position = [
            Float.random(in: -0.2...0.2),
            0.1,
            Float.random(in: -0.2...0.2)
        ]
        
        // Physics and input
        
        entity.generateCollisionShapes(recursive: false)
        var body = PhysicsBodyComponent(mode: .dynamic)
        body.isAffectedByGravity = true
        body.linearDamping = 0.05
        body.angularDamping = 0.05
        // Use a material that encourages rolling with a bit of bounce
        let physMaterial = PhysicsMaterialResource.generate(friction: 0.6, restitution: 0.35)
        body.material = physMaterial
        entity.components.set(body)
        entity.components.set(InputTargetComponent())
        
        root.addChild(entity)
        // Nudge with a small lateral impulse so balls don't stack perfectly
        let impulse = SIMD3<Float>(Float.random(in: -0.01...0.01), 0, Float.random(in: -0.01...0.01))
        entity.applyLinearImpulse(impulse, relativeTo: nil)
        
        objectCount += 1
    }
}

