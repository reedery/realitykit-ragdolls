//
//  ContentView.swift
//  realitykit-ragdolls
//
//  Created by ryan reede on 11/22/25.
//

import SwiftUI
import RealityKit

struct ContentView: View {
    @State private var ragdollTorso: Entity?

    var body: some View {
        RealityView { content in
            do {
                let ragdollScene = try buildRagdollScene()
                content.add(ragdollScene)
            } catch {
                print("Error building ragdoll scene: \(error)")
            }
        } update: { content in
            // Update closure for state changes
        }
        .gesture(
            DragGesture()
                .targetedToAnyEntity()
                .onChanged { value in
                    if let torso = ragdollTorso, value.entity.name == "torso" {
                        // Move the torso based on drag
                        let translation = value.convert(value.translation3D, from: .local, to: torso.parent!)
                        torso.position = torso.position + SIMD3<Float>(
                            Float(translation.x),
                            Float(translation.y),
                            Float(translation.z)
                        )
                    }
                }
        )
        .realityViewCameraControls(.orbit)
        .edgesIgnoringSafeArea(.all)
    }

    // MARK: - Ragdoll Scene Creation

    func buildRagdollScene() throws -> Entity {
        // Create parent simulation entity
        let parentSimulationEntity = Entity()
        let ragdollParent = Entity()
        parentSimulationEntity.addChild(ragdollParent)

        // Add physics simulation component
        var simulationComponent = PhysicsSimulationComponent()
        simulationComponent.solverIterations.positionIterations = 30
        simulationComponent.solverIterations.velocityIterations = 30
        simulationComponent.gravity = [0, -2.0, 0] // Moderate gravity
        parentSimulationEntity.components.set(simulationComponent)

        // Add physics joints component
        parentSimulationEntity.components.set(PhysicsJointsComponent())

        // Create the ragdoll
        let ragdoll = createRagdoll()
        ragdollParent.addChild(ragdoll)

        // Position the scene
        parentSimulationEntity.position = [0, 0.5, -1.5]

        return parentSimulationEntity
    }

    // MARK: - Ragdoll Creation

    func createRagdoll() -> Entity {
        let ragdollRoot = Entity()

        // Create body parts
        let torso = createTorso()
        let head = createHead()
        let leftUpperArm = createUpperArm()
        let leftLowerArm = createLowerArm()
        let rightUpperArm = createUpperArm()
        let rightLowerArm = createLowerArm()
        let leftUpperLeg = createUpperLeg()
        let leftLowerLeg = createLowerLeg()
        let rightUpperLeg = createUpperLeg()
        let rightLowerLeg = createLowerLeg()

        // Add all parts to the ragdoll
        ragdollRoot.addChild(torso)
        ragdollRoot.addChild(head)
        ragdollRoot.addChild(leftUpperArm)
        ragdollRoot.addChild(leftLowerArm)
        ragdollRoot.addChild(rightUpperArm)
        ragdollRoot.addChild(rightLowerArm)
        ragdollRoot.addChild(leftUpperLeg)
        ragdollRoot.addChild(leftLowerLeg)
        ragdollRoot.addChild(rightUpperLeg)
        ragdollRoot.addChild(rightLowerLeg)

        // Position body parts
        torso.position = [0, 0, 0]
        head.position = [0, 0.35, 0]
        leftUpperArm.position = [-0.25, 0.15, 0]
        leftLowerArm.position = [-0.45, -0.05, 0]
        rightUpperArm.position = [0.25, 0.15, 0]
        rightLowerArm.position = [0.45, -0.05, 0]
        leftUpperLeg.position = [-0.08, -0.35, 0]
        leftLowerLeg.position = [-0.08, -0.65, 0]
        rightUpperLeg.position = [0.08, -0.35, 0]
        rightLowerLeg.position = [0.08, -0.65, 0]

        // Store torso reference for dragging
        ragdollTorso = torso

        // Create joints
        do {
            // Neck joint (head to torso)
            try createRevoluteJoint(
                parent: torso,
                parentOffset: [0, 0.25, 0],
                child: head,
                childOffset: [0, -0.1, 0],
                axis: [0, 0, 1]
            )

            // Left shoulder
            try createRevoluteJoint(
                parent: torso,
                parentOffset: [-0.15, 0.15, 0],
                child: leftUpperArm,
                childOffset: [0.1, 0, 0],
                axis: [0, 0, 1]
            )

            // Left elbow
            try createRevoluteJoint(
                parent: leftUpperArm,
                parentOffset: [-0.1, 0, 0],
                child: leftLowerArm,
                childOffset: [0.1, 0, 0],
                axis: [0, 0, 1]
            )

            // Right shoulder
            try createRevoluteJoint(
                parent: torso,
                parentOffset: [0.15, 0.15, 0],
                child: rightUpperArm,
                childOffset: [-0.1, 0, 0],
                axis: [0, 0, 1]
            )

            // Right elbow
            try createRevoluteJoint(
                parent: rightUpperArm,
                parentOffset: [0.1, 0, 0],
                child: rightLowerArm,
                childOffset: [-0.1, 0, 0],
                axis: [0, 0, 1]
            )

            // Left hip
            try createRevoluteJoint(
                parent: torso,
                parentOffset: [-0.08, -0.25, 0],
                child: leftUpperLeg,
                childOffset: [0, 0.15, 0],
                axis: [0, 0, 1]
            )

            // Left knee
            try createRevoluteJoint(
                parent: leftUpperLeg,
                parentOffset: [0, -0.15, 0],
                child: leftLowerLeg,
                childOffset: [0, 0.15, 0],
                axis: [0, 0, 1]
            )

            // Right hip
            try createRevoluteJoint(
                parent: torso,
                parentOffset: [0.08, -0.25, 0],
                child: rightUpperLeg,
                childOffset: [0, 0.15, 0],
                axis: [0, 0, 1]
            )

            // Right knee
            try createRevoluteJoint(
                parent: rightUpperLeg,
                parentOffset: [0, -0.15, 0],
                child: rightLowerLeg,
                childOffset: [0, 0.15, 0],
                axis: [0, 0, 1]
            )

        } catch {
            print("Error creating joints: \(error)")
        }

        return ragdollRoot
    }

    // MARK: - Body Part Creation

    func createTorso() -> Entity {
        let entity = Entity()
        entity.name = "torso"

        let mesh = MeshResource.generateBox(size: [0.3, 0.5, 0.15])
        var material = PhysicallyBasedMaterial()
        material.baseColor.tint = .blue
        entity.components.set(ModelComponent(mesh: mesh, materials: [material]))

        // Kinematic body - can be moved but not affected by forces
        let shape = ShapeResource.generateBox(size: [0.3, 0.5, 0.15])
        var physicsBody = PhysicsBodyComponent(
            shapes: [shape],
            mass: 5.0,
            material: .generate(staticFriction: 0.3, dynamicFriction: 0.2, restitution: 0.1),
            mode: .kinematic
        )
        physicsBody.angularDamping = 2.0
        physicsBody.linearDamping = 2.0

        entity.components.set(physicsBody)
        entity.components.set(CollisionComponent(shapes: [shape]))
        entity.components.set(InputTargetComponent())

        return entity
    }

    func createHead() -> Entity {
        let entity = Entity()
        entity.name = "head"

        let mesh = MeshResource.generateSphere(radius: 0.1)
        var material = PhysicallyBasedMaterial()
        material.baseColor.tint = .orange
        entity.components.set(ModelComponent(mesh: mesh, materials: [material]))

        addDynamicPhysics(to: entity, shape: .generateSphere(radius: 0.1), mass: 1.0)

        return entity
    }

    func createUpperArm() -> Entity {
        let entity = Entity()
        entity.name = "upper_arm"

        let mesh = MeshResource.generateBox(size: [0.2, 0.08, 0.08])
        var material = PhysicallyBasedMaterial()
        material.baseColor.tint = .green
        entity.components.set(ModelComponent(mesh: mesh, materials: [material]))

        addDynamicPhysics(to: entity, shape: .generateBox(size: [0.2, 0.08, 0.08]), mass: 0.5)

        return entity
    }

    func createLowerArm() -> Entity {
        let entity = Entity()
        entity.name = "lower_arm"

        let mesh = MeshResource.generateBox(size: [0.2, 0.07, 0.07])
        var material = PhysicallyBasedMaterial()
        material.baseColor.tint = .cyan
        entity.components.set(ModelComponent(mesh: mesh, materials: [material]))

        addDynamicPhysics(to: entity, shape: .generateBox(size: [0.2, 0.07, 0.07]), mass: 0.4)

        return entity
    }

    func createUpperLeg() -> Entity {
        let entity = Entity()
        entity.name = "upper_leg"

        let mesh = MeshResource.generateBox(size: [0.1, 0.3, 0.1])
        var material = PhysicallyBasedMaterial()
        material.baseColor.tint = .yellow
        entity.components.set(ModelComponent(mesh: mesh, materials: [material]))

        addDynamicPhysics(to: entity, shape: .generateBox(size: [0.1, 0.3, 0.1]), mass: 1.0)

        return entity
    }

    func createLowerLeg() -> Entity {
        let entity = Entity()
        entity.name = "lower_leg"

        let mesh = MeshResource.generateBox(size: [0.09, 0.3, 0.09])
        var material = PhysicallyBasedMaterial()
        material.baseColor.tint = .purple
        entity.components.set(ModelComponent(mesh: mesh, materials: [material]))

        addDynamicPhysics(to: entity, shape: .generateBox(size: [0.09, 0.3, 0.09]), mass: 0.8)

        return entity
    }

    // MARK: - Physics Helper

    func addDynamicPhysics(to entity: Entity, shape: ShapeResource, mass: Float) {
        var physicsBody = PhysicsBodyComponent(
            shapes: [shape],
            mass: mass,
            material: .generate(staticFriction: 0.3, dynamicFriction: 0.2, restitution: 0.1),
            mode: .dynamic
        )
        physicsBody.angularDamping = 1.0
        physicsBody.linearDamping = 0.5

        entity.components.set(physicsBody)
        entity.components.set(CollisionComponent(shapes: [shape]))
    }

    // MARK: - Joint Creation

    func createRevoluteJoint(
        parent: Entity,
        parentOffset: SIMD3<Float>,
        child: Entity,
        childOffset: SIMD3<Float>,
        axis: SIMD3<Float>
    ) throws {
        // Create orientation for the joint axis
        let hingeOrientation = simd_quatf(from: [1, 0, 0], to: axis)

        // Create pin on parent
        let parentPin = parent.pins.set(
            named: "\(parent.name ?? "parent")_pin",
            position: parentOffset,
            orientation: hingeOrientation
        )

        // Create pin on child
        let childPin = child.pins.set(
            named: "\(child.name ?? "child")_pin",
            position: childOffset,
            orientation: hingeOrientation
        )

        // Create revolute joint
        let joint = PhysicsRevoluteJoint(pin0: parentPin, pin1: childPin)

        // Add the joint to the simulation
        try joint.addToSimulation()
    }
}

#Preview {
    ContentView()
}
