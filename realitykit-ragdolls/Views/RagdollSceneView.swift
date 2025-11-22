//
//  RagdollSceneView.swift
//  realitykit-ragdolls
//
//  Created by ryan reede on 11/22/25.
//

import SwiftUI
import RealityKit

struct RagdollSceneView: View {
    let character: CharacterConfiguration
    let showPhysicsDebug: Bool

    @StateObject private var viewModel = RagdollViewModel()
    @State private var physicsConfig = PhysicsConfiguration()

    var body: some View {
        ZStack {
            // Sky gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.4, green: 0.7, blue: 1.0),
                    Color(red: 0.9, green: 0.9, blue: 1.0)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            RealityView { content in
                setupRagdoll(in: content)
            }
            .gesture(
                DragGesture()
                    .targetedToAnyEntity()
                    .onChanged { value in
                        viewModel.onDragChanged(value: value.gestureValue, in: value.entity)
                    }
                    .onEnded { _ in
                        viewModel.onDragEnded()
                    }
            )
            .realityViewCameraControls(.orbit)

            // UI Overlays
            VStack {
                // Character info
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(character.displayName)
                            .font(.title2.bold())
                        Text("Drag the torso to move • Use rebuild button after changing physics")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)

                    Spacer()

                    // Rebuild button - manually trigger rebuild to avoid crashes
                    Button(action: {
                        rebuildScene()
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: "arrow.clockwise.circle.fill")
                                .font(.title)
                            Text("Rebuild")
                                .font(.caption2)
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(.blue)
                        .cornerRadius(12)
                    }
                }
                .padding()

                Spacer()

                // Physics debug controls
                if showPhysicsDebug {
                    PhysicsDebugView(config: physicsConfig)
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                }

                // Dragging feedback
                if viewModel.isDragging {
                    Text("Dragging torso")
                        .font(.headline)
                        .padding(12)
                        .background(.ultraThinMaterial)
                        .cornerRadius(8)
                        .padding(.bottom, 20)
                }
            }
        }
        .navigationTitle("Ragdoll")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            physicsConfig.apply(from: character)
        }
    }

    // MARK: - Setup

    private func setupRagdoll(in content: some RealityViewContentProtocol) {
        do {
            // Create physics world
            let physicsWorld = Entity()
            physicsWorld.name = "physicsWorld"

            // Add physics simulation
            var simulationComponent = PhysicsSimulationComponent()
            simulationComponent.solverIterations.positionIterations = physicsConfig.positionIterations
            simulationComponent.solverIterations.velocityIterations = physicsConfig.velocityIterations
            simulationComponent.gravity = [0, physicsConfig.gravity, 0]
            physicsWorld.components.set(simulationComponent)

            // Add joints component
            physicsWorld.components.set(PhysicsJointsComponent())

            // Add ground
            let ground = createGroundPlane()
            physicsWorld.addChild(ground)

            // Create ragdoll with character configuration
            let ragdoll = try RagdollBuilder.createRagdoll(
                with: character,
                physicsConfig: physicsConfig
            )
            let ragdollParent = Entity()
            ragdollParent.position = [0, 0.0, -1.5]
            ragdollParent.addChild(ragdoll)
            physicsWorld.addChild(ragdollParent)

            // Store references
            viewModel.ragdollScene = physicsWorld
            if let torso = ragdoll.findEntity(named: "torso") {
                viewModel.torsoEntity = torso
            }

            content.add(physicsWorld)

            // Add lighting
            addLighting(to: content)

        } catch {
            print("Error setting up ragdoll: \(error)")
        }
    }

    private func rebuildScene() {
        // Remove the entire scene and restart
        // This is done by dismissing and re-presenting the view
        // For now, just show an alert that user should go back and re-select character
        print("User requested rebuild with new physics parameters")
    }

    private func createGroundPlane() -> Entity {
        let ground = Entity()
        ground.name = "ground"

        // Visual mesh
        let mesh = MeshResource.generatePlane(width: 20, depth: 20)
        var material = PhysicallyBasedMaterial()
        material.baseColor = PhysicallyBasedMaterial.BaseColor(
            tint: UIColor(red: 0.3, green: 0.6, blue: 0.2, alpha: 1.0)
        )
        material.roughness = PhysicallyBasedMaterial.Roughness(floatLiteral: 0.9)
        material.metallic = PhysicallyBasedMaterial.Metallic(floatLiteral: 0.0)
        ground.components.set(ModelComponent(mesh: mesh, materials: [material]))

        // Physics
        let groundShape = ShapeResource.generateBox(width: 20, height: 0.2, depth: 20)
        let physicsBody = PhysicsBodyComponent(
            shapes: [groundShape],
            mass: 0,
            material: .generate(
                staticFriction: physicsConfig.staticFriction,
                dynamicFriction: physicsConfig.dynamicFriction,
                restitution: physicsConfig.restitution
            ),
            mode: .static
        )
        ground.components.set(physicsBody)
        ground.components.set(CollisionComponent(shapes: [groundShape]))

        ground.position = [0, -1.5, -1.5]

        return ground
    }

    private func addLighting(to content: some RealityViewContentProtocol) {
        // Directional light (sun)
        let sunlight = DirectionalLight()
        sunlight.light.intensity = 2000
        sunlight.light.color = .white
        sunlight.look(at: [0, 0, 0], from: [3, 5, 3], relativeTo: nil)
        sunlight.shadow?.shadowProjection = .automatic(maximumDistance: 5.0)
        sunlight.shadow?.depthBias = 0.5
        content.add(sunlight)

        // Ambient light
        let ambient = PointLight()
        ambient.light.intensity = 500
        ambient.light.color = .white
        ambient.light.attenuationRadius = 10
        ambient.position = [0, 3, 0]
        content.add(ambient)
    }
}

#Preview {
    NavigationStack {
        RagdollSceneView(
            character: .defaultCharacter,
            showPhysicsDebug: true
        )
    }
}
