//
//  RobotRagdollView.swift
//  realitykit-ragdolls
//
//  Created by ryan reede on 11/23/25.
//

import SwiftUI
import RealityKit
import Combine

struct RobotRagdollView: View {
    @StateObject private var viewModel = RobotRagdollViewModel()

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
                await viewModel.setupScene(in: content)
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
                // Title and instructions
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Robot Ragdoll")
                            .font(.title2.bold())
                        Text("Drag the chest/pelvis to move • Use orbit controls to rotate view")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)

                    Spacer()
                }
                .padding()

                Spacer()

                // Dragging feedback
                if viewModel.isDragging {
                    Text("Dragging robot")
                        .font(.headline)
                        .padding(12)
                        .background(.ultraThinMaterial)
                        .cornerRadius(8)
                        .padding(.bottom, 20)
                }

                // Status indicator
                if viewModel.isLoading {
                    ProgressView("Loading robot model...")
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(8)
                        .padding(.bottom, 20)
                }
            }
        }
        .navigationTitle("Robot Ragdoll")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - View Model

@MainActor
class RobotRagdollViewModel: ObservableObject {
    @Published var isDragging = false
    @Published var isLoading = true
    @Published var ragdollScene: Entity?

    private var ragdollSystem = RobotRagdollSystem()
    private var draggableEntity: Entity?
    private var initialDragPosition: SIMD3<Float>?

    // MARK: - Scene Setup

    func setupScene(in content: some RealityViewContentProtocol) async {
        do {
            // Create physics world
            let physicsWorld = Entity()
            physicsWorld.name = "physicsWorld"

            // Add physics simulation
            var simulationComponent = PhysicsSimulationComponent()
            simulationComponent.solverIterations.positionIterations = 8
            simulationComponent.solverIterations.velocityIterations = 4
            simulationComponent.gravity = [0, -9.8, 0]
            physicsWorld.components.set(simulationComponent)

            // Add joints component
            physicsWorld.components.set(PhysicsJointsComponent())

            // Add ground
            let ground = createGroundPlane()
            physicsWorld.addChild(ground)

            // Create robot ragdoll
            print("Creating robot ragdoll...")
            let ragdoll = try await ragdollSystem.createRagdoll()

            // Position the ragdoll above the ground
            let ragdollParent = Entity()
            ragdollParent.position = [0, 1.5, -2.0]
            ragdollParent.addChild(ragdoll)
            physicsWorld.addChild(ragdollParent)

            // Store references
            ragdollScene = physicsWorld
            draggableEntity = ragdollSystem.getDraggableEntity()

            content.add(physicsWorld)

            // Add lighting
            addLighting(to: content)

            isLoading = false
            print("Robot ragdoll setup complete")

        } catch {
            print("Error setting up robot ragdoll: \(error)")
            isLoading = false
        }
    }

    // MARK: - Ground and Lighting

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
                staticFriction: 0.8,
                dynamicFriction: 0.6,
                restitution: 0.1
            ),
            mode: .static
        )
        ground.components.set(physicsBody)
        ground.components.set(CollisionComponent(shapes: [groundShape]))

        ground.position = [0, -0.1, -2.0]

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

    // MARK: - Drag Handling

    func onDragChanged(value: DragGesture.Value, in entity: Entity?) {
        guard let dragEntity = draggableEntity,
              entity?.name == "chest" || entity?.name == "pelvis" else { return }

        isDragging = true

        if initialDragPosition == nil {
            initialDragPosition = dragEntity.position
        }

        // Convert drag translation to 3D movement
        let scale: Float = 0.005
        let translation = SIMD3<Float>(
            Float(value.translation.width) * scale,
            -Float(value.translation.height) * scale,
            0
        )

        if let initialPos = initialDragPosition {
            dragEntity.position = initialPos + translation
        }
    }

    func onDragEnded() {
        isDragging = false
        initialDragPosition = nil
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        RobotRagdollView()
    }
}
