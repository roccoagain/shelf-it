//
//  ShelfSceneController.swift
//  ShelfIt
//
//  Created by OpenAI Codex on 10/14/25.
//

import RealityKit
import RealityKitContent
import Foundation
internal import UIKit

/// Handles creation and configuration of the main RealityKit scene.
@MainActor
final class ShelfSceneController {

    private weak var currentScene: Entity?

    enum SceneLoadingError: LocalizedError {
        case shelfPrototypeMissing

        var errorDescription: String? {
            switch self {
            case .shelfPrototypeMissing:
                return "The ShelfPrototype entity could not be found in the loaded scene."
            }
        }
    }

    /// Loads the default scene from the RealityKit asset bundle and ensures the shelf is ready for physics interactions.
    func makeScene() async throws -> Entity {
        let rootEntity = try await Entity(named: "Scene", in: realityKitContentBundle)
        currentScene = rootEntity
        let shelf = try configureShelfPhysics(in: rootEntity)
        spawnTestBall(over: shelf, in: rootEntity)
        return rootEntity
    }

    // MARK: - Private helpers

    @discardableResult
    private func configureShelfPhysics(in scene: Entity) throws -> Entity {
        guard let shelf = scene.findEntity(named: "ShelfPrototype") else {
            throw SceneLoadingError.shelfPrototypeMissing
        }

        ensureCollisionComponent(on: shelf)

        let physicsMaterial = PhysicsMaterialResource.generate(friction: 0.9, restitution: 0.05)
        shelf.components.set(
            PhysicsBodyComponent(
                massProperties: .default,
                material: physicsMaterial,
                mode: .static
            )
        )

        return shelf
    }

    private func ensureCollisionComponent(on entity: Entity) {
        if entity.components[CollisionComponent.self] != nil {
            return
        }

        let bounds = entity.visualBounds(relativeTo: nil)
        let collisionShape = ShapeResource.generateBox(size: bounds.extents)

        entity.components.set(
            CollisionComponent(
                shapes: [collisionShape],
                mode: .default,
                filter: .default
            )
        )
    }

    private func spawnTestBall(over shelf: Entity, in scene: Entity) {
        guard scene.findEntity(named: "TestBall") == nil else { return }

        let radius: Float = 0.08
        let mesh = MeshResource.generateSphere(radius: radius)
        let material = SimpleMaterial(color: .blue, roughness: 0.25, isMetallic: true)
        let ball = ModelEntity(mesh: mesh, materials: [material])
        ball.name = "TestBall"

        ball.components.set(
            CollisionComponent(
                shapes: [ShapeResource.generateSphere(radius: radius)],
                mode: .default,
                filter: .default
            )
        )

        let bodyMaterial = PhysicsMaterialResource.generate(friction: 0.6, restitution: 0.4)
        ball.components.set(
            PhysicsBodyComponent(
                massProperties: .default,
                material: bodyMaterial,
                mode: .dynamic
            )
        )

        let shelfBounds = shelf.visualBounds(relativeTo: scene)
        let shelfTop = shelfBounds.center.y + (shelfBounds.extents.y / 2.0)
        let spawnHeight = shelfTop + radius + 0.2

        ball.position = SIMD3<Float>(
            shelfBounds.center.x,
            spawnHeight,
            shelfBounds.center.z
        )

        scene.addChild(ball)
    }
}
