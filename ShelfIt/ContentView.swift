import SwiftUI
import RealityKit
import RealityKitContent

struct ContentView: View {
    @StateObject var sceneController = ShelfSceneController()
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
                                if let parent = selected.parent {
                                    selected.removeFromParent()
                                    sceneController.selectedEntity = nil
                                } else {
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
                    }
            )
            .simultaneousGesture(
                TapGesture()
                    .targetedToAnyEntity()
                    .onEnded { value in
                        sceneController.selectedEntity = value.entity
                    }
            )
            
            
            if !showPickerPanel {
                VStack {
                    // UI for adding objects
                    Button("Add To-Do Item") {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                            showPickerPanel = true
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(12)
                }
                .glassBackgroundEffect()
                .animation(nil, value: showPickerPanel)
            }
            
            if showPickerPanel {
                VStack(spacing: 12) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("Choose a figurine")
                            .font(.headline)
                            .padding(.vertical, 4)
                        Spacer(minLength: 0)
                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                                showPickerPanel = false
                            }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .imageScale(.large)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 12)
                    ForEach(FigurineKind.allCases, id: \.self) { kind in
                        Button(kind.rawValue) {
                            sceneController.addFigurine(kind: kind)
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                                showPickerPanel = false
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding(20)
                .background(.thinMaterial, in: .rect(cornerRadius: 16))
                .glassBackgroundEffect()
                .frame(maxWidth: 360)
                .opacity(showPickerPanel ? 1 : 0)
                .blur(radius: showPickerPanel ? 0 : 4)
                .transition(
                    .asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.98)),
                        removal: .opacity.combined(with: .scale(scale: 0.98))
                    )
                )
                // Position the panel slightly in front of the desk/root within the volume
                .offset(z: -CGFloat(volumeDepth / 2) + CGFloat(frontMargin))
            }
        }
    }
}

#Preview(windowStyle: .volumetric) {
    ContentView()
}
