//
//  USDZModel.swift
//  realitykit-ragdolls
//
//  Created by ryan reede on 11/22/25.
//

import Foundation
import RealityKit

/// Represents a USDZ 3D model with its metadata
struct USDZModel: Identifiable {
    let id = UUID()
    let fileName: String
    let scale: SIMD3<Float>
    let position: SIMD3<Float>
    let rotation: simd_quatf
    var skeletonInfo: SkeletonInfo?

    init(
        fileName: String,
        scale: SIMD3<Float> = [1, 1, 1],
        position: SIMD3<Float> = [0, 0, 0],
        rotation: simd_quatf = simd_quatf(angle: 0, axis: [0, 1, 0]),
        skeletonInfo: SkeletonInfo? = nil
    ) {
        self.fileName = fileName
        self.scale = scale
        self.position = position
        self.rotation = rotation
        self.skeletonInfo = skeletonInfo
    }
    
    /// Returns true if the model has skeletal animation data
    var hasSkeleton: Bool {
        skeletonInfo != nil
    }
    
    /// Returns the number of joints in the skeleton
    var jointCount: Int {
        skeletonInfo?.totalJointCount ?? 0
    }
}
