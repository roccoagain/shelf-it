import SwiftUI
import RealityKit
import RealityKitContent

struct ContentView: View {
    @StateObject var sceneController = ShelfSceneController()
    @State private var showFigurinePicker = false
    @State private var showPickerPanel = false
    
    private let volumeDepth: Float = 0.60   // meters (example)
    private let frontMargin: Float = 0.02
    
    var body: some View {
        ZStack {
            RealityView { content, attachments in
                // Load the main scene (e.g., a table from Reality Composer Pro)
                await sceneController.initilizeScene(into: content)
            } update: { content, attachments in
                // Update logic if needed
                guard let overlay = attachments.entity(for: "todoOverlay") else {return}
                if let selectedEntity = sceneController.selectedEntity {
                    overlay.setParent(selectedEntity)
                    overlay.position = [0,0.12,0]
                } else {
                    overlay.removeFromParent()
                }
            } attachments: {
                Attachment(id: "todoOverlay") {
                        HStack {
                            Button(action: {
                                // TODO: save changes here later
                                sceneController.selectedEntity = nil;
                            }) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title)
                                    .foregroundColor(.blue)
                            }

                            Button(action: {
                                sceneController.selectedEntity = nil;
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title)
                                    .foregroundColor(.gray)
                            }
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
                // UI for adding objects
                Button("Add To-Do Item") {
                    showPickerPanel = true
                }
                .buttonStyle(.borderedProminent)
                .padding(12)
            }
            .glassBackgroundEffect()
            
            if showPickerPanel {
                VStack(spacing: 12) {
                    HStack {
                        Text("Choose a figurine")
                            .font(.headline)
                            .padding(.vertical, 4)
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 12)
                    ForEach(FigurineKind.allCases, id: \.self) { kind in
                        Button(kind.rawValue) {
                            sceneController.addFigurine(kind: kind)
                            showPickerPanel = false
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    HStack(spacing: 16) {
                        Button("Cancel") { showPickerPanel = false }
                            .buttonStyle(.bordered)
                    }
                }
                .padding(20)
                .background(.thinMaterial, in: .rect(cornerRadius: 16))
                .overlay(alignment: .topTrailing) {
                    Button { showPickerPanel = false } label: {
                        Image(systemName: "xmark.circle.fill").imageScale(.large)
                    }
                    .buttonStyle(.plain)
                    .padding(12)
                }
                .glassBackgroundEffect()
                .frame(maxWidth: 360)
                // Position the panel slightly in front of the desk/root within the volume
                .offset(z: -CGFloat(volumeDepth / 2) + CGFloat(frontMargin))
            }
            
            // Floating add button near the front of the volume
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        showPickerPanel = true
                    } label: {
                        Image(systemName: "plus").font(.title2)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .padding(24)
                }
            }
            .offset(z: -CGFloat(volumeDepth / 2) + CGFloat(frontMargin))
        }
    }
}

#Preview(windowStyle: .volumetric) {
    ContentView()
}
