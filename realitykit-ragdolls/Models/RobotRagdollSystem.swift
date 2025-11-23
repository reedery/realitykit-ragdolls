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
    case pelvis = "pelvis"
    case spine = "spine"
    case chest = "chest"
    case neck = "neck"
    case head = "head"
    case leftShoulder = "left_shoulder"
    case leftUpperArm = "left_upper_arm"
    case leftForearm = "left_forearm"
    case leftHand = "left_hand"
    case rightShoulder = "right_shoulder"
    case rightUpperArm = "right_upper_arm"
    case rightForearm = "right_forearm"
    case rightHand = "right_hand"
    case leftThigh = "left_thigh"
    case leftShin = "left_shin"
    case leftFoot = "left_foot"
    case rightThigh = "right_thigh"
    case rightShin = "right_shin"
    case rightFoot = "right_foot"

    var colliderRadius: Float {
        switch self {
        case .head:
            return 0.1
        case .chest:
            return 0.15
        case .pelvis:
            return 0.12
        case .spine:
            return 0.1
        case .neck:
            return 0.06
        case .leftShoulder, .rightShoulder:
            return 0.07
        case .leftUpperArm, .rightUpperArm, .leftThigh, .rightThigh:
            return 0.06
        case .leftForearm, .rightForearm, .leftShin, .rightShin:
            return 0.05
        case .leftHand, .rightHand:
            return 0.03
        case .leftFoot, .rightFoot:
            return 0.04
        }
    }

    var mass: Float {
        switch self {
        case .head:
            return 4.0
        case .chest:
            return 15.0
        case .pelvis:
            return 10.0
        case .spine:
            return 8.0
        case .neck:
            return 2.0
        case .leftShoulder, .rightShoulder:
            return 2.5
        case .leftUpperArm, .rightUpperArm:
            return 3.0
        case .leftForearm, .rightForearm:
            return 2.0
        case .leftHand, .rightHand:
            return 1.0
        case .leftThigh, .rightThigh:
            return 7.0
        case .leftShin, .rightShin:
            return 4.0
        case .leftFoot, .rightFoot:
            return 1.5
        }
    }
}

// MARK: - Joint Type

enum JointType {
    case hinge
    case ballSocket
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
        // Create T-pose humanoid structure (more realistic proportions)
        let positions: [RobotBone: SIMD3<Float>] = [
            .pelvis: [0, 1.0, 0],
            .spine: [0, 1.2, 0],
            .chest: [0, 1.4, 0],
            .neck: [0, 1.6, 0],
            .head: [0, 1.8, 0],

            // Left arm (T-pose)
            .leftShoulder: [-0.15, 1.5, 0],
            .leftUpperArm: [-0.35, 1.5, 0],
            .leftForearm: [-0.55, 1.5, 0],
            .leftHand: [-0.7, 1.5, 0],

            // Right arm (T-pose)
            .rightShoulder: [0.15, 1.5, 0],
            .rightUpperArm: [0.35, 1.5, 0],
            .rightForearm: [0.55, 1.5, 0],
            .rightHand: [0.7, 1.5, 0],

            // Left leg
            .leftThigh: [-0.1, 0.8, 0],
            .leftShin: [-0.1, 0.4, 0],
            .leftFoot: [-0.1, 0.05, 0],

            // Right leg
            .rightThigh: [0.1, 0.8, 0],
            .rightShin: [0.1, 0.4, 0],
            .rightFoot: [0.1, 0.05, 0]
        ]

        for bone in RobotBone.allCases {
            guard let position = positions[bone] else { continue }

            let transform = Transform(
                scale: .one,
                rotation: simd_quatf(),
                translation: position
            )
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

        // Create visual representation (sphere)
        let mesh = MeshResource.generateSphere(radius: bone.colliderRadius)
        var material = PhysicallyBasedMaterial()
        material.baseColor = PhysicallyBasedMaterial.BaseColor(
            tint: getBoneColor(for: bone)
        )
        material.roughness = 0.7
        material.metallic = 0.2

        entity.components.set(ModelComponent(mesh: mesh, materials: [material]))

        // Collision with filtering to prevent self-collision
        let collisionShape = ShapeResource.generateSphere(radius: bone.colliderRadius)
        let collision = CollisionComponent(
            shapes: [collisionShape],
            mode: .default,
            filter: CollisionFilter(
                group: .init(rawValue: 1 << 1),
                mask: .all.subtracting(.init(rawValue: 1 << 1))
            )
        )
        entity.components.set(collision)

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

        // Set initial velocities to zero
        physicsBody.linearVelocity = .zero
        physicsBody.angularVelocity = .zero

        // Add damping for stability
        physicsBody.linearDamping = config.linearDamping
        physicsBody.angularDamping = config.angularDamping
        physicsBody.isAffectedByGravity = true

        entity.components.set(physicsBody)

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
        // Define bone connections with joint types
        let boneConnections: [(parent: RobotBone, child: RobotBone, jointType: JointType)] = [
            // Spine chain
            (.pelvis, .spine, .ballSocket),
            (.spine, .chest, .ballSocket),
            (.chest, .neck, .ballSocket),
            (.neck, .head, .ballSocket),

            // Left arm
            (.chest, .leftShoulder, .ballSocket),
            (.leftShoulder, .leftUpperArm, .ballSocket),
            (.leftUpperArm, .leftForearm, .hinge),
            (.leftForearm, .leftHand, .ballSocket),

            // Right arm
            (.chest, .rightShoulder, .ballSocket),
            (.rightShoulder, .rightUpperArm, .ballSocket),
            (.rightUpperArm, .rightForearm, .hinge),
            (.rightForearm, .rightHand, .ballSocket),

            // Left leg
            (.pelvis, .leftThigh, .ballSocket),
            (.leftThigh, .leftShin, .hinge),
            (.leftShin, .leftFoot, .hinge),

            // Right leg
            (.pelvis, .rightThigh, .ballSocket),
            (.rightThigh, .rightShin, .hinge),
            (.rightShin, .rightFoot, .hinge)
        ]

        for connection in boneConnections {
            guard let parentEntity = boneEntities[connection.parent],
                  let childEntity = boneEntities[connection.child] else {
                continue
            }

            let joint: PhysicsJointComponent

            switch connection.jointType {
            case .hinge:
                joint = JointConstraintBuilder.createHingeJoint(
                    between: parentEntity,
                    and: childEntity,
                    anchorA: getConnectionPoint(from: connection.parent, to: connection.child),
                    anchorB: getConnectionPoint(from: connection.child, to: connection.parent),
                    axis: SIMD3<Float>(1, 0, 0),
                    minAngle: -.pi / 2,
                    maxAngle: .pi / 2
                )
            case .ballSocket:
                joint = JointConstraintBuilder.createBallJoint(
                    between: parentEntity,
                    and: childEntity,
                    anchorA: getConnectionPoint(from: connection.parent, to: connection.child),
                    anchorB: getConnectionPoint(from: connection.child, to: connection.parent),
                    coneAngle: .pi / 4
                )
            }

            // Add joint to parent entity
            parentEntity.components.set(joint)
        }
    }

    /// Calculate connection points between bones
    private func getConnectionPoint(from bone: RobotBone, to targetBone: RobotBone) -> SIMD3<Float> {
        // For simplified version, return offset based on bone's collider radius
        // This creates connection points at the edges of the spheres
        return SIMD3<Float>(0, bone.colliderRadius * 0.5, 0)
    }

    // MARK: - Physics

    private func enableRagdollPhysics() {
        for (_, entity) in boneEntities {
            if var physicsBody = entity.components[PhysicsBodyComponent.self] {
                physicsBody.mode = .dynamic
                physicsBody.isAffectedByGravity = true
                entity.components.set(physicsBody)
            }
        }
        print("Ragdoll physics enabled with \(boneEntities.count) bones")
    }

    // MARK: - Interaction

    func getDraggableEntity() -> Entity? {
        return boneEntities[.chest] ?? boneEntities[.pelvis]
    }

    /// Apply an impulse to trigger ragdoll effect
    func applyImpulse(force: SIMD3<Float>, to bone: RobotBone) {
        guard let entity = boneEntities[bone],
              var physicsBody = entity.components[PhysicsBodyComponent.self] else {
            return
        }

        physicsBody.applyLinearImpulse(force, relativeTo: nil)
        entity.components.set(physicsBody)
    }

    /// Switch between animated and ragdoll mode
    func setRagdollEnabled(_ enabled: Bool) {
        for (_, entity) in boneEntities {
            if var physicsBody = entity.components[PhysicsBodyComponent.self] {
                physicsBody.mode = enabled ? .dynamic : .kinematic
                entity.components.set(physicsBody)
            }
        }
    }
}
