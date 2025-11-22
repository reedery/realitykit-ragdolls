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
    @State private var needsRebuild = false

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
            } update: { content in
                if needsRebuild {
                    // Remove old ragdoll
                    if let oldScene = viewModel.ragdollScene {
                        content.remove(oldScene)
                    }
                    // Create new one
                    setupRagdoll(in: content)
                    needsRebuild = false
                }
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
                        Text("Drag the torso to move")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)

                    Spacer()

                    // Rebuild button
                    Button(action: {
                        needsRebuild = true
                    }) {
                        Image(systemName: "arrow.clockwise.circle.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                }
                .padding()

                Spacer()

                // Physics debug controls
                if showPhysicsDebug {
                    PhysicsDebugView(config: physicsConfig)
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                        .onChange(of: physicsConfig.gravity) { _, _ in
                            needsRebuild = true
                        }
                        .onChange(of: physicsConfig.positionIterations) { _, _ in
                            needsRebuild = true
                        }
                        .onChange(of: physicsConfig.velocityIterations) { _, _ in
                            needsRebuild = true
                        }
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

    private func setupRagdoll(in content: RealityViewContent) {
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

    private func addLighting(to content: RealityViewContent) {
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
