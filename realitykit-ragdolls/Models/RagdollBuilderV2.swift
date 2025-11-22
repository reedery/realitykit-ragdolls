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
        ragdollRoot.addChild(head)
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

        // Head - positioned above torso with gap
        let headGap = (props.torsoRadius + props.headRadius) * spacing
        head.position = [0, headGap, 0]

        // Arms - horizontal positioning with spacing
        let armHorizontalGap = (props.torsoRadius + props.upperArmLength/2) * spacing
        let armVerticalOffset: Float = props.torsoRadius * 0.5

        leftUpperArm.position = [-armHorizontalGap, armVerticalOffset, 0]
        leftLowerArm.position = [
            -armHorizontalGap - (props.upperArmLength + props.lowerArmLength/2) * spacing,
            armVerticalOffset,
            0
        ]

        rightUpperArm.position = [armHorizontalGap, armVerticalOffset, 0]
        rightLowerArm.position = [
            armHorizontalGap + (props.upperArmLength + props.lowerArmLength/2) * spacing,
            armVerticalOffset,
            0
        ]

        // Legs - vertical positioning with spacing
        let legHipWidth = props.torsoRadius * 0.6
        let legVerticalGap = (props.torsoRadius + props.upperLegLength/2) * spacing

        leftUpperLeg.position = [-legHipWidth, -legVerticalGap, 0]
        leftLowerLeg.position = [
            -legHipWidth,
            -legVerticalGap - (props.upperLegLength + props.lowerLegLength/2) * spacing,
            0
        ]

        rightUpperLeg.position = [legHipWidth, -legVerticalGap, 0]
        rightLowerLeg.position = [
            legHipWidth,
            -legVerticalGap - (props.upperLegLength + props.lowerLegLength/2) * spacing,
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

        // Torso - kinematic (slightly smaller collider than visual)
        RagdollPhysics.addKinematicPhysics(
            to: torso,
            shape: .generateSphere(radius: props.torsoRadius * 0.9),
            mass: physics.torsoMass,
            config: physicsConfig
        )

        // Head - dynamic (slightly smaller collider)
        RagdollPhysics.addDynamicPhysics(
            to: head,
            shape: .generateSphere(radius: props.headRadius * 0.87),
            mass: physics.headMass,
            config: physicsConfig,
            isExtremity: true
        )

        // Arms - capsules for smoother collisions
        let upperArmCapsuleHeight = props.upperArmLength * 0.87
        let lowerArmCapsuleHeight = props.lowerArmLength * 0.87

        RagdollPhysics.addDynamicPhysics(
            to: leftUpperArm,
            shape: .generateCapsule(height: upperArmCapsuleHeight, radius: props.upperArmRadius),
            mass: physics.upperArmMass,
            config: physicsConfig
        )
        RagdollPhysics.addDynamicPhysics(
            to: rightUpperArm,
            shape: .generateCapsule(height: upperArmCapsuleHeight, radius: props.upperArmRadius),
            mass: physics.upperArmMass,
            config: physicsConfig
        )

        RagdollPhysics.addDynamicPhysics(
            to: leftLowerArm,
            shape: .generateCapsule(height: lowerArmCapsuleHeight, radius: props.lowerArmRadius),
            mass: physics.lowerArmMass,
            config: physicsConfig,
            isExtremity: true
        )
        RagdollPhysics.addDynamicPhysics(
            to: rightLowerArm,
            shape: .generateCapsule(height: lowerArmCapsuleHeight, radius: props.lowerArmRadius),
            mass: physics.lowerArmMass,
            config: physicsConfig,
            isExtremity: true
        )

        // Legs - capsules for smoother collisions
        let upperLegCapsuleHeight = props.upperLegLength * 0.87
        let lowerLegCapsuleHeight = props.lowerLegLength * 0.87

        RagdollPhysics.addDynamicPhysics(
            to: leftUpperLeg,
            shape: .generateCapsule(height: upperLegCapsuleHeight, radius: props.upperLegRadius),
            mass: physics.upperLegMass,
            config: physicsConfig
        )
        RagdollPhysics.addDynamicPhysics(
            to: rightUpperLeg,
            shape: .generateCapsule(height: upperLegCapsuleHeight, radius: props.upperLegRadius),
            mass: physics.upperLegMass,
            config: physicsConfig
        )

        RagdollPhysics.addDynamicPhysics(
            to: leftLowerLeg,
            shape: .generateCapsule(height: lowerLegCapsuleHeight, radius: props.lowerLegRadius),
            mass: physics.lowerLegMass,
            config: physicsConfig,
            isExtremity: true
        )
        RagdollPhysics.addDynamicPhysics(
            to: rightLowerLeg,
            shape: .generateCapsule(height: lowerLegCapsuleHeight, radius: props.lowerLegRadius),
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

        // Calculate joint offsets
        let torsoTop = props.torsoRadius * 0.9
        let torsoBottom = -props.torsoRadius * 0.9
        let torsoShoulder = props.torsoRadius * 0.9
        let headBottom = -props.headRadius * 0.87

        // Neck joint
        try RagdollPhysics.createSphericalJoint(
            parent: torso,
            parentOffset: [0, torsoTop, 0],
            child: head,
            childOffset: [0, headBottom, 0],
            coneLimitRadians: physicsConfig.neckConeLimitDegrees * .pi / 180
        )

        // Shoulders
        let shoulderHorizontalOffset = torsoShoulder
        let armTopOffset = props.upperArmLength * 0.87 / 2

        try RagdollPhysics.createSphericalJoint(
            parent: torso,
            parentOffset: [-shoulderHorizontalOffset, torsoTop * 0.5, 0],
            child: leftUpperArm,
            childOffset: [armTopOffset, 0, 0],
            coneLimitRadians: physicsConfig.shoulderConeLimitDegrees * .pi / 180
        )

        try RagdollPhysics.createSphericalJoint(
            parent: torso,
            parentOffset: [shoulderHorizontalOffset, torsoTop * 0.5, 0],
            child: rightUpperArm,
            childOffset: [-armTopOffset, 0, 0],
            coneLimitRadians: physicsConfig.shoulderConeLimitDegrees * .pi / 180
        )

        // Elbows
        let armBottomOffset = -props.upperArmLength * 0.87 / 2
        let forearmTopOffset = props.lowerArmLength * 0.87 / 2

        try RagdollPhysics.createRevoluteJoint(
            parent: leftUpperArm,
            parentOffset: [armBottomOffset, 0, 0],
            child: leftLowerArm,
            childOffset: [forearmTopOffset, 0, 0],
            axis: [0, 0, 1],
            minAngle: 0,
            maxAngle: physicsConfig.elbowMaxBendDegrees * .pi / 180
        )

        try RagdollPhysics.createRevoluteJoint(
            parent: rightUpperArm,
            parentOffset: [-armBottomOffset, 0, 0],
            child: rightLowerArm,
            childOffset: [-forearmTopOffset, 0, 0],
            axis: [0, 0, 1],
            minAngle: -physicsConfig.elbowMaxBendDegrees * .pi / 180,
            maxAngle: 0
        )

        // Hips
        let hipHorizontalOffset = props.torsoRadius * 0.6
        let legTopOffset = props.upperLegLength * 0.87 / 2

        try RagdollPhysics.createSphericalJoint(
            parent: torso,
            parentOffset: [-hipHorizontalOffset, torsoBottom, 0],
            child: leftUpperLeg,
            childOffset: [0, legTopOffset, 0],
            coneLimitRadians: physicsConfig.hipConeLimitDegrees * .pi / 180
        )

        try RagdollPhysics.createSphericalJoint(
            parent: torso,
            parentOffset: [hipHorizontalOffset, torsoBottom, 0],
            child: rightUpperLeg,
            childOffset: [0, legTopOffset, 0],
            coneLimitRadians: physicsConfig.hipConeLimitDegrees * .pi / 180
        )

        // Knees
        let legBottomOffset = -props.upperLegLength * 0.87 / 2
        let shinTopOffset = props.lowerLegLength * 0.87 / 2

        try RagdollPhysics.createRevoluteJoint(
            parent: leftUpperLeg,
            parentOffset: [0, legBottomOffset, 0],
            child: leftLowerLeg,
            childOffset: [0, shinTopOffset, 0],
            axis: [0, 0, 1],
            minAngle: -physicsConfig.kneeMaxBendDegrees * .pi / 180,
            maxAngle: 0
        )

        try RagdollPhysics.createRevoluteJoint(
            parent: rightUpperLeg,
            parentOffset: [0, legBottomOffset, 0],
            child: rightLowerLeg,
            childOffset: [0, shinTopOffset, 0],
            axis: [0, 0, 1],
            minAngle: -physicsConfig.kneeMaxBendDegrees * .pi / 180,
            maxAngle: 0
        )
    }
}
