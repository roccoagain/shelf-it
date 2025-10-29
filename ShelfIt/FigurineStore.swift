//
//  FigurineStore.swift
//  ShelfIt
//
//  Created by Rocco Antoniou on 10/27/25.
//

import Foundation
import RealityKit

struct FigurinePrototype: Identifiable, Hashable {
    enum Geometry: Hashable {
        case primitive(Primitive)
        case asset(name: String)
    }
    
    enum Primitive: String, CaseIterable, Hashable {
        case cube
        case sphere
        case cylinder
    }
    
    let id: String
    let title: String
    let geometry: Geometry
    let previewAssetName: String?
    
    init(id: String, title: String, geometry: Geometry, previewAssetName: String? = nil) {
        self.id = id
        self.title = title
        self.geometry = geometry
        if let previewAssetName {
            self.previewAssetName = previewAssetName
        } else {
            switch geometry {
            case .primitive:
                self.previewAssetName = nil
            case .asset(let name):
                self.previewAssetName = name
            }
        }
    }
}

enum FigurineCatalog {
    static let all: [FigurinePrototype] = [
        FigurinePrototype(id: "robot", title: "Robot", geometry: .asset(name: "robot")),
        FigurinePrototype(id: "trash", title: "trash", geometry: .asset(name: "trash")),
        FigurinePrototype(id: "dog", title: "dog", geometry: .asset(name: "dog")),
        FigurinePrototype(id: "cube", title: "Cube", geometry: .primitive(.cube)),
        FigurinePrototype(id: "sphere", title: "Sphere", geometry: .primitive(.sphere)),
        FigurinePrototype(id: "cylinder", title: "Cylinder", geometry: .primitive(.cylinder))
    ]
    
    private static let lookup: [FigurinePrototype.ID: FigurinePrototype] = {
        Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })
    }()
    
    static func prototype(for id: FigurinePrototype.ID) -> FigurinePrototype? {
        lookup[id]
    }
}

struct Vec3: Codable { var x, y, z: Float }
struct Quat: Codable { var x, y, z, w: Float }
struct HSBA: Codable { var h, s, b, a: Float }

struct FigurineRecord: Codable, Identifiable {
    var id: UUID
    var prototypeID: FigurinePrototype.ID
    var name: String
    var position: Vec3
    var rotation: Quat
    var scale: Vec3
    var color: HSBA
    var displayTitle: String = ""
    var detail: String = ""
}

struct FigurineIDComponent: Component { var id: UUID }

final class FigurineStore {
    static let shared = FigurineStore()
    private init() {}

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
