//
//  FigurineStore.swift
//  ShelfIt
//
//  Created by Rocco Antoniou on 10/27/25.
//

import Foundation
import RealityKit

enum FigurineKind: String, CaseIterable, Codable {
    case cube, sphere, cylinder
}

struct Vec3: Codable { var x, y, z: Float }
struct Quat: Codable { var x, y, z, w: Float }
struct HSBA: Codable { var h, s, b, a: Float }

struct FigurineRecord: Codable, Identifiable {
    var id: UUID
    var kind: FigurineKind
    var name: String
    var position: Vec3
    var rotation: Quat
    var scale: Vec3
    var color: HSBA
}

struct FigurineIDComponent: Component { var id: UUID }

final class FigurineStore {
    static let shared = FigurineStore()
    private init() {}   // Added

    private let url: URL = {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("figurines.json")
    }()

    func load() -> [UUID: FigurineRecord] {
        guard let data = try? Data(contentsOf: url) else { return [:] }
        return (try? JSONDecoder().decode([UUID: FigurineRecord].self, from: data)) ?? [:]
    }

    func save(_ dict: [UUID: FigurineRecord]) {
        if let data = try? JSONEncoder().encode(dict) {
            try? data.write(to: url, options: [.atomic])
        }
    }
}
