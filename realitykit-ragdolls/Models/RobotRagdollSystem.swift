//
//  RobotRagdollSystem.swift
//  realitykit-ragdolls
//
//  Created by ryan reede on 11/23/25.
//

import RealityKit
import SwiftUI

// MARK: - Configuration

struct RagdollConfiguration {
    let boneMass: Float = 1.0
    let colliderRadius: Float = 0.05
    let jointStiffness: Float = 100.0
    let jointDamping: Float = 10.0
    let linearDamping: Float = 0.1
    let angularDamping: Float = 0.1
}

// MARK: - Robot Bone Enum

enum RobotBone: String, CaseIterable {
    case pelvis, spine, chest, neck, head
    case leftShoulder, leftUpperArm, leftForearm, leftHand
    case rightShoulder, rightUpperArm, rightForearm, rightHand
    case leftThigh, leftShin, leftFoot
    case rightThigh, rightShin, rightFoot

    var colliderRadius: Float {
        switch self {
        case .pelvis, .spine, .chest:
            return 0.08
        case .neck:
            return 0.04
        case .head:
            return 0.06
        case .leftShoulder, .rightShoulder:
            return 0.05
        case .leftUpperArm, .rightUpperArm, .leftThigh, .rightThigh:
            return 0.04
        case .leftForearm, .rightForearm, .leftShin, .rightShin:
            return 0.035
        case .leftHand, .rightHand, .leftFoot, .rightFoot:
            return 0.03
        }
    }

    var mass: Float {
        switch self {
        case .pelvis, .spine, .chest:
            return 2.0
        case .neck:
            return 0.3
        case .head:
            return 1.0
        case .leftShoulder, .rightShoulder:
            return 0.5
        case .leftUpperArm, .rightUpperArm:
            return 0.8
        case .leftForearm, .rightForearm:
            return 0.6
        case .leftHand, .rightHand:
            return 0.3
        case .leftThigh, .rightThigh:
            return 1.2
        case .leftShin, .rightShin:
            return 0.9
        case .leftFoot, .rightFoot:
            return 0.4
        }
    }
}

// MARK: - Joint Constraint Builder

class JointConstraintBuilder {

    /// Creates a ball-and-socket joint (cone twist)
    static func createBallJoint(
        between entityA: Entity,
        and entityB: Entity,
        anchorA: SIMD3<Float>,
        anchorB: SIMD3<Float>,
        coneAngle: Float = .pi / 4
    ) -> PhysicsJointComponent {
        let joint = PhysicsConeTwistJoint(
            entityA: entityA,
            entityB: entityB,
            anchorFromEntityA: anchorA,
            anchorFromEntityB: anchorB,
            axis: SIMD3<Float>(0, 1, 0),
            swingAngle1: coneAngle,
            swingAngle2: coneAngle,
            twistAngle: coneAngle / 2
        )
        return PhysicsJointComponent(joint: joint)
    }

    /// Creates a hinge joint (revolute)
    static func createHingeJoint(
        between entityA: Entity,
        and entityB: Entity,
        anchorA: SIMD3<Float>,
        anchorB: SIMD3<Float>,
        axis: SIMD3<Float>,
        minAngle: Float = -.pi / 2,
        maxAngle: Float = .pi / 2
    ) -> PhysicsJointComponent {
        let joint = PhysicsRevoluteJoint(
            entityA: entityA,
            entityB: entityB,
            anchorFromEntityA: anchorA,
            anchorFromEntityB: anchorB,
            axis: axis,
            minAngle: minAngle,
            maxAngle: maxAngle
        )
        return PhysicsJointComponent(joint: joint)
    }
}

// MARK: - Robot Ragdoll System

@MainActor
class RobotRagdollSystem {
    private var boneEntities: [RobotBone: Entity] = [:]
    private var rootEntity: Entity?
    private let config = RagdollConfiguration()

    /// Creates a ragdoll from the robot model
    func createRagdoll(from modelPath: String = "biped_robot") async throws -> Entity {
        let ragdollRoot = Entity()
        ragdollRoot.name = "robotRagdoll"

        // Try to load the USDZ model
        guard let characterModel = try? await loadRobotModel(named: modelPath) else {
            print("Failed to load robot model, creating procedural ragdoll")
            createProceduralRagdoll(rootEntity: ragdollRoot)
            try setupJointConstraints()
            enableRagdollPhysics()
            return ragdollRoot
        }

        // Check for skeleton
        if characterModel.components.has(SkeletalPoseComponent.self) {
            print("Processing skeleton-based ragdoll")
            try await processSkeletonBones(from: characterModel, rootEntity: ragdollRoot)
        } else {
            print("No skeleton found, creating procedural ragdoll")
            createProceduralRagdoll(rootEntity: ragdollRoot)
        }

        try setupJointConstraints()
        enableRagdollPhysics()

        rootEntity = ragdollRoot
        return ragdollRoot
    }

    // MARK: - Model Loading

    private func loadRobotModel(named: String) async throws -> ModelEntity? {
        // Try loading from Assets3d folder
        let bundlePath = Bundle.main.path(forResource: named, ofType: "usdz", inDirectory: "Assets3d")

        if let path = bundlePath {
            let url = URL(fileURLWithPath: path)
            return try await ModelEntity.load(contentsOf: url)
        }

        // Fallback: try loading from main bundle
        return try? await ModelEntity.load(named: named)
    }

    // MARK: - Skeleton Processing

    private func processSkeletonBones(from model: ModelEntity, rootEntity: Entity) async throws {
        guard let skeleton = model.components[SkeletalPoseComponent.self] else {
            return
        }

        // Get the skeleton joint hierarchy
        let jointNames = skeleton.definition.joints.map { $0.name }
        print("Found \(jointNames.count) joints in skeleton")

        // Map joint names to our RobotBone enum
        for bone in RobotBone.allCases {
            if let jointIndex = jointNames.firstIndex(where: { $0.lowercased().contains(bone.rawValue.lowercased()) }) {
                let joint = skeleton.definition.joints[jointIndex]
                let transform = Transform(matrix: joint.inverseBindPose.inverse)

                let boneEntity = createBoneEntity(bone: bone, transform: transform)
                boneEntity.name = bone.rawValue
                boneEntities[bone] = boneEntity
                rootEntity.addChild(boneEntity)
            }
        }

        // If we didn't find enough bones, fall back to procedural
        if boneEntities.count < 5 {
            print("Not enough bones mapped (\(boneEntities.count)), falling back to procedural")
            boneEntities.removeAll()
            createProceduralRagdoll(rootEntity: rootEntity)
        }
    }

    // MARK: - Procedural Ragdoll

    private func createProceduralRagdoll(rootEntity: Entity) {
        // Create basic humanoid structure
        let positions: [RobotBone: SIMD3<Float>] = [
            .pelvis: [0, 0.9, 0],
            .spine: [0, 1.1, 0],
            .chest: [0, 1.3, 0],
            .neck: [0, 1.5, 0],
            .head: [0, 1.65, 0],

            // Left arm
            .leftShoulder: [-0.15, 1.35, 0],
            .leftUpperArm: [-0.3, 1.2, 0],
            .leftForearm: [-0.5, 1.0, 0],
            .leftHand: [-0.65, 0.85, 0],

            // Right arm
            .rightShoulder: [0.15, 1.35, 0],
            .rightUpperArm: [0.3, 1.2, 0],
            .rightForearm: [0.5, 1.0, 0],
            .rightHand: [0.65, 0.85, 0],

            // Left leg
            .leftThigh: [-0.1, 0.6, 0],
            .leftShin: [-0.1, 0.3, 0],
            .leftFoot: [-0.1, 0.05, 0],

            // Right leg
            .rightThigh: [0.1, 0.6, 0],
            .rightShin: [0.1, 0.3, 0],
            .rightFoot: [0.1, 0.05, 0]
        ]

        for bone in RobotBone.allCases {
            guard let position = positions[bone] else { continue }

            let transform = Transform(translation: position)
            let boneEntity = createBoneEntity(bone: bone, transform: transform)
            boneEntity.name = bone.rawValue
            boneEntities[bone] = boneEntity
            rootEntity.addChild(boneEntity)
        }
    }

    // MARK: - Bone Entity Creation

    private func createBoneEntity(bone: RobotBone, transform: Transform) -> Entity {
        let entity = Entity()
        entity.transform = transform

        // Create visual representation (sphere for now)
        let mesh = MeshResource.generateSphere(radius: bone.colliderRadius)
        var material = PhysicallyBasedMaterial()
        material.baseColor = PhysicallyBasedMaterial.BaseColor(
            tint: getBoneColor(for: bone)
        )
        material.roughness = 0.7
        material.metallic = 0.2

        entity.components.set(ModelComponent(mesh: mesh, materials: [material]))

        // Physics body
        var physicsBody = PhysicsBodyComponent(
            massProperties: .init(mass: bone.mass),
            material: .generate(
                staticFriction: 0.5,
                dynamicFriction: 0.3,
                restitution: 0.1
            ),
            mode: .dynamic
        )
        physicsBody.linearDamping = config.linearDamping
        physicsBody.angularDamping = config.angularDamping

        entity.components.set(physicsBody)

        // Collision
        let collisionShape = ShapeResource.generateSphere(radius: bone.colliderRadius)
        entity.components.set(CollisionComponent(shapes: [collisionShape]))

        // Make torso/pelvis draggable
        if bone == .pelvis || bone == .chest {
            entity.components.set(InputTargetComponent())
        }

        return entity
    }

    private func getBoneColor(for bone: RobotBone) -> UIColor {
        switch bone {
        case .pelvis, .spine, .chest:
            return .systemBlue
        case .neck, .head:
            return .systemOrange
        case .leftShoulder, .leftUpperArm, .leftForearm, .leftHand:
            return .systemGreen
        case .rightShoulder, .rightUpperArm, .rightForearm, .rightHand:
            return .systemGreen
        case .leftThigh, .leftShin, .leftFoot:
            return .systemRed
        case .rightThigh, .rightShin, .rightFoot:
            return .systemRed
        }
    }

    // MARK: - Joint Constraints

    private func setupJointConstraints() throws {
        // Spine joints (ball joints)
        createJointIfExists(.pelvis, .spine, coneAngle: .pi / 6)
        createJointIfExists(.spine, .chest, coneAngle: .pi / 6)
        createJointIfExists(.chest, .neck, coneAngle: .pi / 4)
        createJointIfExists(.neck, .head, coneAngle: .pi / 3)

        // Shoulder joints (ball joints)
        createJointIfExists(.chest, .leftShoulder, coneAngle: .pi / 3)
        createJointIfExists(.leftShoulder, .leftUpperArm, coneAngle: .pi / 2)
        createJointIfExists(.chest, .rightShoulder, coneAngle: .pi / 3)
        createJointIfExists(.rightShoulder, .rightUpperArm, coneAngle: .pi / 2)

        // Elbow joints (hinge joints)
        createHingeJointIfExists(.leftUpperArm, .leftForearm, axis: [0, 0, 1], minAngle: 0, maxAngle: .pi * 0.8)
        createHingeJointIfExists(.rightUpperArm, .rightForearm, axis: [0, 0, 1], minAngle: -.pi * 0.8, maxAngle: 0)

        // Wrist joints (ball joints with small cone)
        createJointIfExists(.leftForearm, .leftHand, coneAngle: .pi / 4)
        createJointIfExists(.rightForearm, .rightHand, coneAngle: .pi / 4)

        // Hip joints (ball joints)
        createJointIfExists(.pelvis, .leftThigh, coneAngle: .pi / 3)
        createJointIfExists(.pelvis, .rightThigh, coneAngle: .pi / 3)

        // Knee joints (hinge joints)
        createHingeJointIfExists(.leftThigh, .leftShin, axis: [0, 0, 1], minAngle: -.pi * 0.8, maxAngle: 0)
        createHingeJointIfExists(.rightThigh, .rightShin, axis: [0, 0, 1], minAngle: -.pi * 0.8, maxAngle: 0)

        // Ankle joints (ball joints with small cone)
        createJointIfExists(.leftShin, .leftFoot, coneAngle: .pi / 6)
        createJointIfExists(.rightShin, .rightFoot, coneAngle: .pi / 6)
    }

    private func createJointIfExists(_ boneA: RobotBone, _ boneB: RobotBone, coneAngle: Float) {
        guard let entityA = boneEntities[boneA],
              let entityB = boneEntities[boneB] else { return }

        let joint = JointConstraintBuilder.createBallJoint(
            between: entityA,
            and: entityB,
            anchorA: [0, 0, 0],
            anchorB: [0, 0, 0],
            coneAngle: coneAngle
        )
        entityA.components.set(joint)
    }

    private func createHingeJointIfExists(
        _ boneA: RobotBone,
        _ boneB: RobotBone,
        axis: SIMD3<Float>,
        minAngle: Float,
        maxAngle: Float
    ) {
        guard let entityA = boneEntities[boneA],
              let entityB = boneEntities[boneB] else { return }

        let joint = JointConstraintBuilder.createHingeJoint(
            between: entityA,
            and: entityB,
            anchorA: [0, 0, 0],
            anchorB: [0, 0, 0],
            axis: axis,
            minAngle: minAngle,
            maxAngle: maxAngle
        )
        entityA.components.set(joint)
    }

    // MARK: - Physics

    private func enableRagdollPhysics() {
        // Physics is already enabled in createBoneEntity
        // This method can be used for additional physics setup if needed
        print("Ragdoll physics enabled with \(boneEntities.count) bones")
    }

    // MARK: - Interaction

    func getDraggableEntity() -> Entity? {
        return boneEntities[.chest] ?? boneEntities[.pelvis]
    }
}
