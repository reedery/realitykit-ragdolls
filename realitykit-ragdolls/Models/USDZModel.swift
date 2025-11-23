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

    init(
        fileName: String,
        scale: SIMD3<Float> = [1, 1, 1],
        position: SIMD3<Float> = [0, 0, 0],
        rotation: simd_quatf = simd_quatf(angle: 0, axis: [0, 1, 0])
    ) {
        self.fileName = fileName
        self.scale = scale
        self.position = position
        self.rotation = rotation
    }
}
