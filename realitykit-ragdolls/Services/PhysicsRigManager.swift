//
//  PhysicsRigManager.swift
//  realitykit-ragdolls
//
//  Created by ryan reede on 11/23/25.
//

import Foundation
import RealityKit
import UIKit
import simd

/// Manages physics-based articulation using rigid bodies and joints
class PhysicsRigManager {
    
    // MARK: - Types
    
    struct BoneSegment {
        let startJointIndex: Int
        let endJointIndex: Int
        let startPosition: SIMD3<Float>
        let endPosition: SIMD3<Float>
        let rigidBody: ModelEntity
        let name: String
    }
    
    // MARK: - Properties
    
    private var boneSegments: [BoneSegment] = []
    private var physicsJoints: [Entity] = []
    
    // MARK: - Public Methods
    
    /// Creates a simple test rig with one articulated arm segment
    /// - Parameters:
    ///   - parentEntity: The entity to attach physics bodies to
    ///   - skeletonInfo: Information about the skeleton
    /// - Returns: The draggable end marker entity
    func createTestArmRig(
        in parentEntity: Entity,
        skeletonInfo: SkeletonInfo
    ) -> ModelEntity? {
        print("\n=== Creating Physics Test Rig ===")
        
        guard let pose = skeletonInfo.primaryPose,
              pose.jointCount >= 2 else {
            print("⚠️ Not enough joints for test rig")
            return nil
        }
        
        // Pick two joints to connect (we'll use indices we found earlier)
        let startJointIdx = 45  // Middle joint from your logs
        let endJointIdx = 89    // One of the end joints
        
        guard let startJoint = pose.joint(at: startJointIdx),
              let endJoint = pose.joint(at: endJointIdx) else {
            print("⚠️ Could not get joints at indices \(startJointIdx) and \(endJointIdx)")
            return nil
        }
        
        print("Creating arm segment between:")
        print("  Start: \(startJoint.name) at \(startJoint.translation)")
        print("  End: \(endJoint.name) at \(endJoint.translation)")
        
        // Create positions in world space
        let startPos = SIMD3<Float>(0, 1.5, 0)  // Shoulder height
        let endPos = SIMD3<Float>(0.5, 1.0, 0)  // Hand position (lower and to the side)
        
        // Create the bone segment as a cylinder
        let boneEntity = createBoneVisual(from: startPos, to: endPos)
        boneEntity.name = "bone_\(startJoint.name)_to_\(endJoint.name)"
        
        // Add physics to the bone - use kinematic so we control it, not gravity
        boneEntity.components.set(PhysicsBodyComponent(
            massProperties: .default,
            material: .default,
            mode: .kinematic  // Kinematic - we control position/rotation, no gravity
        ))
        
        // Enable collision
        boneEntity.generateCollisionShapes(recursive: false)
        
        parentEntity.addChild(boneEntity)
        
        // Create an anchor point at the shoulder (fixed in space)
        let shoulderAnchor = createAnchorPoint(at: startPos, name: "shoulder_anchor")
        parentEntity.addChild(shoulderAnchor)
        
        // Create a ball-and-socket joint connecting shoulder anchor to bone
        let joint = createBallSocketJoint(
            from: shoulderAnchor,
            to: boneEntity,
            at: startPos
        )
        parentEntity.addChild(joint)
        physicsJoints.append(joint)
        
        // Create draggable marker at the hand
        let handMarker = createDraggableMarker(at: endPos, name: "hand_marker")
        
        // Note: Don't attach marker to bone - keep it independent for dragging
        // We'll manually update bone based on marker position
        parentEntity.addChild(handMarker)
        
        // Store the bone segment
        let segment = BoneSegment(
            startJointIndex: startJointIdx,
            endJointIndex: endJointIdx,
            startPosition: startPos,
            endPosition: endPos,
            rigidBody: boneEntity,
            name: "test_arm"
        )
        boneSegments.append(segment)
        
        print("✓ Created physics test rig with 1 arm segment")
        print("  Bone entity: \(boneEntity.name)")
        print("  Try dragging the hand marker!")
        
        return handMarker
    }
    
    // MARK: - Private Methods
    
    /// Creates a visual representation of a bone
    private func createBoneVisual(from start: SIMD3<Float>, to end: SIMD3<Float>) -> ModelEntity {
        let direction = end - start
        let length = simd_length(direction)
        let radius: Float = 0.05
        
        // Create cylinder mesh
        let mesh = MeshResource.generateBox(
            width: radius * 2,
            height: length,
            depth: radius * 2
        )
        
        var material = PhysicallyBasedMaterial()
        material.baseColor = .init(tint: .systemOrange.withAlphaComponent(0.8))
        material.metallic = .init(floatLiteral: 0.5)
        material.roughness = .init(floatLiteral: 0.3)
        
        let boneEntity = ModelEntity(mesh: mesh, materials: [material])
        
        // Position at midpoint
        let midpoint = (start + end) / 2
        boneEntity.position = midpoint
        
        // Rotate to align with direction
        let up = SIMD3<Float>(0, 1, 0)
        if length > 0.001 {
            let normalizedDir = simd_normalize(direction)
            let rotation = simd_quatf(from: up, to: normalizedDir)
            boneEntity.orientation = rotation
        }
        
        return boneEntity
    }
    
    /// Creates a fixed anchor point
    private func createAnchorPoint(at position: SIMD3<Float>, name: String) -> ModelEntity {
        let mesh = MeshResource.generateSphere(radius: 0.08)
        
        var material = PhysicallyBasedMaterial()
        material.baseColor = .init(tint: .systemRed.withAlphaComponent(0.9))
        
        let anchor = ModelEntity(mesh: mesh, materials: [material])
        anchor.name = name
        anchor.position = position
        
        // Static physics body - doesn't move
        anchor.components.set(PhysicsBodyComponent(
            massProperties: .default,
            material: .default,
            mode: .static
        ))
        
        anchor.generateCollisionShapes(recursive: false)
        
        return anchor
    }
    
    /// Creates a connection between two entities
    /// Note: RealityKit's physics joint API is limited on iOS/visionOS
    /// We'll use a simpler constraint-based approach instead
    private func createBallSocketJoint(
        from anchor: Entity,
        to body: Entity,
        at position: SIMD3<Float>
    ) -> Entity {
        // Create a visual indicator for the joint
        let jointEntity = Entity()
        jointEntity.name = "joint_\(anchor.name)_to_\(body.name)"
        jointEntity.position = position
        
        // For now, we'll rely on manual constraint enforcement
        // The arm bone's one end is "attached" to the anchor conceptually
        // When we drag the other end, we'll rotate the bone around this point
        
        print("Created joint connection point between \(anchor.name) and \(body.name)")
        print("Note: Using manual constraints instead of physics joints")
        
        return jointEntity
    }
    
    /// Creates a draggable marker
    private func createDraggableMarker(at position: SIMD3<Float>, name: String) -> ModelEntity {
        let mesh = MeshResource.generateSphere(radius: 0.12)
        
        var material = PhysicallyBasedMaterial()
        material.baseColor = .init(tint: .systemGreen.withAlphaComponent(0.9))
        material.emissiveColor = .init(color: .systemGreen.withAlphaComponent(0.5))
        material.emissiveIntensity = 2.0
        
        let marker = ModelEntity(mesh: mesh, materials: [material])
        marker.name = name
        marker.position = position  // World position
        
        // Enable interaction
        marker.components.set(InputTargetComponent(allowedInputTypes: .all))
        marker.generateCollisionShapes(recursive: false)
        
        return marker
    }
    
    /// Applies force to move a marker (and its attached bone)
    func dragMarker(named name: String, to position: SIMD3<Float>, marker: Entity) {
        // Update marker position
        marker.position = position
        
        // Find the corresponding bone segment and update its rotation
        if let segment = boneSegments.first {
            // Calculate new bone rotation based on drag position
            updateBoneRotation(segment: segment, handPosition: position)
            print("Updated bone rotation based on hand position: \(position)")
        }
    }
    
    /// Updates bone rotation to point from shoulder to hand position
    private func updateBoneRotation(segment: BoneSegment, handPosition: SIMD3<Float>) {
        let shoulderPos = segment.startPosition
        let direction = handPosition - shoulderPos
        let distance = simd_length(direction)
        
        guard distance > 0.001 else { return }
        
        // Normalize direction
        let normalizedDir = simd_normalize(direction)
        
        // Calculate rotation from default orientation (pointing up) to target direction
        let up = SIMD3<Float>(0, 1, 0)
        let rotation = simd_quatf(from: up, to: normalizedDir)
        
        // Update bone orientation
        segment.rigidBody.orientation = rotation
        
        // Position bone at midpoint between shoulder and hand
        let midpoint = shoulderPos + (direction / 2.0)
        segment.rigidBody.position = midpoint
        
        print("  Shoulder: \(shoulderPos)")
        print("  Hand: \(handPosition)")
        print("  Bone midpoint: \(midpoint)")
        print("  Direction: \(normalizedDir)")
    }
}

