import Foundation
import RealityKit
import RealityKitContent
import SwiftUI
import Combine

class ShelfSceneController: ObservableObject {
    @Published var selectedEntity: Entity?
    var sceneRoot: Entity?
    private var records: [UUID: FigurineRecord] = FigurineStore.shared.load()
    
    struct FigurineMetadata {
        var title: String
        var detail: String
    }
    
    func initilizeScene(into content: RealityViewContent) async {
        guard sceneRoot == nil else { return }
        if let root = try? await Entity(named: "table", in: realityKitContentBundle) {
            sceneRoot = root
            content.add(root)
            await restoreAll()
            
            //add scene floor
            // Create a ModelEntity for the floor
            let floor = ModelEntity(
                mesh: .generateBox(size: [4, 0.1, 4]), // Adjust size as needed
                materials: [OcclusionMaterial()]
            )
            floor.name = "floor"
            
            //collision component
            floor.components[CollisionComponent.self] = CollisionComponent(
                shapes: [.generateBox(size: [2, 0.1, 2])],
                mode: .default // or .trigger, if you don't want it to be a physics object
            )
            
            // Add the PhysicsBodyComponent for static physics
            floor.components[PhysicsBodyComponent.self] = PhysicsBodyComponent(
                massProperties: .default, // Default mass properties
                mode: .static // Set to static to make it a non-moving floor
            )
            content.add(floor)
            
            
            
        }
    }
    
    @MainActor
    func addFigurine(from prototype: FigurinePrototype) async {
        guard let root = sceneRoot else { return }
        
        let baseColor = prototype.usesRandomColor ? UIColor.randomSaturatedPastel : nil
        guard let entity = await instantiateEntity(for: prototype, color: baseColor) else { return }
        
        let id = UUID()
        entity.name = id.uuidString
        entity.position = [
            Float.random(in: -0.2...0.2),
            0.1,
            Float.random(in: -0.2...0.2)
        ]
        configureForScene(entity)
        entity.components.set(FigurineIDComponent(id: id))
        root.addChild(entity)
        entity.applyLinearImpulse(
            [Float.random(in: -0.01...0.01), 0, Float.random(in: -0.01...0.01)],
            relativeTo: nil
        )
        
        // persist
        records[id] = snapshot(
            entity: entity,
            prototype: prototype,
            id: id,
            displayTitle: prototype.title,
            detail: ""
        )
        FigurineStore.shared.save(records)
    }
    
    func persistTransform(for entity: Entity) {
        guard
            let id = entity.components[FigurineIDComponent.self]?.id,
            let model = entity as? ModelEntity,
            var rec = records[id],
            let prototype = FigurineCatalog.prototype(for: rec.prototypeID)
        else { return }
        rec = snapshot(
            entity: model,
            prototype: prototype,
            name: rec.name,
            id: rec.id,
            displayTitle: rec.displayTitle,
            detail: rec.detail
        )
        records[id] = rec
        FigurineStore.shared.save(records)
    }
    
    func remove(figurine entity: Entity) {
        guard let id = entity.components[FigurineIDComponent.self]?.id else { return }
        entity.removeFromParent()
        records.removeValue(forKey: id)
        FigurineStore.shared.save(records)
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

    func figurineID(for entity: Entity) -> UUID? {
        entity.components[FigurineIDComponent.self]?.id
    }

    @MainActor
    func metadata(for figurineID: UUID) -> FigurineMetadata? {
        guard let record = records[figurineID] else { return nil }
        let fallbackTitle = FigurineCatalog.prototype(for: record.prototypeID)?.title
        let resolvedTitle = record.displayTitle.isEmpty ? (fallbackTitle ?? "Item") : record.displayTitle
        return FigurineMetadata(title: resolvedTitle, detail: record.detail)
    }

    @MainActor
    func metadata(for entity: Entity) -> FigurineMetadata? {
        guard let id = figurineID(for: entity) else { return nil }
        return metadata(for: id)
    }

    @MainActor
    func updateMetadata(for figurineID: UUID, title: String, detail: String) {
        guard var record = records[figurineID] else { return }
        guard record.displayTitle != title || record.detail != detail else { return }
        objectWillChange.send()
        record.displayTitle = title
        record.detail = detail
        records[figurineID] = record
        FigurineStore.shared.save(records)
    }

    
    private func snapshot(
        entity: ModelEntity,
        prototype: FigurinePrototype,
        name: String? = nil,
        id: UUID? = nil,
        displayTitle: String? = nil,
        detail: String? = nil
    ) -> FigurineRecord {
        let t = entity.transform
        
        let uiColor: UIColor
        if prototype.usesRandomColor,
           let simple = entity.model?.materials.first as? SimpleMaterial {
            uiColor = simple.color.tint
        } else {
            uiColor = .white
        }
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        
        return FigurineRecord(
            id: id ?? UUID(),
            prototypeID: prototype.id,
            name: name ?? entity.name,
            position: Vec3(x: t.translation.x, y: t.translation.y, z: t.translation.z),
            rotation: Quat(x: t.rotation.imag.x, y: t.rotation.imag.y, z: t.rotation.imag.z, w: t.rotation.real),
            scale: Vec3(x: t.scale.x, y: t.scale.y, z: t.scale.z),
            color: HSBA(h: Float(h), s: Float(s), b: Float(b), a: Float(a)),
            displayTitle: displayTitle ?? prototype.title,
            detail: detail ?? ""
        )
    }
    
    
    @MainActor
    private func restoreAll() async {
        guard let root = sceneRoot else { return }
        for rec in records.values {
            guard
                let entity = await buildEntity(from: rec)
            else { continue }
            entity.components.set(FigurineIDComponent(id: rec.id))
            root.addChild(entity)
        }
    }
    
    private func configureForScene(_ entity: ModelEntity) {
        entity.generateCollisionShapes(recursive: true)
        entity.components.set(PhysicsBodyComponent(
            massProperties: .default,
            material: .generate(friction: 0.6, restitution: 0.35),
            mode: .dynamic
        ))
        entity.components.set(InputTargetComponent())
    }
    
    private func instantiateEntity(
        for prototype: FigurinePrototype,
        color: UIColor?
    ) async -> ModelEntity? {
        switch prototype.geometry {
        case .primitive(let primitive):
            let mesh: MeshResource = switch primitive {
            case .cube: .generateBox(size: 0.06)
            case .sphere: .generateSphere(radius: 0.05)
            case .cylinder: .generateCylinder(height: 0.08, radius: 0.04)
            }
            let surfaceColor = color ?? UIColor.white
            return ModelEntity(
                mesh: mesh,
                materials: [SimpleMaterial(color: surfaceColor, isMetallic: false)]
            )
        case .asset(let name):
            guard let loaded = try? await Entity(named: name, in: realityKitContentBundle) else {
                return nil
            }
            let container = ModelEntity()
            container.name = name
            container.addChild(loaded.clone(recursive: true))
            return container
        }
    }
    
    private func buildEntity(from rec: FigurineRecord) async -> ModelEntity? {
        guard let prototype = FigurineCatalog.prototype(for: rec.prototypeID) else { return nil }
        let restoreColor: UIColor?
        if prototype.usesRandomColor {
            restoreColor = UIColor(
                hue: CGFloat(rec.color.h),
                saturation: CGFloat(rec.color.s),
                brightness: CGFloat(rec.color.b),
                alpha: CGFloat(rec.color.a)
            )
        } else {
            restoreColor = nil
        }
        
        guard let entity = await instantiateEntity(for: prototype, color: restoreColor) else { return nil }
        entity.name = rec.name
        entity.transform = Transform(
            scale: [rec.scale.x, rec.scale.y, rec.scale.z],
            rotation: simd_quatf(ix: rec.rotation.x, iy: rec.rotation.y, iz: rec.rotation.z, r: rec.rotation.w),
            translation: [rec.position.x, rec.position.y, rec.position.z]
        )
        configureForScene(entity)
        return entity
    }
}

private extension FigurinePrototype {
    var usesRandomColor: Bool {
        if case .primitive = geometry {
            return true
        }
        return false
    }
}

private extension UIColor {
    static var randomSaturatedPastel: UIColor {
        UIColor(
            hue: CGFloat.random(in: 0...1),
            saturation: 0.6,
            brightness: 0.85,
            alpha: 1.0
        )
    }
}
