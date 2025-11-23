//
//  ArticulationManager.swift
//  realitykit-ragdolls
//
//  Created by ryan reede on 11/23/25.
//

import Foundation
import RealityKit
import UIKit
import simd

/// Configuration for how a joint should behave when articulated
struct JointArticulationConfig {
    let jointIndex: Int
    let jointName: String
    let allowedRotationAxes: Set<RotationAxis>
    let minAngle: Float  // in radians
    let maxAngle: Float  // in radians
    let isDraggable: Bool
    
    enum RotationAxis {
        case x, y, z
    }
    
    static func draggableHand(index: Int, name: String) -> JointArticulationConfig {
        JointArticulationConfig(
            jointIndex: index,
            jointName: name,
            allowedRotationAxes: [.x, .y, .z],
            minAngle: -.pi / 2,  // -90 degrees
            maxAngle: .pi / 2,   // 90 degrees
            isDraggable: true
        )
    }
    
    static func elbow(index: Int, name: String) -> JointArticulationConfig {
        JointArticulationConfig(
            jointIndex: index,
            jointName: name,
            allowedRotationAxes: [.x],  // Only bend in one direction
            minAngle: 0,
            maxAngle: .pi * 0.8,  // 144 degrees
            isDraggable: false
        )
    }
}

/// Manages skeleton articulation and joint manipulation
class ArticulationManager {
    
    // MARK: - Properties
    
    private var articulatedJoints: [Int: ArticulatedJoint] = [:]
    private var jointConfigs: [Int: JointArticulationConfig] = [:]
    private weak var skeletalEntity: Entity?
    
    // MARK: - Public Methods
    
    /// Sets up articulation for a skeleton
    /// - Parameters:
    ///   - entity: The entity containing the skeleton
    ///   - skeletonInfo: Information about the skeleton structure
    ///   - configs: Configuration for which joints to articulate
    func setupArticulation(
        for entity: Entity,
        skeletonInfo: SkeletonInfo,
        configs: [JointArticulationConfig]
    ) {
        print("\n=== Setting up Articulation ===")
        print("Configuring \(configs.count) joints for articulation")
        
        // Store the skeletal entity reference
        self.skeletalEntity = findSkeletalEntity(in: entity)
        
        if self.skeletalEntity == nil {
            print("⚠️ Warning: Could not find entity with SkeletalPosesComponent")
        }
        
        // Store configs
        for config in configs {
            jointConfigs[config.jointIndex] = config
            print("Joint [\(config.jointIndex)] \(config.jointName): draggable=\(config.isDraggable)")
        }
        
        // Create visual markers and collision shapes for draggable joints
        for config in configs where config.isDraggable {
            if let pose = skeletonInfo.primaryPose,
               let joint = pose.joint(at: config.jointIndex) {
                createDraggableMarker(for: joint, in: entity, config: config)
            }
        }
    }
    
    /// Finds the entity that contains the SkeletalPosesComponent
    /// - Parameter entity: The root entity to search
    /// - Returns: The entity with SkeletalPosesComponent if found
    private func findSkeletalEntity(in entity: Entity) -> Entity? {
        if entity.components.has(SkeletalPosesComponent.self) {
            return entity
        }
        
        for child in entity.children {
            if let found = findSkeletalEntity(in: child) {
                return found
            }
        }
        
        return nil
    }
    
    /// Identifies common joints in a skeleton for articulation
    /// - Parameter skeletonInfo: The skeleton information
    /// - Returns: Array of suggested joint configurations
    static func identifyArticulationJoints(from skeletonInfo: SkeletonInfo) -> [JointArticulationConfig] {
        var configs: [JointArticulationConfig] = []
        
        print("\n=== Analyzing Joints for Articulation ===")
        print("Total joints in skeleton: \(skeletonInfo.jointNames.count)")
        print("\nAll joint names:")
        for (index, jointName) in skeletonInfo.jointNames.enumerated() {
            print("  [\(index)] \(jointName)")
        }
        
        // Common joint name patterns - expanded for more variations
        let handPatterns = ["hand", "wrist", "palm", "finger", "thumb"]
        let elbowPatterns = ["elbow", "forearm", "lower_arm", "lowerarm"]
        let shoulderPatterns = ["shoulder", "upperarm", "upper_arm", "clavicle", "collar"]
        let armPatterns = ["arm", "limb"]  // Generic arm patterns
        
        print("\nSearching for matching joints...")
        
        for (index, jointName) in skeletonInfo.jointNames.enumerated() {
            let nameLower = jointName.lowercased()
            
            // Check for hands (most important for interaction)
            if handPatterns.contains(where: { nameLower.contains($0) }) {
                configs.append(.draggableHand(index: index, name: jointName))
                print("✓ Found hand joint: \(jointName) at index \(index)")
            }
            // Check for elbows
            else if elbowPatterns.contains(where: { nameLower.contains($0) }) {
                configs.append(.elbow(index: index, name: jointName))
                print("✓ Found elbow joint: \(jointName) at index \(index)")
            }
            // Check for shoulders
            else if shoulderPatterns.contains(where: { nameLower.contains($0) }) {
                configs.append(JointArticulationConfig(
                    jointIndex: index,
                    jointName: jointName,
                    allowedRotationAxes: [.x, .y, .z],
                    minAngle: -.pi,
                    maxAngle: .pi,
                    isDraggable: false
                ))
                print("✓ Found shoulder joint: \(jointName) at index \(index)")
            }
            // Generic arm detection - make draggable as fallback
            else if armPatterns.contains(where: { nameLower.contains($0) }) {
                configs.append(.draggableHand(index: index, name: jointName))
                print("✓ Found arm joint (made draggable): \(jointName) at index \(index)")
            }
        }
        
        // If still no joints found, make a few end joints draggable
        if configs.isEmpty {
            print("\n⚠️ No joints matched patterns. Using heuristic approach...")
            
            // Find joints that might be extremities (typically later in the list)
            let jointCount = skeletonInfo.jointNames.count
            if jointCount >= 10 {
                // Make some later joints draggable (often hands/feet)
                let candidateIndices = [
                    jointCount - 1,  // Last joint
                    jointCount - 2,  // Second to last
                    jointCount / 2,  // Middle joint
                ]
                
                for index in candidateIndices where index >= 0 && index < jointCount {
                    configs.append(.draggableHand(
                        index: index,
                        name: skeletonInfo.jointNames[index]
                    ))
                    print("✓ Made joint draggable: \(skeletonInfo.jointNames[index]) at index \(index)")
                }
            } else if jointCount > 0 {
                // Small skeleton - just make the last joint draggable
                let lastIndex = jointCount - 1
                configs.append(.draggableHand(
                    index: lastIndex,
                    name: skeletonInfo.jointNames[lastIndex]
                ))
                print("✓ Made last joint draggable: \(skeletonInfo.jointNames[lastIndex])")
            }
        }
        
        print("\nTotal articulation joints configured: \(configs.count)")
        return configs
    }
    
    /// Handles drag gesture on a joint
    /// - Parameters:
    ///   - jointIndex: The index of the joint being dragged
    ///   - translation: The translation vector from the drag
    func handleJointDrag(jointIndex: Int, translation: SIMD3<Float>) {
        guard let joint = articulatedJoints[jointIndex],
              let skelEntity = skeletalEntity,
              var skeletalPoses = skelEntity.components[SkeletalPosesComponent.self] else {
            print("⚠️ Cannot update joint - missing skeletal data")
            return
        }
        
        // Update marker position
        joint.handleDrag(translation: translation)
        
        // Update the actual skeleton joint
        guard !skeletalPoses.poses.isEmpty else { return }
        
        var pose = skeletalPoses.poses[0]
        guard jointIndex < pose.jointTransforms.count else { return }
        
        // Calculate rotation based on drag
        // Simple rotation: convert translation to rotation around axes
        let rotationAmount = length(translation) * 0.5
        let rotationAxis = normalize(SIMD3<Float>(translation.y, -translation.x, 0))
        
        let currentTransform = pose.jointTransforms[jointIndex]
        let dragRotation = simd_quatf(angle: rotationAmount, axis: rotationAxis)
        
        // Apply rotation to joint
        var newTransform = currentTransform
        newTransform.rotation = dragRotation * currentTransform.rotation
        
        pose.jointTransforms[jointIndex] = newTransform
        skeletalPoses.poses[0] = pose
        
        // Update the component
        skelEntity.components.set(skeletalPoses)
        
        print("Updated joint \(jointIndex) with rotation")
    }
    
    // MARK: - Private Methods
    
    /// Creates a visible draggable marker for a joint
    /// - Parameters:
    ///   - joint: The joint to create a marker for
    ///   - parentEntity: The parent entity to add the marker to
    ///   - config: Configuration for the joint
    private func createDraggableMarker(
        for joint: Joint,
        in parentEntity: Entity,
        config: JointArticulationConfig
    ) {
        // Create a larger, more visible sphere mesh for the joint marker
        let sphereMesh = MeshResource.generateSphere(radius: 0.15)
        
        var material = PhysicallyBasedMaterial()
        material.baseColor = .init(tint: .systemBlue.withAlphaComponent(0.8))
        material.metallic = .init(floatLiteral: 0.7)
        material.roughness = .init(floatLiteral: 0.3)
        material.emissiveColor = .init(color: .systemBlue.withAlphaComponent(0.5))
        material.emissiveIntensity = 2.0
        
        let markerEntity = ModelEntity(mesh: sphereMesh, materials: [material])
        markerEntity.name = "marker_\(config.jointName)"
        
        // Position the marker - offset upward to be visible
        // Since joint translations are in skeleton local space and often near origin,
        // we'll position markers at reasonable locations relative to the model
        let markerPosition: SIMD3<Float>
        
        if abs(joint.translation.x) < 0.1 && abs(joint.translation.y) < 0.1 && abs(joint.translation.z) < 0.1 {
            // Joint is near origin in skeleton space, distribute markers around the model
            let angle = Float(config.jointIndex) * (2 * .pi / 3)
            let radius: Float = 1.5
            markerPosition = SIMD3<Float>(
                cos(angle) * radius,
                1.0 + Float(config.jointIndex % 3) * 0.5,  // Vary height
                sin(angle) * radius
            )
            print("⚠️ Joint \(config.jointName) at skeleton origin, placing marker at distributed position: \(markerPosition)")
        } else {
            // Use joint's actual position, scaled up if needed
            let scale: Float = 10.0  // Scale factor to make skeleton space visible
            markerPosition = joint.translation * scale
            print("Using scaled joint position for \(config.jointName): \(markerPosition)")
        }
        
        markerEntity.position = markerPosition
        
        // Add collision for interaction
        markerEntity.generateCollisionShapes(recursive: false)
        
        // Enable input target for gestures - use all input types
        markerEntity.components.set(InputTargetComponent(allowedInputTypes: .all))
        
        // Add physics body (kinematic so it can be moved but affects others)
        markerEntity.components.set(PhysicsBodyComponent(
            massProperties: .default,
            material: .default,
            mode: .kinematic
        ))
        
        // Add custom component to store joint info
        markerEntity.components.set(JointMarkerComponent(
            jointIndex: config.jointIndex,
            jointName: config.jointName,
            isDraggable: config.isDraggable
        ))
        
        parentEntity.addChild(markerEntity)
        
        // Store the articulated joint
        let articulatedJoint = ArticulatedJoint(
            config: config,
            markerEntity: markerEntity,
            initialTransform: Transform(
                scale: [1, 1, 1],
                rotation: joint.rotation,
                translation: markerPosition
            )
        )
        articulatedJoints[config.jointIndex] = articulatedJoint
        
        print("✓ Created visible marker for \(config.jointName) at position \(markerPosition)")
    }
}

// MARK: - Supporting Types

/// Represents an articulated joint that can be manipulated
private class ArticulatedJoint {
    let config: JointArticulationConfig
    let markerEntity: ModelEntity
    let initialTransform: Transform
    
    init(config: JointArticulationConfig, markerEntity: ModelEntity, initialTransform: Transform) {
        self.config = config
        self.markerEntity = markerEntity
        self.initialTransform = initialTransform
    }
    
    func handleDrag(translation: SIMD3<Float>) {
        // Update marker position
        let newPosition = initialTransform.translation + translation
        markerEntity.position = newPosition
        
        // TODO: Update actual skeleton joint rotation based on IK
        // This would involve inverse kinematics calculations
    }
}

