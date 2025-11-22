//
//  ContentView.swift
//  realitykit-ragdolls
//
//  Created by ryan reede on 11/22/25.
//

import SwiftUI
import RealityKit

struct ContentView: View {
    @StateObject private var viewModel = RagdollViewModel()
    
    var body: some View {
        ZStack {
            // Sky gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.4, green: 0.7, blue: 1.0),  // Sky blue at top
                    Color(red: 0.9, green: 0.9, blue: 1.0)   // Lighter blue at horizon
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            RealityView { content in
                do {
                    // Create a single parent entity for all physics interactions
                    let physicsWorld = Entity()
                    physicsWorld.name = "physicsWorld"
                    
                    // Add physics simulation to the world
                    var simulationComponent = PhysicsSimulationComponent()
                    simulationComponent.solverIterations.positionIterations = 80
                    simulationComponent.solverIterations.velocityIterations = 80
                    simulationComponent.gravity = [0, -2.0, 0]
                    physicsWorld.components.set(simulationComponent)
                    
                    // Add joints component
                    physicsWorld.components.set(PhysicsJointsComponent())
                    
                    // Add ground to physics world
                    let ground = createGroundPlane()
                    physicsWorld.addChild(ground)
                    
                    // Create and add ragdoll to physics world
                    let ragdoll = try RagdollBuilder.createRagdoll()
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
                    
                    // Add lighting for better visuals
                    let sunlight = DirectionalLight()
                    sunlight.light.intensity = 2000
                    sunlight.light.color = .white
                    sunlight.look(at: [0, 0, 0], from: [3, 5, 3], relativeTo: nil)
                    sunlight.shadow?.shadowProjection = .automatic(maximumDistance: 5.0)
                    sunlight.shadow?.depthBias = 0.5
                    content.add(sunlight)
                    
                    // Add ambient light for softer shadows
                    let ambient = PointLight()
                    ambient.light.intensity = 500
                    ambient.light.color = .white
                    ambient.light.attenuationRadius = 10
                    ambient.position = [0, 3, 0]
                    content.add(ambient)
                    
                } catch {
                    print("Error setting up ragdoll: \(error)")
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
            
            // Visual feedback when dragging
            if viewModel.isDragging {
                VStack {
                    Text("Dragging torso")
                        .font(.title)
                        .padding(8)
                        .background(.ultraThinMaterial)
                        .cornerRadius(8)
                    Spacer()
                }
                .padding()
            }
        }
    }
    
    // MARK: - Ground Plane
    
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
            material: .generate(staticFriction: 0.8, dynamicFriction: 0.6, restitution: 0.2),
            mode: .static
        )
        ground.components.set(physicsBody)
        ground.components.set(CollisionComponent(shapes: [groundShape]))
        
        // Position the ground
        ground.position = [0, -1.5, -1.5]
        
        return ground
    }
}

#Preview {
    ContentView()
}
