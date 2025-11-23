//
//  IKSolver.swift
//  realitykit-ragdolls
//
//  Created by ryan reede on 11/23/25.
//

import Foundation
import RealityKit
import simd

/// Simple 2-joint IK solver for arm chains
struct IKSolver {
    
    /// Solves 2-bone IK (shoulder -> elbow -> wrist)
    /// - Parameters:
    ///   - shoulderPos: Shoulder position in world space
    ///   - targetPos: Desired wrist position
    ///   - upperLength: Length of upper arm (shoulder to elbow)
    ///   - lowerLength: Length of forearm (elbow to wrist)
    /// - Returns: Tuple of (elbow position, shoulder rotation, elbow rotation)
    static func solveTwoBoneIK(
        shoulderPos: SIMD3<Float>,
        targetPos: SIMD3<Float>,
        upperLength: Float,
        lowerLength: Float
    ) -> (elbowPos: SIMD3<Float>, shoulderRotation: simd_quatf, elbowRotation: simd_quatf) {
        
        // Vector from shoulder to target
        let toTarget = targetPos - shoulderPos
        let distance = simd_length(toTarget)
        let direction = simd_normalize(toTarget)
        
        // Clamp distance to reachable range
        let maxReach = upperLength + lowerLength
        let minReach = abs(upperLength - lowerLength)
        let clampedDistance = simd_clamp(distance, minReach, maxReach)
        
        // Use law of cosines to find elbow angle
        let a = upperLength
        let b = lowerLength
        let c = clampedDistance
        
        // Angle at shoulder
        let shoulderAngle = acos(
            simd_clamp((a * a + c * c - b * b) / (2 * a * c), -1.0, 1.0)
        )
        
        // Angle at elbow
        let elbowAngle = acos(
            simd_clamp((a * a + b * b - c * c) / (2 * a * b), -1.0, 1.0)
        )
        
        // Calculate elbow position
        // Place elbow in the plane defined by shoulder and target
        // Offset perpendicular to the direction (bend direction)
        let bendDirection = SIMD3<Float>(0, 0, 1)  // Bend forward by default
        let perpendicular = simd_normalize(simd_cross(direction, bendDirection))
        
        let elbowOffset = perpendicular * (upperLength * sin(shoulderAngle))
        let elbowForward = direction * (upperLength * cos(shoulderAngle))
        let elbowPos = shoulderPos + elbowForward + elbowOffset
        
        // Calculate rotations
        // Shoulder rotation: point upper arm toward elbow
        let shoulderDir = simd_normalize(elbowPos - shoulderPos)
        let shoulderRotation = simd_quatf(from: SIMD3<Float>(0, -1, 0), to: shoulderDir)
        
        // Elbow rotation: point forearm toward wrist
        let elbowDir = simd_normalize(targetPos - elbowPos)
        let elbowRotation = simd_quatf(from: SIMD3<Float>(0, -1, 0), to: elbowDir)
        
        return (elbowPos, shoulderRotation, elbowRotation)
    }
}

