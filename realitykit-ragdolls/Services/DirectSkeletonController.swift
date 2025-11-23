//
//  DirectSkeletonController.swift
//  realitykit-ragdolls
//
//  Created by ryan reede on 11/23/25.
//

import Foundation
import RealityKit
import UIKit

/// Directly controls skeleton joints by modifying SkeletalPosesComponent
class DirectSkeletonController {
    
    // MARK: - Properties
    
    private weak var skeletalEntity: Entity?
    private var controlMarkers: [Int: ModelEntity] = [:]
    private var originalTransforms: [Int: Transform] = [:]
    
    // MARK: - Setup
    
    /// Sets up direct control for skeleton joints
    /// - Parameters:
    ///   - entity: The root entity containing the skeleton
    ///   - jointIndices: Which joints to make controllable
    ///   - parentEntity: Where to add visual markers
    func setup(
        skeletalRoot: Entity,
        controlJoints: [Int],
        in parentEntity: Entity
    ) -> Bool {
        print("\n=== Setting Up Direct Skeleton Control ===")
        
        // Find the skeletal entity
        guard let skelEntity = findSkeletalEntity(in: skeletalRoot) else {
            print("❌ Could not find skeletal entity")
            return false
        }
        
        self.skeletalEntity = skelEntity
        print("✓ Found skeletal entity: \(skelEntity.name)")
        
        // Get initial pose and save ALL original transforms
        guard var skeletalPoses = skelEntity.components[SkeletalPosesComponent.self],
              !skeletalPoses.poses.isEmpty else {
            print("❌ No skeletal poses found")
            return false
        }
        
        let pose = skeletalPoses.poses[0]
        print("✓ Skeleton has \(pose.jointTransforms.count) joints")
        
        // Store ALL original transforms for proper reset
        for jointIndex in 0..<pose.jointTransforms.count {
            originalTransforms[jointIndex] = pose.jointTransforms[jointIndex]
        }
        print("✓ Saved original transforms for all \(pose.jointTransforms.count) joints")
        
        print("✅ Direct skeleton control ready")
        return true
    }
    
    // MARK: - Control Methods
    
    /// Rotates a joint based on drag input
    /// - Parameters:
    ///   - jointIndex: The joint to rotate
    ///   - rotation: The rotation to apply
    func rotateJoint(_ jointIndex: Int, by rotation: simd_quatf) {
        guard let skelEntity = skeletalEntity,
              var skeletalPoses = skelEntity.components[SkeletalPosesComponent.self],
              !skeletalPoses.poses.isEmpty else {
            return
        }
        
        var pose = skeletalPoses.poses[0]
        guard jointIndex < pose.jointTransforms.count else {
            return
        }
        
        // Get current transform
        var transform = pose.jointTransforms[jointIndex]
        
        // Apply rotation
        transform.rotation = rotation * transform.rotation
        
        // Update the pose
        pose.jointTransforms[jointIndex] = transform
        skeletalPoses.poses[0] = pose
        
        // Write back to component
        skelEntity.components.set(skeletalPoses)
        
        print("Rotated joint \(jointIndex)")
    }
    
    /// Sets a joint to a specific rotation
    /// - Parameters:
    ///   - jointIndex: The joint to rotate
    ///   - rotation: The absolute rotation to set
    func setJointRotation(_ jointIndex: Int, to rotation: simd_quatf) {
        guard let skelEntity = skeletalEntity,
              var skeletalPoses = skelEntity.components[SkeletalPosesComponent.self],
              !skeletalPoses.poses.isEmpty else {
            return
        }
        
        var pose = skeletalPoses.poses[0]
        guard jointIndex < pose.jointTransforms.count else {
            return
        }
        
        // Get current transform
        var transform = pose.jointTransforms[jointIndex]
        
        // Set rotation
        transform.rotation = rotation
        
        // Update the pose
        pose.jointTransforms[jointIndex] = transform
        skeletalPoses.poses[0] = pose
        
        // Write back to component
        skelEntity.components.set(skeletalPoses)
        
        // Update marker position if it exists
        if let marker = controlMarkers[jointIndex] {
            // Marker follows the joint (simplified - in reality would need FK)
            print("Updated joint \(jointIndex) rotation")
        }
    }
    
    
    
    
    /// Creates control handles: one for root, and one for each wrist
    /// - Parameter modelEntity: The robot model entity to position markers relative to
    func createInteractiveControls(modelEntity: Entity, in parentEntity: Entity) {
        print("\n🎮 Creating control handles...")
        
        let modelPos = modelEntity.position
        
        // 1. Root control (green) - moves whole character
        let rootMarker = createControlMarker(
            for: 0,
            at: modelPos + SIMD3<Float>(0, 2.0, 0),
            color: .systemGreen,
            name: "control_root"
        )
        parentEntity.addChild(rootMarker)
        controlMarkers[0] = rootMarker
        print("   🟢 Root control created")
        
        // 2. Right wrist control (red) - IK for right arm
        let rightWristMarker = createControlMarker(
            for: 38,  // Right wrist joint
            at: modelPos + SIMD3<Float>(0.5, 1.0, 0.3),
            color: .systemRed,
            name: "control_right_wrist"
        )
        parentEntity.addChild(rightWristMarker)
        controlMarkers[38] = rightWristMarker
        print("   🔴 Right wrist control created")
        
        // 3. Left wrist control (blue) - IK for left arm
        let leftWristMarker = createControlMarker(
            for: 66,  // Left wrist joint
            at: modelPos + SIMD3<Float>(-0.5, 1.0, 0.3),
            color: .systemBlue,
            name: "control_left_wrist"
        )
        parentEntity.addChild(leftWristMarker)
        controlMarkers[66] = leftWristMarker
        print("   🔵 Left wrist control created")
        
        print("   🎉 Controls ready!")
        print("      🟢 = Move character")
        print("      🔴 = Right arm IK")
        print("      🔵 = Left arm IK")
    }
    
    /// Moves the root joint (whole character) based on marker position
    /// - Parameters:
    ///   - jointIndex: Should be 0 (root)
    ///   - newPosition: The new position for the marker/character
    func moveCharacter(to newPosition: SIMD3<Float>) {
        guard let skelEntity = skeletalEntity,
              var skeletalPoses = skelEntity.components[SkeletalPosesComponent.self],
              !skeletalPoses.poses.isEmpty else {
            return
        }
        
        var pose = skeletalPoses.poses[0]
        
        // Update root joint translation (moves whole character)
        var rootTransform = pose.jointTransforms[0]
        rootTransform.translation = newPosition
        pose.jointTransforms[0] = rootTransform
        
        skeletalPoses.poses[0] = pose
        skelEntity.components.set(skeletalPoses)
        
        //print("   → Character moved to: \(newPosition)")
    }
    
    /// Resets the robot to a neutral standing pose
    func resetToNeutralPose() {
        guard let skelEntity = skeletalEntity,
              var skeletalPoses = skelEntity.components[SkeletalPosesComponent.self],
              !skeletalPoses.poses.isEmpty else {
            return
        }
        
        var pose = skeletalPoses.poses[0]
        
        // Reset all joints to original transforms
        for index in 0..<pose.jointTransforms.count {
            if let originalTransform = originalTransforms[index] {
                var transform = originalTransform
                
                // Force root joint (0) to identity rotation to prevent whole-body rotation
                if index == 0 {
                    transform.rotation = simd_quatf(angle: 0, axis: [0, 1, 0])  // Identity rotation
                    print("  → Corrected root joint rotation to upright")
                }
                
                pose.jointTransforms[index] = transform
            }
        }
        
        skeletalPoses.poses[0] = pose
        skelEntity.components.set(skeletalPoses)
        
        print("✓ Reset robot to neutral upright pose")
    }
    
    
    /// Resets a joint to its original transform
    /// - Parameter jointIndex: The joint to reset
    func resetJoint(_ jointIndex: Int) {
        guard let originalTransform = originalTransforms[jointIndex] else {
            return
        }
        
        setJointRotation(jointIndex, to: originalTransform.rotation)
        print("Reset joint \(jointIndex) to original rotation")
    }
    
    // MARK: - Private Methods
    
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
    
    private func createControlMarker(
        for jointIndex: Int,
        at position: SIMD3<Float>,
        color: UIColor,
        name: String
    ) -> ModelEntity {
        let mesh = MeshResource.generateSphere(radius: 0.12)
        
        var material = PhysicallyBasedMaterial()
        material.baseColor = .init(tint: color.withAlphaComponent(0.95))
        material.emissiveColor = .init(color: color.withAlphaComponent(0.7))
        material.emissiveIntensity = 5.0
        
        let marker = ModelEntity(mesh: mesh, materials: [material])
        marker.name = name
        marker.position = position
        
        // Enable interaction
        marker.components.set(InputTargetComponent(allowedInputTypes: .all))
        marker.generateCollisionShapes(recursive: false)
        
        // Store joint index
        marker.components.set(JointMarkerComponent(
            jointIndex: jointIndex,
            jointName: "joint_\(jointIndex)",
            isDraggable: true
        ))
        
        return marker
    }
    
    /// Moves an arm using IK when wrist is dragged
    /// - Parameters:
    ///   - wristJoint: Wrist joint index (38 for right, 66 for left)
    ///   - targetPosition: Where the wrist should be
    func moveArmIK(wristJoint: Int, to targetPosition: SIMD3<Float>) {
        guard let skelEntity = skeletalEntity,
              var skeletalPoses = skelEntity.components[SkeletalPosesComponent.self],
              !skeletalPoses.poses.isEmpty else {
            return
        }
        
        var pose = skeletalPoses.poses[0]
        
        // Determine which arm (right or left)
        let isRightArm = (wristJoint == 38)
        let shoulderJoint = isRightArm ? 36 : 64
        let elbowJoint = isRightArm ? 37 : 65
        
        // Get shoulder position (assume at origin for now, can be improved)
        let shoulderTransform = pose.jointTransforms[shoulderJoint]
        let shoulderPos = shoulderTransform.translation
        
        // Arm segment lengths (estimated - can be measured from model)
        let upperArmLength: Float = 0.3  // shoulder to elbow
        let forearmLength: Float = 0.25  // elbow to wrist
        
        // Solve IK
        let ikResult = IKSolver.solveTwoBoneIK(
            shoulderPos: shoulderPos,
            targetPos: targetPosition,
            upperLength: upperArmLength,
            lowerLength: forearmLength
        )
        
        // Apply rotations to skeleton
        var shoulderT = pose.jointTransforms[shoulderJoint]
        shoulderT.rotation = ikResult.shoulderRotation
        pose.jointTransforms[shoulderJoint] = shoulderT
        
        var elbowT = pose.jointTransforms[elbowJoint]
        elbowT.rotation = ikResult.elbowRotation
        pose.jointTransforms[elbowJoint] = elbowT
        
        skeletalPoses.poses[0] = pose
        skelEntity.components.set(skeletalPoses)
        
        print("   → \(isRightArm ? "Right" : "Left") arm IK to: \(targetPosition)")
    }
}

