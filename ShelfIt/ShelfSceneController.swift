import Foundation
import RealityKit
import RealityKitContent
import SwiftUI
import Combine

// enum for selectable models.
enum FigurineKind: String, CaseIterable {
    case cube = "Cube"
    case sphere = "Sphere"
    case cylinder = "Cylinder"
}

class ShelfSceneController: ObservableObject {
    // MARK: - Shelf Initialization
    // @Published var addNewObject = false
    @Published var selectedEntity: Entity?
    
    var sceneRoot: Entity?
    var objectCount = 0

    func initilizeScene(into content: RealityViewContent) async {
        guard sceneRoot == nil else { return }
        
        if let rootEntity = try? await Entity(named: "table", in: realityKitContentBundle) {
            sceneRoot = rootEntity
            content.add(rootEntity)
        }
    }

    // MARK: - Shelf Interactions
    func addFigurine(kind: FigurineKind) {
        guard let root = sceneRoot else {
            print("Scene root not available")
            return
        }

        // switch case for selecting a figurine type
        // TODO: use figurines here instead of basic shapes. see FigurineKind enum
        let mesh: MeshResource
        switch kind {
        case .cube:
            mesh = .generateBox(size: 0.06)
        case .sphere:
            mesh = .generateSphere(radius: 0.05)
        case .cylinder:
            mesh = .generateCylinder(height: 0.08, radius: 0.04)
        }
        
        // random color, simple material
        let color = UIColor(hue: CGFloat.random(in: 0...1), saturation: 0.6, brightness: 0.85, alpha: 1.0)
        let material = SimpleMaterial(color: color, isMetallic: false)
        
        // create entity and name it
        let entity = ModelEntity(mesh: mesh, materials: [material])
        entity.name = "todo-\(objectCount)"
        
        // random position on table
        entity.position = [Float.random(in: -0.2...0.2), 0.1, Float.random(in: -0.2...0.2)]
        
        // collision and physics
        entity.generateCollisionShapes(recursive: true) // replaces hard-coded sphere collision
        var body = PhysicsBodyComponent(mode: .dynamic)
        body.isAffectedByGravity = true
        body.linearDamping = 0.05
        body.angularDamping = 0.05
        body.material = PhysicsMaterialResource.generate(friction: 0.6, restitution: 0.35)
        entity.components.set(body)
        entity.components.set(InputTargetComponent())

        
        root.addChild(entity)
        
        // Nudge with a small lateral impulse so balls don't stack perfectly
        let impulse = SIMD3<Float>(Float.random(in: -0.01...0.01), 0, Float.random(in: -0.01...0.01))
        entity.applyLinearImpulse(impulse, relativeTo: nil)
        
        objectCount += 1
    }
}

