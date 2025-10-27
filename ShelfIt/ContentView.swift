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
                guard let overlay = attachments.entity(for: "figurinePopup") else {return}
                if let selectedEntity = sceneController.selectedEntity {
                    overlay.setParent(selectedEntity)
                    overlay.position = [0,0.12,0]
                } else {
                    overlay.removeFromParent()
                }
            } attachments: {
                Attachment(id: "figurinePopup") {
                    if let selected = sceneController.selectedEntity {
                        VStack(spacing: 12) {
                            HStack(alignment: .firstTextBaseline) {
                                Text(selected.name.isEmpty ? "Selected Item" : selected.name)
                                    .font(.headline)
                                    .padding(.vertical, 4)
                                Spacer(minLength: 0)
                                Button {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                                        sceneController.selectedEntity = nil
                                    }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .imageScale(.large)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 12)
                            
                            Button {
                                if let selected = sceneController.selectedEntity {
                                    sceneController.remove(figurine: selected)
                                    sceneController.selectedEntity = nil
                                }
                            } label: {
                                Text("Mark Completed")
                                    .font(.title3.weight(.semibold))
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.blue)
                        }
                        .padding(20)
                        .background(.thinMaterial, in: .rect(cornerRadius: 16))
                        .glassBackgroundEffect()
                        .frame(maxWidth: 360)
                    }
                }
            }
            .gesture(
                DragGesture()
                    .targetedToAnyEntity()
                    .onChanged { value in
                        let entity = value.entity
                        entity.components.set(PhysicsBodyComponent(mode: .kinematic))
                        // move entity based on drag
                        if let parent = entity.parent {
                            entity.position = value.convert(value.location3D, from: .local, to: parent)
                        }
                    }
                    .onEnded { value in
                        let entity = value.entity
                        entity.components.set(PhysicsBodyComponent(mode: .dynamic))
                        sceneController.persistTransform(for: entity)
                    }
            )
            .simultaneousGesture(
                TapGesture()
                    .targetedToAnyEntity()
                    .onEnded { value in
                        sceneController.selectedEntity = value.entity
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

#Preview(windowStyle: .volumetric) {
    ContentView()
        .environmentObject(ShelfSceneController())
}
