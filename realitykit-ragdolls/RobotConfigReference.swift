import RealityKit
import Foundation

// MARK: - Ragdoll Configuration
struct RagdollConfiguration {
    let boneMass: Float = 1.0
    let colliderRadius: Float = 0.05
    let jointStiffness: Float = 100.0
    let jointDamping: Float = 10.0
}

// MARK: - Bone Hierarchy Definition
enum HumanoidBone: String, CaseIterable {
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
        case .head: return 0.1
        case .chest: return 0.15
        case .pelvis: return 0.12
        case .leftHand, .rightHand: return 0.03
        case .leftFoot, .rightFoot: return 0.04
        default: return 0.05
        }
    }
    
    var mass: Float {
        switch self {
        case .head: return 4.0
        case .chest: return 15.0
        case .pelvis: return 10.0
        case .leftThigh, .rightThigh: return 7.0
        case .leftShin, .rightShin: return 4.0
        default: return 2.0
        }
    }
}

// MARK: - Joint Constraint Builder
class JointConstraintBuilder {
    
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

// MARK: - Ragdoll System
@MainActor
class RagdollSystem {
    
    private var boneEntities: [HumanoidBone: Entity] = [:]
    private var rootEntity: Entity?
    private let config: RagdollConfiguration
    
    init(config: RagdollConfiguration = RagdollConfiguration()) {
        self.config = config
    }
    
    /// Creates a ragdoll from an existing character model with skeleton
    func createRagdoll(from characterModel: ModelEntity) async throws -> Entity {
        
        // Create root entity for the ragdoll
        let ragdollRoot = Entity()
        ragdollRoot.name = "Ragdoll_Root"
        
        // Find and process skeleton joints
        if let skeleton = characterModel.components[SkeletalPoseComponent.self] {
            await processSkeletonBones(skeleton: skeleton, rootEntity: ragdollRoot)
        } else {
            // If no skeleton found, create a procedural one
            createProceduralRagdoll(rootEntity: ragdollRoot)
        }
        
        // Setup joint constraints between bones
        setupJointConstraints()
        
        // Enable ragdoll physics
        enableRagdollPhysics()
        
        self.rootEntity = ragdollRoot
        return ragdollRoot
    }
    
    /// Process existing skeleton bones and add physics
    private func processSkeletonBones(skeleton: SkeletalPoseComponent, rootEntity: Entity) async {
        
        for jointName in skeleton.jointNames {
            if let bone = HumanoidBone(rawValue: jointName) {
                
                // Get joint transform from skeleton
                if let jointIndex = skeleton.jointNames.firstIndex(of: jointName) {
                    let jointTransform = skeleton.jointTransforms[jointIndex]
                    
                    // Create bone entity with physics
                    let boneEntity = createBoneEntity(
                        bone: bone,
                        transform: jointTransform
                    )
                    
                    boneEntities[bone] = boneEntity
                    rootEntity.addChild(boneEntity)
                }
            }
        }
    }
    
    /// Create a procedural ragdoll skeleton
    private func createProceduralRagdoll(rootEntity: Entity) {
        
        // Define bone positions for a T-pose humanoid
        let bonePositions: [HumanoidBone: SIMD3<Float>] = [
            .pelvis: SIMD3(0, 1.0, 0),
            .spine: SIMD3(0, 1.2, 0),
            .chest: SIMD3(0, 1.4, 0),
            .neck: SIMD3(0, 1.6, 0),
            .head: SIMD3(0, 1.8, 0),
            
            .leftShoulder: SIMD3(-0.15, 1.5, 0),
            .leftUpperArm: SIMD3(-0.35, 1.5, 0),
            .leftForearm: SIMD3(-0.55, 1.5, 0),
            .leftHand: SIMD3(-0.7, 1.5, 0),
            
            .rightShoulder: SIMD3(0.15, 1.5, 0),
            .rightUpperArm: SIMD3(0.35, 1.5, 0),
            .rightForearm: SIMD3(0.55, 1.5, 0),
            .rightHand: SIMD3(0.7, 1.5, 0),
            
            .leftThigh: SIMD3(-0.1, 0.8, 0),
            .leftShin: SIMD3(-0.1, 0.4, 0),
            .leftFoot: SIMD3(-0.1, 0.05, 0),
            
            .rightThigh: SIMD3(0.1, 0.8, 0),
            .rightShin: SIMD3(0.1, 0.4, 0),
            .rightFoot: SIMD3(0.1, 0.05, 0)
        ]
        
        for (bone, position) in bonePositions {
            let transform = Transform(
                scale: .one,
                rotation: simd_quatf(),
                translation: position
            )
            
            let boneEntity = createBoneEntity(bone: bone, transform: transform)
            boneEntities[bone] = boneEntity
            rootEntity.addChild(boneEntity)
        }
    }
    
    /// Create individual bone entity with physics components
    private func createBoneEntity(bone: HumanoidBone, transform: Transform) -> Entity {
        
        let entity = Entity()
        entity.name = bone.rawValue
        entity.transform = transform
        
        // Add sphere collider
        let sphereShape = ShapeResource.generateSphere(radius: bone.colliderRadius)
        let collision = CollisionComponent(
            shapes: [sphereShape],
            mode: .default,
            filter: CollisionFilter(
                group: .init(rawValue: 1 << 1),
                mask: .all.subtracting(.init(rawValue: 1 << 1))
            )
        )
        entity.components.set(collision)
        
        // Add physics body
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
        physicsBody.linearDamping = 0.1
        physicsBody.angularDamping = 0.1
        
        entity.components.set(physicsBody)
        
        // Add visual representation (optional)
        let mesh = MeshResource.generateSphere(radius: bone.colliderRadius)
        let material = SimpleMaterial(color: .systemBlue.withAlphaComponent(0.3), isMetallic: false)
        entity.components.set(ModelComponent(mesh: mesh, materials: [material]))
        
        return entity
    }
    
    /// Setup joint constraints between bones
    private func setupJointConstraints() {
        
        // Define bone connections
        let boneConnections: [(parent: HumanoidBone, child: HumanoidBone, jointType: JointType)] = [
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
                    axis: SIMD3<Float>(1, 0, 0)
                )
            case .ballSocket:
                joint = JointConstraintBuilder.createBallJoint(
                    between: parentEntity,
                    and: childEntity,
                    anchorA: getConnectionPoint(from: connection.parent, to: connection.child),
                    anchorB: getConnectionPoint(from: connection.child, to: connection.parent)
                )
            }
            
            // Add joint to parent entity
            parentEntity.components.set(joint)
        }
    }
    
    /// Calculate connection points between bones
    private func getConnectionPoint(from bone: HumanoidBone, to targetBone: HumanoidBone) -> SIMD3<Float> {
        // This would be calculated based on bone geometry
        // Simplified version returns offset towards target
        return SIMD3<Float>(0, bone.colliderRadius, 0)
    }
    
    /// Enable ragdoll physics simulation
    private func enableRagdollPhysics() {
        for (_, entity) in boneEntities {
            if var physicsBody = entity.components[PhysicsBodyComponent.self] {
                physicsBody.mode = .dynamic
                physicsBody.isAffectedByGravity = true
                entity.components.set(physicsBody)
            }
        }
    }
    
    /// Apply an impulse to trigger ragdoll effect
    func applyImpulse(force: SIMD3<Float>, to bone: HumanoidBone) {
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

// MARK: - Joint Types
enum JointType {
    case hinge
    case ballSocket
}

// MARK: - Usage Example
@MainActor
class RagdollViewController {
    
    func setupRagdoll(in scene: Scene) async {
        
        // Create ragdoll system
        let ragdollSystem = RagdollSystem()
        
        // Load your character model (example)
        if let characterModel = try? await ModelEntity(named: "character") {
            
            // Create ragdoll from character
            let ragdoll = try? await ragdollSystem.createRagdoll(from: characterModel)
            
            if let ragdoll = ragdoll {
                // Add to scene
                let anchor = AnchorEntity(world: .zero)
                anchor.addChild(ragdoll)
                scene.addAnchor(anchor)
                
                // Example: Apply impulse to trigger ragdoll
                ragdollSystem.applyImpulse(
                    force: SIMD3<Float>(5, 10, 0),
                    to: .chest
                )
            }
        }
    }
}
