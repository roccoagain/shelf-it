import Foundation
import RealityKit
import RealityKitContent
import SwiftUI
import Combine

class ShelfSceneController: ObservableObject {
    @Published var selectedEntity: Entity?
    var sceneRoot: Entity?
    private var records: [UUID: FigurineRecord] = FigurineStore.shared.load()
    
    func initilizeScene(into content: RealityViewContent) async {
        guard sceneRoot == nil else { return }
        if let root = try? await Entity(named: "table", in: realityKitContentBundle) {
            sceneRoot = root
            content.add(root)
            restoreAll()
        }
    }
    
    func addFigurine(kind: FigurineKind) {
        guard let root = sceneRoot else { return }
        
        let mesh: MeshResource = switch kind {
        case .cube: .generateBox(size: 0.06)
        case .sphere: .generateSphere(radius: 0.05)
        case .cylinder: .generateCylinder(height: 0.08, radius: 0.04)
        }
        
        let color = UIColor(
            hue: CGFloat.random(in: 0...1),
            saturation: 0.6, brightness: 0.85, alpha: 1.0
        )
        
        let entity = ModelEntity(mesh: mesh, materials: [SimpleMaterial(color: color, isMetallic: false)])
        let id = UUID()
        entity.name = "todo-\(id.uuidString.prefix(6))"
        entity.position = [Float.random(in: -0.2...0.2), 0.1, Float.random(in: -0.2...0.2)]
        entity.generateCollisionShapes(recursive: true)
        entity.components.set(PhysicsBodyComponent(
            massProperties: .default,
            material: .generate(friction: 0.6, restitution: 0.35),
            mode: .dynamic
        ))
        entity.components.set(InputTargetComponent())
        entity.components.set(FigurineIDComponent(id: id))
        root.addChild(entity)
        entity.applyLinearImpulse([Float.random(in: -0.01...0.01), 0, Float.random(in: -0.01...0.01)], relativeTo: nil)
        
        // persist
        records[id] = snapshot(entity: entity, kind: kind)
        FigurineStore.shared.save(records)
    }
    
    func persistTransform(for entity: Entity) {
        guard
            let id = entity.components[FigurineIDComponent.self]?.id,
            let model = entity as? ModelEntity,
            var rec = records[id]
        else { return }
        rec = snapshot(entity: model, kind: rec.kind, name: rec.name, id: rec.id)
        records[id] = rec
        FigurineStore.shared.save(records)
    }
    
    func remove(figurine entity: Entity) {
        guard let id = entity.components[FigurineIDComponent.self]?.id else { return }
        entity.removeFromParent()
        records.removeValue(forKey: id)
        FigurineStore.shared.save(records)
    }
    
    // MARK: - helpers
    private func snapshot(entity: ModelEntity, kind: FigurineKind, name: String? = nil, id: UUID? = nil) -> FigurineRecord {
        let t = entity.transform
        
        // extract color
        let uiColor: UIColor
        if let simple = entity.model?.materials.first as? SimpleMaterial {
            uiColor = simple.color.tint
        } else {
            uiColor = .white
        }
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        
        return FigurineRecord(
            id: id ?? UUID(),
            kind: kind,
            name: name ?? entity.name,
            position: Vec3(x: t.translation.x, y: t.translation.y, z: t.translation.z),
            rotation: Quat(x: t.rotation.imag.x, y: t.rotation.imag.y, z: t.rotation.imag.z, w: t.rotation.real),
            scale: Vec3(x: t.scale.x, y: t.scale.y, z: t.scale.z),
            color: HSBA(h: Float(h), s: Float(s), b: Float(b), a: Float(a))
        )
    }
    
    
    private func restoreAll() {
        guard let root = sceneRoot else { return }
        for rec in records.values {
            let entity = buildEntity(from: rec)
            entity.components.set(FigurineIDComponent(id: rec.id))
            root.addChild(entity)
        }
    }
    
    @MainActor
    func removeAll() {
        guard let root = sceneRoot else { return }

        // Snapshot the list before mutating it
        let toDelete = root.children.filter { $0.components[FigurineIDComponent.self] != nil }

        toDelete.forEach { $0.removeFromParent() }

        records.removeAll()
        selectedEntity = nil
        FigurineStore.shared.save(records)
    }

    
    private func buildEntity(from rec: FigurineRecord) -> ModelEntity {
        let mesh: MeshResource = switch rec.kind {
        case .cube: .generateBox(size: 0.06)
        case .sphere: .generateSphere(radius: 0.05)
        case .cylinder: .generateCylinder(height: 0.08, radius: 0.04)
        }
        let ui = UIColor(hue: CGFloat(rec.color.h), saturation: CGFloat(rec.color.s),
                         brightness: CGFloat(rec.color.b), alpha: CGFloat(rec.color.a))
        let entity = ModelEntity(mesh: mesh, materials: [SimpleMaterial(color: ui, isMetallic: false)])
        entity.name = rec.name
        entity.transform = Transform(
            scale: [rec.scale.x, rec.scale.y, rec.scale.z],
            rotation: simd_quatf(ix: rec.rotation.x, iy: rec.rotation.y, iz: rec.rotation.z, r: rec.rotation.w),
            translation: [rec.position.x, rec.position.y, rec.position.z]
        )
        entity.generateCollisionShapes(recursive: true)
        entity.components.set(PhysicsBodyComponent(mode: .dynamic))
        entity.components.set(InputTargetComponent())
        return entity
    }
}

