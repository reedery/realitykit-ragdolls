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
//
//  RagdollBuilderV2.swift
//  realitykit-ragdolls
//
//  Created by ryan reede on 11/22/25.
//

import RealityKit

/// Enhanced ragdoll builder with character configuration support
extension RagdollBuilder {

    // MARK: - Character-Based Creation

    /// Creates a ragdoll with custom character configuration
    static func createRagdoll(
        with character: CharacterConfiguration,
        physicsConfig: PhysicsConfiguration
    ) throws -> Entity {
        let ragdollRoot = Entity()

        let props = character.bodyProportions
        let physics = character.physicsProperties
        let visual = character.visualProperties

        // Create body parts with character-specific properties
        let torso = RagdollBodyPart.createTorso(
            radius: props.torsoRadius,
            color: visual.torsoColor.toUIColor()
        )

        let head = RagdollBodyPart.createHead(
            radius: props.headRadius,
            color: visual.headColor.toUIColor()
        )

        let leftUpperArm = RagdollBodyPart.createLimb(
            length: props.upperArmLength,
            radius: props.upperArmRadius,
            color: visual.limbColor.toUIColor(),
            name: "upper_arm"
        )

        let leftLowerArm = RagdollBodyPart.createLimb(
            length: props.lowerArmLength,
            radius: props.lowerArmRadius,
            color: visual.limbColor.toUIColor(),
            name: "lower_arm"
        )

        let rightUpperArm = RagdollBodyPart.createLimb(
            length: props.upperArmLength,
            radius: props.upperArmRadius,
            color: visual.limbColor.toUIColor(),
            name: "upper_arm"
        )

        let rightLowerArm = RagdollBodyPart.createLimb(
            length: props.lowerArmLength,
            radius: props.lowerArmRadius,
            color: visual.limbColor.toUIColor(),
            name: "lower_arm"
        )

        let leftUpperLeg = RagdollBodyPart.createLimb(
            length: props.upperLegLength,
            radius: props.upperLegRadius,
            color: visual.limbColor.toUIColor(),
            name: "upper_leg"
        )

        let leftLowerLeg = RagdollBodyPart.createLimb(
            length: props.lowerLegLength,
            radius: props.lowerLegRadius,
            color: visual.limbColor.toUIColor(),
            name: "lower_leg"
        )

        let rightUpperLeg = RagdollBodyPart.createLimb(
            length: props.upperLegLength,
            radius: props.upperLegRadius,
            color: visual.limbColor.toUIColor(),
            name: "upper_leg"
        )

        let rightLowerLeg = RagdollBodyPart.createLimb(
            length: props.lowerLegLength,
            radius: props.lowerLegRadius,
            color: visual.limbColor.toUIColor(),
            name: "lower_leg"
        )

        // Add all parts to ragdoll
        ragdollRoot.addChild(torso)

        // Head is fixed to torso (child of torso, not root)
        torso.addChild(head)

        // Add limbs to root (they'll have joints to torso)
        ragdollRoot.addChild(leftUpperArm)
        ragdollRoot.addChild(leftLowerArm)
        ragdollRoot.addChild(rightUpperArm)
        ragdollRoot.addChild(rightLowerArm)
        ragdollRoot.addChild(leftUpperLeg)
        ragdollRoot.addChild(leftLowerLeg)
        ragdollRoot.addChild(rightUpperLeg)
        ragdollRoot.addChild(rightLowerLeg)

        // Position body parts with character-specific proportions
        positionBodyParts(
            character: character,
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

        // Add physics with character-specific properties
        addPhysicsToBodyParts(
            character: character,
            physicsConfig: physicsConfig,
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

        // Create joints with character-specific limits
        try createJoints(
            character: character,
            physicsConfig: physicsConfig,
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

    // MARK: - Positioning

    private static func positionBodyParts(
        character: CharacterConfiguration,
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
        let props = character.bodyProportions
        let spacing = props.jointSpacing

        // Torso at center
        torso.position = [0, 0, 0]

        // Head - positioned close to torso, almost touching
        let headGap = (props.torsoRadius + props.headRadius) * 0.6
        head.position = [0, headGap, 0]  // Local to torso

        // Arms - MUCH more spacing, especially from torso
        let sphereRadius = props.upperArmRadius * 2.5  // Visual sphere size
        let armHorizontalGap = (props.torsoRadius + sphereRadius) * spacing * 2.2  // Much farther from torso
        let armVerticalOffset: Float = props.torsoRadius * 0.5

        leftUpperArm.position = [-armHorizontalGap, armVerticalOffset, 0]
        leftLowerArm.position = [
            -armHorizontalGap - (sphereRadius * 2) * spacing * 2.5,  // Much more spacing between segments
            armVerticalOffset,
            0
        ]

        rightUpperArm.position = [armHorizontalGap, armVerticalOffset, 0]
        rightLowerArm.position = [
            armHorizontalGap + (sphereRadius * 2) * spacing * 2.5,  // Much more spacing between segments
            armVerticalOffset,
            0
        ]

        // Legs - MUCH more vertical spacing, especially from torso
        let legHipWidth = props.torsoRadius * 0.6
        let legSphereRadius = props.upperLegRadius * 2.5  // Visual sphere size
        let legVerticalGap = (props.torsoRadius + legSphereRadius) * spacing * 2.2  // Much farther from torso

        leftUpperLeg.position = [-legHipWidth, -legVerticalGap, 0]
        leftLowerLeg.position = [
            -legHipWidth,
            -legVerticalGap - (legSphereRadius * 2) * spacing * 2.5,  // Much more spacing between segments
            0
        ]

        rightUpperLeg.position = [legHipWidth, -legVerticalGap, 0]
        rightLowerLeg.position = [
            legHipWidth,
            -legVerticalGap - (legSphereRadius * 2) * spacing * 2.5,  // Much more spacing between segments
            0
        ]
    }

    // MARK: - Physics

    private static func addPhysicsToBodyParts(
        character: CharacterConfiguration,
        physicsConfig: PhysicsConfiguration,
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
        let props = character.bodyProportions
        let physics = character.physicsProperties

        // Torso - kinematic (VERY SMALL collider - 40% of visual for maximum space)
        StableRagdollPhysics.addKinematicPhysics(
            to: torso,
            shape: .generateSphere(radius: props.torsoRadius * 0.40),
            mass: physics.torsoMass,
            config: physicsConfig
        )

        // Head - NO PHYSICS (fixed to torso for stability)
        // Just a visual element, no collision or physics body

        // Arms - SPHERES with smaller colliders (65% of visual for more space)
        let upperArmSphereRadius = props.upperArmRadius * 2.5 * 0.65
        let lowerArmSphereRadius = props.lowerArmRadius * 2.5 * 0.65

        StableRagdollPhysics.addDynamicPhysics(
            to: leftUpperArm,
            shape: .generateSphere(radius: upperArmSphereRadius),
            mass: physics.upperArmMass,
            config: physicsConfig
        )
        StableRagdollPhysics.addDynamicPhysics(
            to: rightUpperArm,
            shape: .generateSphere(radius: upperArmSphereRadius),
            mass: physics.upperArmMass,
            config: physicsConfig
        )

        StableRagdollPhysics.addDynamicPhysics(
            to: leftLowerArm,
            shape: .generateSphere(radius: lowerArmSphereRadius),
            mass: physics.lowerArmMass,
            config: physicsConfig,
            isExtremity: true
        )
        StableRagdollPhysics.addDynamicPhysics(
            to: rightLowerArm,
            shape: .generateSphere(radius: lowerArmSphereRadius),
            mass: physics.lowerArmMass,
            config: physicsConfig,
            isExtremity: true
        )

        // Legs - SPHERES with smaller colliders (65% of visual for more space)
        let upperLegSphereRadius = props.upperLegRadius * 2.5 * 0.65
        let lowerLegSphereRadius = props.lowerLegRadius * 2.5 * 0.65

        StableRagdollPhysics.addDynamicPhysics(
            to: leftUpperLeg,
            shape: .generateSphere(radius: upperLegSphereRadius),
            mass: physics.upperLegMass,
            config: physicsConfig
        )
        StableRagdollPhysics.addDynamicPhysics(
            to: rightUpperLeg,
            shape: .generateSphere(radius: upperLegSphereRadius),
            mass: physics.upperLegMass,
            config: physicsConfig
        )

        StableRagdollPhysics.addDynamicPhysics(
            to: leftLowerLeg,
            shape: .generateSphere(radius: lowerLegSphereRadius),
            mass: physics.lowerLegMass,
            config: physicsConfig,
            isExtremity: true
        )
        StableRagdollPhysics.addDynamicPhysics(
            to: rightLowerLeg,
            shape: .generateSphere(radius: lowerLegSphereRadius),
            mass: physics.lowerLegMass,
            config: physicsConfig,
            isExtremity: true
        )
    }

    // MARK: - Joints

    private static func createJoints(
        character: CharacterConfiguration,
        physicsConfig: PhysicsConfiguration,
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
        let props = character.bodyProportions
        let physics = character.physicsProperties

        // Calculate joint offsets (match collider sizing: torso 40%, limbs 65%)
        let torsoTop = props.torsoRadius * 0.40
        let torsoBottom = -props.torsoRadius * 0.40
        let torsoShoulder = props.torsoRadius * 0.40

        // NO NECK JOINT - head is fixed to torso as a child entity

        // Shoulders - attach to edge of sphere colliders
        let shoulderHorizontalOffset = torsoShoulder
        let upperArmSphereRadius = props.upperArmRadius * 2.5 * 0.65

        try StableRagdollPhysics.createSphericalJoint(
            parent: torso,
            parentOffset: [-shoulderHorizontalOffset, torsoTop * 0.5, 0],
            child: leftUpperArm,
            childOffset: [upperArmSphereRadius, 0, 0],  // Edge of sphere
            coneLimitRadians: physicsConfig.shoulderConeLimitDegrees * .pi / 180
        )

        try StableRagdollPhysics.createSphericalJoint(
            parent: torso,
            parentOffset: [shoulderHorizontalOffset, torsoTop * 0.5, 0],
            child: rightUpperArm,
            childOffset: [-upperArmSphereRadius, 0, 0],  // Edge of sphere
            coneLimitRadians: physicsConfig.shoulderConeLimitDegrees * .pi / 180
        )

        // Elbows - attach sphere to sphere
        let lowerArmSphereRadius = props.lowerArmRadius * 2.5 * 0.65

        try StableRagdollPhysics.createRevoluteJoint(
            parent: leftUpperArm,
            parentOffset: [-upperArmSphereRadius, 0, 0],  // Edge of upper arm sphere
            child: leftLowerArm,
            childOffset: [lowerArmSphereRadius, 0, 0],    // Edge of lower arm sphere
            axis: [0, 0, 1],
            minAngle: 0,
            maxAngle: physicsConfig.elbowMaxBendDegrees * .pi / 180
        )

        try StableRagdollPhysics.createRevoluteJoint(
            parent: rightUpperArm,
            parentOffset: [upperArmSphereRadius, 0, 0],   // Edge of upper arm sphere
            child: rightLowerArm,
            childOffset: [-lowerArmSphereRadius, 0, 0],   // Edge of lower arm sphere
            axis: [0, 0, 1],
            minAngle: -physicsConfig.elbowMaxBendDegrees * .pi / 180,
            maxAngle: 0
        )

        // Hips - attach to edge of sphere colliders
        let hipHorizontalOffset = props.torsoRadius * 0.6
        let upperLegSphereRadius = props.upperLegRadius * 2.5 * 0.65

        try StableRagdollPhysics.createSphericalJoint(
            parent: torso,
            parentOffset: [-hipHorizontalOffset, torsoBottom, 0],
            child: leftUpperLeg,
            childOffset: [0, upperLegSphereRadius, 0],  // Top edge of upper leg sphere
            coneLimitRadians: physicsConfig.hipConeLimitDegrees * .pi / 180
        )

        try StableRagdollPhysics.createSphericalJoint(
            parent: torso,
            parentOffset: [hipHorizontalOffset, torsoBottom, 0],
            child: rightUpperLeg,
            childOffset: [0, upperLegSphereRadius, 0],  // Top edge of upper leg sphere
            coneLimitRadians: physicsConfig.hipConeLimitDegrees * .pi / 180
        )

        // Knees - attach sphere to sphere
        let lowerLegSphereRadius = props.lowerLegRadius * 2.5 * 0.65

        try StableRagdollPhysics.createRevoluteJoint(
            parent: leftUpperLeg,
            parentOffset: [0, -upperLegSphereRadius, 0],  // Bottom edge of upper leg sphere
            child: leftLowerLeg,
            childOffset: [0, lowerLegSphereRadius, 0],    // Top edge of lower leg sphere
            axis: [0, 0, 1],
            minAngle: -physicsConfig.kneeMaxBendDegrees * .pi / 180,
            maxAngle: 0
        )

        try StableRagdollPhysics.createRevoluteJoint(
            parent: rightUpperLeg,
            parentOffset: [0, -upperLegSphereRadius, 0],  // Bottom edge of upper leg sphere
            child: rightLowerLeg,
            childOffset: [0, lowerLegSphereRadius, 0],    // Top edge of lower leg sphere
            axis: [0, 0, 1],
            minAngle: -physicsConfig.kneeMaxBendDegrees * .pi / 180,
            maxAngle: 0
        )
    }
}
