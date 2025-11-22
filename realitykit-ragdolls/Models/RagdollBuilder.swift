//
//  RagdollBuilder.swift
//  realitykit-ragdolls
//
//  Created by ryan reede on 11/22/25.
//

import RealityKit

/// Assembles and configures the complete ragdoll character
class RagdollBuilder {

    // MARK: - Scene Creation

    static func buildRagdollScene() throws -> Entity {
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
        let ragdoll = try createRagdoll()
        ragdollParent.addChild(ragdoll)

        // Position the scene
        parentSimulationEntity.position = [0, 0.5, -1.5]

        return parentSimulationEntity
    }

    // MARK: - Ragdoll Assembly

    static func createRagdoll() throws -> Entity {
        let ragdollRoot = Entity()

        // Create body parts
        let torso = RagdollBodyPart.createTorso()
        let head = RagdollBodyPart.createHead()
        let leftUpperArm = RagdollBodyPart.createUpperArm()
        let leftLowerArm = RagdollBodyPart.createLowerArm()
        let rightUpperArm = RagdollBodyPart.createUpperArm()
        let rightLowerArm = RagdollBodyPart.createLowerArm()
        let leftUpperLeg = RagdollBodyPart.createUpperLeg()
        let leftLowerLeg = RagdollBodyPart.createLowerLeg()
        let rightUpperLeg = RagdollBodyPart.createUpperLeg()
        let rightLowerLeg = RagdollBodyPart.createLowerLeg()

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
        positionBodyParts(
            torso: torso,
            head: head,
            leftUpperArm: leftUpperArm,
            leftLowerArm: leftLowerArm,
            rightUpperArm: rightUpperArm,
            rightLowerArm: rightLowerArm,
            leftUpperLeg: leftUpperLeg,
            leftLowerLeg: leftLowerLeg,
            rightUpperLeg: rightUpperLeg,
            rightLowerLeg: rightLowerLeg
        )

        // Add physics to body parts
        addPhysicsToBodyParts(
            torso: torso,
            head: head,
            leftUpperArm: leftUpperArm,
            leftLowerArm: leftLowerArm,
            rightUpperArm: rightUpperArm,
            rightLowerArm: rightLowerArm,
            leftUpperLeg: leftUpperLeg,
            leftLowerLeg: leftLowerLeg,
            rightUpperLeg: rightUpperLeg,
            rightLowerLeg: rightLowerLeg
        )

        // Create joints
        try createJoints(
            torso: torso,
            head: head,
            leftUpperArm: leftUpperArm,
            leftLowerArm: leftLowerArm,
            rightUpperArm: rightUpperArm,
            rightLowerArm: rightLowerArm,
            leftUpperLeg: leftUpperLeg,
            leftLowerLeg: leftLowerLeg,
            rightUpperLeg: rightUpperLeg,
            rightLowerLeg: rightLowerLeg
        )

        return ragdollRoot
    }

    // MARK: - Private Helpers

    private static func positionBodyParts(
        torso: Entity,
        head: Entity,
        leftUpperArm: Entity,
        leftLowerArm: Entity,
        rightUpperArm: Entity,
        rightLowerArm: Entity,
        leftUpperLeg: Entity,
        leftLowerLeg: Entity,
        rightUpperLeg: Entity,
        rightLowerLeg: Entity
    ) {
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
    }

    private static func addPhysicsToBodyParts(
        torso: Entity,
        head: Entity,
        leftUpperArm: Entity,
        leftLowerArm: Entity,
        rightUpperArm: Entity,
        rightLowerArm: Entity,
        leftUpperLeg: Entity,
        leftLowerLeg: Entity,
        rightUpperLeg: Entity,
        rightLowerLeg: Entity
    ) {
        // Torso - kinematic
        RagdollPhysics.addKinematicPhysics(
            to: torso,
            shape: .generateBox(size: [0.3, 0.5, 0.15]),
            mass: 5.0
        )

        // Head - dynamic
        RagdollPhysics.addDynamicPhysics(
            to: head,
            shape: .generateSphere(radius: 0.1),
            mass: 1.0
        )

        // Arms - dynamic
        RagdollPhysics.addDynamicPhysics(
            to: leftUpperArm,
            shape: .generateBox(size: [0.2, 0.08, 0.08]),
            mass: 0.5
        )
        RagdollPhysics.addDynamicPhysics(
            to: leftLowerArm,
            shape: .generateBox(size: [0.2, 0.07, 0.07]),
            mass: 0.4
        )
        RagdollPhysics.addDynamicPhysics(
            to: rightUpperArm,
            shape: .generateBox(size: [0.2, 0.08, 0.08]),
            mass: 0.5
        )
        RagdollPhysics.addDynamicPhysics(
            to: rightLowerArm,
            shape: .generateBox(size: [0.2, 0.07, 0.07]),
            mass: 0.4
        )

        // Legs - dynamic
        RagdollPhysics.addDynamicPhysics(
            to: leftUpperLeg,
            shape: .generateBox(size: [0.1, 0.3, 0.1]),
            mass: 1.0
        )
        RagdollPhysics.addDynamicPhysics(
            to: leftLowerLeg,
            shape: .generateBox(size: [0.09, 0.3, 0.09]),
            mass: 0.8
        )
        RagdollPhysics.addDynamicPhysics(
            to: rightUpperLeg,
            shape: .generateBox(size: [0.1, 0.3, 0.1]),
            mass: 1.0
        )
        RagdollPhysics.addDynamicPhysics(
            to: rightLowerLeg,
            shape: .generateBox(size: [0.09, 0.3, 0.09]),
            mass: 0.8
        )
    }

    private static func createJoints(
        torso: Entity,
        head: Entity,
        leftUpperArm: Entity,
        leftLowerArm: Entity,
        rightUpperArm: Entity,
        rightLowerArm: Entity,
        leftUpperLeg: Entity,
        leftLowerLeg: Entity,
        rightUpperLeg: Entity,
        rightLowerLeg: Entity
    ) throws {
        // Neck joint (head to torso)
        try RagdollPhysics.createRevoluteJoint(
            parent: torso,
            parentOffset: [0, 0.25, 0],
            child: head,
            childOffset: [0, -0.1, 0],
            axis: [0, 0, 1]
        )

        // Left shoulder
        try RagdollPhysics.createRevoluteJoint(
            parent: torso,
            parentOffset: [-0.15, 0.15, 0],
            child: leftUpperArm,
            childOffset: [0.1, 0, 0],
            axis: [0, 0, 1]
        )

        // Left elbow
        try RagdollPhysics.createRevoluteJoint(
            parent: leftUpperArm,
            parentOffset: [-0.1, 0, 0],
            child: leftLowerArm,
            childOffset: [0.1, 0, 0],
            axis: [0, 0, 1]
        )

        // Right shoulder
        try RagdollPhysics.createRevoluteJoint(
            parent: torso,
            parentOffset: [0.15, 0.15, 0],
            child: rightUpperArm,
            childOffset: [-0.1, 0, 0],
            axis: [0, 0, 1]
        )

        // Right elbow
        try RagdollPhysics.createRevoluteJoint(
            parent: rightUpperArm,
            parentOffset: [0.1, 0, 0],
            child: rightLowerArm,
            childOffset: [-0.1, 0, 0],
            axis: [0, 0, 1]
        )

        // Left hip
        try RagdollPhysics.createRevoluteJoint(
            parent: torso,
            parentOffset: [-0.08, -0.25, 0],
            child: leftUpperLeg,
            childOffset: [0, 0.15, 0],
            axis: [0, 0, 1]
        )

        // Left knee
        try RagdollPhysics.createRevoluteJoint(
            parent: leftUpperLeg,
            parentOffset: [0, -0.15, 0],
            child: leftLowerLeg,
            childOffset: [0, 0.15, 0],
            axis: [0, 0, 1]
        )

        // Right hip
        try RagdollPhysics.createRevoluteJoint(
            parent: torso,
            parentOffset: [0.08, -0.25, 0],
            child: rightUpperLeg,
            childOffset: [0, 0.15, 0],
            axis: [0, 0, 1]
        )

        // Right knee
        try RagdollPhysics.createRevoluteJoint(
            parent: rightUpperLeg,
            parentOffset: [0, -0.15, 0],
            child: rightLowerLeg,
            childOffset: [0, 0.15, 0],
            axis: [0, 0, 1]
        )
    }
}
