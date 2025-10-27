//
//  PickerPanel.swift
//  ShelfIt
//
//  Created by Jack Miller on 10/26/25.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct PickerPanel: View {
    @Environment(\.dismissWindow) private var dismissWindow
    @EnvironmentObject private var sceneController: ShelfSceneController
    private let columnCount = 3
    private let thumbnailSize: CGFloat = 120
    private let gridSpacing: CGFloat = 24
    private let prototypes: [FigurinePrototype] = FigurineCatalog.all
    
    private var rowHeight: CGFloat { thumbnailSize + 32 }
    private var gridViewportHeight: CGFloat { (2.5 * rowHeight) + (1.5 * gridSpacing) }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack {
                Text("Choose an object")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Button("Exit", systemImage: "xmark") {
                    dismissWindow(id: ShelfItWindowID.picker)
                }
                .labelStyle(.iconOnly)
            }
            
            

            ScrollView(.vertical, showsIndicators: true) {
                Grid(horizontalSpacing: gridSpacing, verticalSpacing: gridSpacing) {
                    ForEach(modelRows) { row in
                        GridRow {
                            ForEach(row.items) { item in
                                PickerThumbnail(
                                    prototype: item,
                                    size: thumbnailSize,
                                    selectionHandler: { select(item) }
                                )
                            }
                            
                            if row.items.count < columnCount {
                                ForEach(0..<(columnCount - row.items.count), id: \.self) { _ in
                                    Color.clear
                                        .frame(width: thumbnailSize, height: rowHeight)
                                }
                            }
                        }
                    }
                }
            }
            .frame(height: gridViewportHeight)
        }
        .padding(28)
        .frame(minWidth: 460)
        .glassBackgroundEffect(in: RoundedRectangle(cornerRadius: 36, style: .continuous))
    }
    
    private func select(_ prototype: FigurinePrototype) {
        Task {
            await sceneController.addFigurine(from: prototype)
            await MainActor.run {
                dismissWindow(id: ShelfItWindowID.picker)
            }
        }
    }
    
    private var modelRows: [ModelRow] {
        prototypes
            .chunked(into: columnCount)
            .enumerated()
            .map { index, items in
                ModelRow(id: index, items: items)
            }
    }
}

private struct PickerThumbnail: View {
    let prototype: FigurinePrototype
    let size: CGFloat
    let selectionHandler: () -> Void
    
    var body: some View {
        Button(action: selectionHandler) {
            VStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(.thinMaterial)
                    
                    if let assetName = prototype.previewAssetName {
                        Model3D(named: assetName, bundle: realityKitContentBundle) { model in
                            model
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxWidth: size, maxHeight: size)
                        } placeholder: {
                            ProgressView()
                        }
                        .frame(width: size, height: size)
                    } else {
                        PrimitiveThumbnailView(prototype: prototype)
                            .frame(width: size, height: size)
                            .padding(24)
                    }
                }
                .frame(width: size, height: size)
                
                Text(prototype.title)
                    .font(.headline)
                    .minimumScaleFactor(0.8)
                    .foregroundStyle(.secondary)
            }
            .frame(width: size)
        }
        .buttonStyle(.plain)
    }
}

private struct PrimitiveThumbnailView: View {
    let prototype: FigurinePrototype
    
    var body: some View {
        GeometryReader { proxy in
            let dimension = min(proxy.size.width, proxy.size.height)
            let size = dimension * 0.75
            
            Group {
                switch prototype.geometry {
                case .primitive(.cube):
                    Rectangle()
                        .fill(.secondary)
                        .frame(width: size, height: size)
                        .shadow(radius: 6, y: 6)
                case .primitive(.sphere):
                    Circle()
                        .fill(.secondary)
                        .frame(width: size, height: size)
                        .shadow(radius: 6, y: 6)
                case .primitive(.cylinder):
                    Capsule(style: .circular)
                        .fill(.secondary)
                        .frame(width: size * 0.7, height: size)
                        .shadow(radius: 6, y: 6)
                case .asset:
                    EmptyView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

private extension PickerPanel {
    struct ModelRow: Identifiable {
        let id: Int
        let items: [FigurinePrototype]
    }
}

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [self] }
        
        var chunks: [[Element]] = []
        var index = startIndex
        
        while index < endIndex {
            let end = self.index(index, offsetBy: size, limitedBy: endIndex) ?? endIndex
            chunks.append(Array(self[index..<end]))
            index = end
        }
        
        return chunks
    }
}

#Preview {
    PickerPanel()
        .environmentObject(ShelfSceneController())
}
