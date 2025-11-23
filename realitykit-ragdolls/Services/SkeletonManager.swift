//
//  SkeletonManager.swift
//  realitykit-ragdolls
//
//  Created by ryan reede on 11/23/25.
//

import Foundation
import RealityKit

/// Manages skeleton extraction and manipulation for USDZ models
class SkeletonManager {
    
    // MARK: - Public Methods
    
    /// Extracts skeleton information from an entity hierarchy
    /// - Parameter entity: The root entity to search
    /// - Returns: SkeletonInfo if a skeleton is found, nil otherwise
    static func extractSkeletonInfo(from entity: Entity) -> SkeletonInfo? {
        // Recursively search for skeleton
        return findSkeletonInfo(in: entity)
    }
    
    /// Prints detailed skeleton information for debugging
    /// - Parameter entity: The entity to analyze
    static func printSkeletonDebugInfo(from entity: Entity) {
        print("\n=== Skeleton Information ===")
        
        guard let skeletonInfo = extractSkeletonInfo(from: entity) else {
            print("No skeleton found in entity hierarchy")
            return
        }
        
        print("Entity: \(skeletonInfo.entityName)")
        print("Total joints: \(skeletonInfo.totalJointCount)")
        print("Number of poses: \(skeletonInfo.poses.count)")
        
        for (poseIndex, pose) in skeletonInfo.poses.enumerated() {
            print("\n  Pose \(poseIndex):")
            print("    Joint count: \(pose.jointCount)")
            
            for joint in pose.joints {
                print("      [\(joint.index)] \(joint.name)")
                print("          Translation: \(joint.translation)")
                print("          Rotation: \(joint.rotation)")
                print("          Scale: \(joint.scale)")
            }
        }
    }
    
    /// Prints the entity hierarchy for debugging
    /// - Parameter entity: The root entity to print
    static func printEntityHierarchy(_ entity: Entity, indent: Int = 0) {
        let indentString = String(repeating: "  ", count: indent)
        let componentInfo = entity.components.map { String(describing: type(of: $0)) }.joined(separator: ", ")
        print("\(indentString)├─ \(entity.name.isEmpty ? "<unnamed>" : entity.name) [Components: \(componentInfo)]")
        
        for child in entity.children {
            printEntityHierarchy(child, indent: indent + 1)
        }
    }
    
    // MARK: - Private Methods
    
    /// Recursively searches for skeleton information in entity hierarchy
    /// - Parameter entity: The entity to search
    /// - Returns: SkeletonInfo if found, nil otherwise
    private static func findSkeletonInfo(in entity: Entity) -> SkeletonInfo? {
        // Check if this entity has skeletal poses
        if let skeletalPoses = entity.components[SkeletalPosesComponent.self] {
            return buildSkeletonInfo(from: entity, skeletalPoses: skeletalPoses)
        }
        
        // Recursively check children
        for child in entity.children {
            if let info = findSkeletonInfo(in: child) {
                return info
            }
        }
        
        return nil
    }
    
    /// Builds SkeletonInfo from entity components
    /// - Parameters:
    ///   - entity: The entity containing the skeleton
    ///   - skeletalPoses: The skeletal poses component
    /// - Returns: SkeletonInfo with extracted data
    private static func buildSkeletonInfo(
        from entity: Entity,
        skeletalPoses: SkeletalPosesComponent
    ) -> SkeletonInfo? {
        // Get the number of joints from the first pose
        guard let firstPose = skeletalPoses.poses.first else {
            return nil
        }
        
        let jointCount = firstPose.jointTransforms.count
        
        // Try to find joint entities in the hierarchy
        let jointEntities = findJointEntities(in: entity)
        print("Found \(jointEntities.count) joint entities in hierarchy")
        
        // Create a mapping from entity names to use as joint names
        var jointNames: [String] = []
        if jointEntities.count == jointCount {
            // Perfect match - use entity names
            jointNames = jointEntities.map { $0.name.isEmpty ? "joint_\($0)" : $0.name }
        } else {
            // Generate generic names based on index
            jointNames = (0..<jointCount).map { "joint_\(String(format: "%02d", $0))" }
            
            // If we have joint entities, print them for debugging
            if !jointEntities.isEmpty {
                print("Joint entities found (may not match skeleton structure):")
                for jointEntity in jointEntities {
                    print("  - \(jointEntity.name)")
                }
            }
        }
        
        var poses: [SkeletalPose] = []
        
        // Build poses from skeletal poses component
        for pose in skeletalPoses.poses {
            var joints: [Joint] = []
            
            for (index, transform) in pose.jointTransforms.enumerated() {
                let jointName = index < jointNames.count ? jointNames[index] : "joint_\(index)"
                
                let joint = Joint(
                    index: index,
                    name: jointName,
                    transform: transform
                )
                joints.append(joint)
            }
            
            poses.append(SkeletalPose(joints: joints))
        }
        
        return SkeletonInfo(
            entityName: entity.name,
            poses: poses,
            jointNames: jointNames
        )
    }
    
    /// Finds all entities that could be joints in the hierarchy
    /// - Parameter entity: The root entity to search
    /// - Returns: Array of entities that might be joints
    private static func findJointEntities(in entity: Entity) -> [Entity] {
        var joints: [Entity] = []
        
        // Recursively collect all child entities
        func collectEntities(_ entity: Entity) {
            // Check if this looks like a joint (has transform, named entity)
            if !entity.name.isEmpty {
                // Common joint naming patterns
                let jointKeywords = ["joint", "bone", "jnt", "ik", "ctrl"]
                let name = entity.name.lowercased()
                
                if jointKeywords.contains(where: { name.contains($0) }) {
                    joints.append(entity)
                }
            }
            
            for child in entity.children {
                collectEntities(child)
            }
        }
        
        collectEntities(entity)
        return joints
    }
}

