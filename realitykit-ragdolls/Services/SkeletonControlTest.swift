//
//  SkeletonControlTest.swift
//  realitykit-ragdolls
//
//  Created by ryan reede on 11/23/25.
//

import Foundation
import RealityKit

/// Tests whether we can control a USDZ skeleton at all
class SkeletonControlTest {
    
    /// Attempts various methods to control skeleton joints
    /// - Parameter entity: The entity with skeleton
    /// - Returns: True if any method works
    static func testSkeletonControl(on entity: Entity) -> Bool {
        print("\n=== TESTING SKELETON CONTROL ===")
        
        guard let skeletalEntity = findSkeletalEntity(in: entity) else {
            print("❌ No skeletal entity found")
            return false
        }
        
        print("✓ Found skeletal entity: \(skeletalEntity.name)")
        
        // Test 1: Can we read SkeletalPosesComponent?
        guard var skeletalPoses = skeletalEntity.components[SkeletalPosesComponent.self] else {
            print("❌ Cannot access SkeletalPosesComponent")
            return false
        }
        
        print("✓ Can read SkeletalPosesComponent")
        print("  Poses count: \(skeletalPoses.poses.count)")
        
        guard !skeletalPoses.poses.isEmpty else {
            print("❌ No poses in component")
            return false
        }
        
        var pose = skeletalPoses.poses[0]
        print("✓ Can read pose with \(pose.jointTransforms.count) joints")
        
        // Test 2: Can we modify a joint transform?
        guard pose.jointTransforms.count > 0 else {
            print("❌ No joint transforms")
            return false
        }
        
        let originalTransform = pose.jointTransforms[0]
        print("\n📊 Original joint 0 transform:")
        print("  Translation: \(originalTransform.translation)")
        print("  Rotation: \(originalTransform.rotation)")
        
        // Try to modify it
        var modifiedTransform = originalTransform
        modifiedTransform.rotation = simd_quatf(angle: .pi / 4, axis: [0, 0, 1])  // 45° rotation
        
        pose.jointTransforms[0] = modifiedTransform
        skeletalPoses.poses[0] = pose
        
        print("\n🔧 Attempting to set modified transform...")
        
        // Test 3: Can we write back to component?
        skeletalEntity.components.set(skeletalPoses)
        
        // Test 4: Did it actually change?
        if let updatedPoses = skeletalEntity.components[SkeletalPosesComponent.self],
           !updatedPoses.poses.isEmpty {
            let updatedTransform = updatedPoses.poses[0].jointTransforms[0]
            
            print("\n📊 After modification:")
            print("  Translation: \(updatedTransform.translation)")
            print("  Rotation: \(updatedTransform.rotation)")
            
            // Check if rotation actually changed
            let rotationChanged = !simd_equal(updatedTransform.rotation.vector, originalTransform.rotation.vector)
            
            if rotationChanged {
                print("\n✅ SUCCESS! Skeleton IS controllable!")
                print("   The joint rotation was modified!")
                return true
            } else {
                print("\n❌ FAILED: Rotation reverted back")
                print("   SkeletalPosesComponent appears to be read-only or animation-controlled")
                return false
            }
        }
        
        print("❌ Could not read back component")
        return false
    }
    
    private static func findSkeletalEntity(in entity: Entity) -> Entity? {
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
}

