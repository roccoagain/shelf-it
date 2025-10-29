import SwiftUI
import RealityKit
import RealityKitContent

struct ContentView: View {
    @Environment(\.openWindow) private var openWindow
    @EnvironmentObject private var sceneController: ShelfSceneController
    
    private let volumeDepth: Float = 0.6   // meters (example)
    private let frontMargin: Float = 0.02
    
    var body: some View {
        ZStack {
            RealityView { content, attachments in
                // Load the main scene (e.g., a table from Reality Composer Pro)
                await sceneController.initilizeScene(into: content)
                
                guard let floorEntity = content.entities.first(where: { $0.name == "floor" }) else { return }
                floorEntity.position = [0,-0.4,0]
                
                
            } update: { content, attachments in
                // Update logic if needed
                guard let overlay = attachments.entity(for: "figurinePopup") else { return }
                if let selectedEntity = sceneController.selectedEntity {
                    let parent = sceneController.sceneRoot
                    overlay.setParent(parent ?? selectedEntity)
                    let bounds = selectedEntity.visualBounds(relativeTo: parent ?? selectedEntity)
                    let topCenter = SIMD3<Float>(
                        bounds.center.x,
                        bounds.max.y + 0.15,
                        bounds.center.z
                    )
                    overlay.position = topCenter
                } else {
                    overlay.removeFromParent()
                }
            } attachments: {
                Attachment(id: "figurinePopup") {
                    if let selected = sceneController.selectedEntity,
                       let figurineID = sceneController.figurineID(for: selected) {
                        FigurinePopupView(
                            figurineID: figurineID,
                            onClose: {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                                    sceneController.selectedEntity = nil
                                }
                            },
                            onMarkCompleted: {
                                sceneController.remove(figurine: selected)
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                                    sceneController.selectedEntity = nil
                                }
                            }
                        )
                    }
                }
            }
            .gesture(
                DragGesture()
                    .targetedToAnyEntity()
                    .onChanged { value in
                        guard
                            let figurine = sceneController.figurineEntity(containing: value.entity),
                            let parent = figurine.parent
                        else { return }
                        sceneController.updatePhysicsMode(for: figurine, kinematic: true)
                        figurine.position = value.convert(value.location3D, from: .local, to: parent)
                    }
                    .onEnded { value in
                        guard let figurine = sceneController.figurineEntity(containing: value.entity) else { return }
                        sceneController.updatePhysicsMode(for: figurine, kinematic: false)
                        sceneController.persistTransform(for: figurine)
                    }
            )
            .simultaneousGesture(
                TapGesture()
                    .targetedToAnyEntity()
                    .onEnded { value in
                        sceneController.selectedEntity = sceneController
                            .figurineEntity(containing: value.entity)
                    }
            )
            
            
            VStack {
                HStack {
                    Button("Add To-Do Item") {
                        openWindow(id: ShelfItWindowID.picker)
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button(role: .destructive) {
                        sceneController.removeAll()          // NEW
                    } label: {
                        Text("Clear All")
                    }
                    .buttonStyle(.bordered)
                }
                .padding(12)
            }
            .glassBackgroundEffect()
        }
    }
}

private struct FigurinePopupView: View {
    @EnvironmentObject private var sceneController: ShelfSceneController
    
    let figurineID: UUID
    let onClose: () -> Void
    let onMarkCompleted: () -> Void
    
    private var metadataValue: ShelfSceneController.FigurineMetadata? {
        sceneController.metadata(for: figurineID)
    }
    
    private var titleBinding: Binding<String> {
        guard metadataValue != nil else {
            return .constant("")
        }
        return Binding(
            get: { sceneController.metadata(for: figurineID)?.title ?? "" },
            set: { newValue in
                let currentDetail = sceneController.metadata(for: figurineID)?.detail ?? ""
                sceneController.updateMetadata(for: figurineID, title: newValue, detail: currentDetail)
            }
        )
    }
    
    private var detailBinding: Binding<String> {
        guard metadataValue != nil else {
            return .constant("")
        }
        return Binding(
            get: { sceneController.metadata(for: figurineID)?.detail ?? "" },
            set: { newValue in
                let currentTitle = sceneController.metadata(for: figurineID)?.title ?? ""
                sceneController.updateMetadata(for: figurineID, title: currentTitle, detail: newValue)
            }
        )
    }
    
    var body: some View {
        Group {
            if metadataValue != nil {
                content
            } else {
                ProgressView()
                    .padding(32)
            }
        }
        .frame(maxWidth: 360)
        .background(.thinMaterial, in: .rect(cornerRadius: 16))
        .glassBackgroundEffect()
    }
    
    private var content: some View {
        VStack(spacing: 18) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Figurine Details")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    TextField("Custom title", text: titleBinding)
                        .font(.title3.weight(.semibold))
                        .textFieldStyle(.plain)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .imageScale(.large)
                }
                .buttonStyle(.plain)
                .padding(.top, 12)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Description")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                ZStack(alignment: .topLeading) {
                    TextEditor(text: detailBinding)
                        .frame(minHeight: 100, maxHeight: 140)
                        .padding(10)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .scrollContentBackground(.hidden)
                    
                    if detailBinding.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("Add a note or context for this figurine")
                            .font(.footnote)
                            .foregroundStyle(.tertiary)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 16)
                    }
                }
            }
            
            Button(action: onMarkCompleted) {
                Text("Mark Completed")
                    .font(.title3.weight(.semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
        }
        .padding(20)
    }
}

#Preview(windowStyle: .volumetric) {
    ContentView()
        .environmentObject(ShelfSceneController())
}
