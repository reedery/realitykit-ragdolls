//
//  Joint.swift
//  realitykit-ragdolls
//
//  Created by ryan reede on 11/23/25.
//

import Foundation
import RealityKit

/// Represents a skeletal joint with its transform data
struct Joint: Identifiable {
    let id = UUID()
    let index: Int
    let name: String
    let translation: SIMD3<Float>
    let rotation: simd_quatf
    let scale: SIMD3<Float>
    
    init(index: Int, name: String, transform: Transform) {
        self.index = index
        self.name = name
        self.translation = transform.translation
        self.rotation = transform.rotation
        self.scale = transform.scale
    }
}

/// Represents a skeletal pose containing all joint transforms
struct SkeletalPose {
    let joints: [Joint]
    
    var jointCount: Int {
        joints.count
    }
    
    /// Find a joint by name
    func joint(named name: String) -> Joint? {
        joints.first { $0.name == name }
    }
    
    /// Find a joint by index
    func joint(at index: Int) -> Joint? {
        joints.first { $0.index == index }
    }
}

/// Information about a model's skeleton
struct SkeletonInfo {
    let entityName: String
    let poses: [SkeletalPose]
    let jointNames: [String]
    
    var hasMultiplePoses: Bool {
        poses.count > 1
    }
    
    var primaryPose: SkeletalPose? {
        poses.first
    }
    
    var totalJointCount: Int {
        jointNames.count
    }
}

