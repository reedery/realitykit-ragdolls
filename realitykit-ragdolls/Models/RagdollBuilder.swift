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

        // Add physics simulation component with increased solver iterations for stability
        var simulationComponent = PhysicsSimulationComponent()
        simulationComponent.solverIterations.positionIterations = 30  // Increased from 30
        simulationComponent.solverIterations.velocityIterations = 30  // Increased from 30
        simulationComponent.gravity = [0, -6.0, 0] // Moderate gravity
        parentSimulationEntity.components.set(simulationComponent)

        // Add physics joints component
        parentSimulationEntity.components.set(PhysicsJointsComponent())

        // Create the ragdoll
        let ragdoll = try createRagdoll()
        ragdollParent.addChild(ragdoll)

        // Position the scene - 0.5 units lower to be closer to ground
        parentSimulationEntity.position = [0, 0.0, -1.5]

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
        // Torso at center (sphere radius 0.2)
        torso.position = [0, 0, 0]
        
        // Head positioned with gap above torso
        // Torso sphere radius is 0.2, head sphere radius is 0.15
        head.position = [0, 0.40, 0]  // Increased gap
        
        // Arms positioned with more spacing to prevent overlap
        // Upper arm length is 0.3, add extra spacing from torso
        leftUpperArm.position = [-0.40, 0.10, 0]   // Further from torso, lower
        leftLowerArm.position = [-0.75, 0.10, 0]   // More spacing between arm segments
        rightUpperArm.position = [0.40, 0.10, 0]   // Further from torso, lower
        rightLowerArm.position = [0.75, 0.10, 0]   // More spacing between arm segments
        
        // Legs positioned with more spacing
        // Upper leg length is 0.3
        leftUpperLeg.position = [-0.12, -0.45, 0]   // Slightly wider hip stance, more gap
        leftLowerLeg.position = [-0.12, -0.80, 0]   // More spacing between leg segments
        rightUpperLeg.position = [0.12, -0.45, 0]   // Slightly wider hip stance, more gap
        rightLowerLeg.position = [0.12, -0.80, 0]   // More spacing between leg segments
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
        // Torso - kinematic (sphere slightly smaller than visual)
        // Visual: radius 0.2, Physics: radius 0.18
        RagdollPhysics.addKinematicPhysics(
            to: torso,
            shape: .generateSphere(radius: 0.18),
            mass: 8.0
        )

        // Head - dynamic (sphere slightly smaller than visual)
        // Visual: radius 0.15, Physics: radius 0.13
        RagdollPhysics.addDynamicPhysics(
            to: head,
            shape: .generateSphere(radius: 0.13),
            mass: 1.2,
            isExtremity: true
        )

        // Arms - dynamic (horizontal capsules, softer than boxes)
        // Upper arms: visual is [0.3, 0.08, 0.08], physics capsule is smaller
        // Capsule height 0.26 (vs visual 0.3), radius 0.03 (vs visual 0.04)
        RagdollPhysics.addDynamicPhysics(
            to: leftUpperArm,
            shape: .generateCapsule(height: 0.26, radius: 0.03),
            mass: 1.2
        )
        RagdollPhysics.addDynamicPhysics(
            to: rightUpperArm,
            shape: .generateCapsule(height: 0.26, radius: 0.03),
            mass: 1.2
        )
        
        // Lower arms: visual is [0.3, 0.07, 0.07], physics capsule is smaller
        // Capsule height 0.26, radius 0.028
        RagdollPhysics.addDynamicPhysics(
            to: leftLowerArm,
            shape: .generateCapsule(height: 0.26, radius: 0.028),
            mass: 0.8,
            isExtremity: true
        )
        RagdollPhysics.addDynamicPhysics(
            to: rightLowerArm,
            shape: .generateCapsule(height: 0.26, radius: 0.028),
            mass: 0.8,
            isExtremity: true
        )

        // Legs - dynamic (vertical capsules, softer than boxes)
        // Upper legs: visual is [0.1, 0.3, 0.1], physics capsule is smaller
        // Capsule height 0.26 (vs visual 0.3), radius 0.04 (vs visual 0.05)
        RagdollPhysics.addDynamicPhysics(
            to: leftUpperLeg,
            shape: .generateCapsule(height: 0.26, radius: 0.04),
            mass: 1.5
        )
        RagdollPhysics.addDynamicPhysics(
            to: rightUpperLeg,
            shape: .generateCapsule(height: 0.26, radius: 0.04),
            mass: 1.5
        )
        
        // Lower legs: visual is [0.09, 0.3, 0.09], physics capsule is smaller
        // Capsule height 0.26, radius 0.036
        RagdollPhysics.addDynamicPhysics(
            to: leftLowerLeg,
            shape: .generateCapsule(height: 0.26, radius: 0.036),
            mass: 1.0,
            isExtremity: true
        )
        RagdollPhysics.addDynamicPhysics(
            to: rightLowerLeg,
            shape: .generateCapsule(height: 0.26, radius: 0.036),
            mass: 1.0,
            isExtremity: true
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
        // Neck joint (head to torso) - very tight limit for realistic head movement
        try RagdollPhysics.createSphericalJoint(
            parent: torso,
            parentOffset: [0, 0.18, 0],      // Top of torso
            child: head,
            childOffset: [0, -0.13, 0],      // Bottom of head
            coneLimitRadians: .pi / 8        // 22.5 degrees
        )

        // Left shoulder - tighter limit for more realistic arm movement
        try RagdollPhysics.createSphericalJoint(
            parent: torso,
            parentOffset: [-0.18, 0.10, 0],  // Edge of torso
            child: leftUpperArm,
            childOffset: [0.13, 0, 0],       // Right edge of upper arm (towards torso)
            coneLimitRadians: .pi / 4        // 45 degrees
        )

        // Left elbow - revolute joint with angle limits
        try RagdollPhysics.createRevoluteJoint(
            parent: leftUpperArm,
            parentOffset: [-0.13, 0, 0],     // Left edge of upper arm
            child: leftLowerArm,
            childOffset: [0.13, 0, 0],       // Right edge of lower arm
            axis: [0, 0, 1],
            minAngle: 0,                     // Can't bend backwards
            maxAngle: 2.5                    // ~143 degrees max bend
        )

        // Right shoulder - tighter limit
        try RagdollPhysics.createSphericalJoint(
            parent: torso,
            parentOffset: [0.18, 0.10, 0],   // Edge of torso
            child: rightUpperArm,
            childOffset: [-0.13, 0, 0],      // Left edge of upper arm (towards torso)
            coneLimitRadians: .pi / 4        // 45 degrees
        )

        // Right elbow - revolute joint with angle limits
        try RagdollPhysics.createRevoluteJoint(
            parent: rightUpperArm,
            parentOffset: [0.13, 0, 0],      // Right edge of upper arm
            child: rightLowerArm,
            childOffset: [-0.13, 0, 0],      // Left edge of lower arm
            axis: [0, 0, 1],
            minAngle: -2.5,                  // ~143 degrees max bend
            maxAngle: 0                      // Can't bend backwards
        )

        // Left hip - tighter limit for more realistic leg movement
        try RagdollPhysics.createSphericalJoint(
            parent: torso,
            parentOffset: [-0.12, -0.18, 0], // Bottom of torso at hip position
            child: leftUpperLeg,
            childOffset: [0, 0.13, 0],       // Top of upper leg
            coneLimitRadians: .pi / 6        // 30 degrees
        )

        // Left knee - revolute joint with angle limits
        try RagdollPhysics.createRevoluteJoint(
            parent: leftUpperLeg,
            parentOffset: [0, -0.13, 0],     // Bottom of upper leg
            child: leftLowerLeg,
            childOffset: [0, 0.13, 0],       // Top of lower leg
            axis: [0, 0, 1],
            minAngle: -2.5,                  // ~143 degrees max bend
            maxAngle: 0                      // Can't bend forward
        )

        // Right hip - tighter limit
        try RagdollPhysics.createSphericalJoint(
            parent: torso,
            parentOffset: [0.12, -0.18, 0],  // Bottom of torso at hip position
            child: rightUpperLeg,
            childOffset: [0, 0.13, 0],       // Top of upper leg
            coneLimitRadians: .pi / 6        // 30 degrees
        )

        // Right knee - revolute joint with angle limits
        try RagdollPhysics.createRevoluteJoint(
            parent: rightUpperLeg,
            parentOffset: [0, -0.13, 0],     // Bottom of upper leg
            child: rightLowerLeg,
            childOffset: [0, 0.13, 0],       // Top of lower leg
            axis: [0, 0, 1],
            minAngle: -2.5,                  // ~143 degrees max bend
            maxAngle: 0                      // Can't bend forward
        )
    }
}
