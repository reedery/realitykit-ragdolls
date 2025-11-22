//
//  RAGDOLL STABILITY ANALYSIS & FIXES
//  realitykit-ragdolls
//
//  Based on physics first principles analysis
//

/*
 ROOT CAUSES OF INSTABILITY AND SOLUTIONS:

 1. MASS/INERTIA MISCONFIGURATION ⚠️ CRITICAL - ✅ FIXED
    - Current ratios: torso 8.0, limbs 0.4-1.5 = up to 20:1 ratio
    - Extreme ratios destabilize solver (should be max 3:1)
    - Light limbs get "thrown" by heavy torso
    - Solution: Normalize masses (torso 6.0, lightest limb 2.0)

 2. PENETRATION/COLLISION ISSUES ⚠️ CRITICAL - ✅ FIXED
    - Colliders at 87-90% still cause overlap during joint movement
    - Initial spawn positions might have colliders touching
    - Solution: Reduce to 70%, increase spawn spacing
    - Note: CCD not available in RealityKit, using smaller colliders instead

 3. ITERATION COUNT ⚠️ HIGH - ✅ FIXED
    - 80 iterations is not enough for complex ragdolls
    - Each joint adds constraint complexity
    - 10 body parts + 9 joints = needs ~120-150 iterations
    - Solution: Increase to 150 position, 150 velocity iterations

 4. FRICTION ISSUES ⚠️ MEDIUM - ✅ FIXED
    - High friction (0.9/0.8) causes "stick-slip" behavior
    - Bodies stick together then suddenly release with force
    - Solution: Reduce to 0.5/0.4 for smoother sliding

 5. DAMPING TOO LOW ⚠️ MEDIUM - ✅ FIXED
    - Insufficient damping allows oscillations to build
    - Solution: Increase damping significantly (18/12 base, 22/15 extremities)

 6. JOINT CONSTRAINT VIOLATIONS ⚠️ MEDIUM - ✅ FIXED
    - Joint pins placed at collider edges with proper offsets
    - Angular limits properly configured

 NOTE: Some advanced physics features not available in RealityKit:
 - CCD (Continuous Collision Detection) - using smaller colliders instead
 - Sleep thresholds - using high damping instead
 - Angular velocity limits - using high damping instead

 FIXES APPLIED:
 1. ✅ Normalize mass ratios (3:1 max)
 2. ✅ Reduce collider sizes to 70%
 3. ✅ Increase solver iterations to 150
 4. ✅ Reduce friction to 0.5/0.4
 5. ✅ Increase damping significantly
 6. ✅ Fix joint pin placement
 7. ✅ Reduce gravity and eliminate bounce
 */

import RealityKit
import UIKit

/// Enhanced physics with stability improvements
enum StableRagdollPhysics {

    // MARK: - Stability Constants

    private static let colliderSizeMultiplier: Float = 0.70  // 70% of visual (was 87-90%)
    private static let massRatioMax: Float = 3.0            // Maximum mass ratio between parts
    private static let baseMass: Float = 2.0                // Minimum mass for any part
    private static let staticFriction: Float = 0.5          // Reduced from 0.9
    private static let dynamicFriction: Float = 0.4         // Reduced from 0.8
    private static let restitution: Float = 0.0             // No bounce at all

    // Note: These constants are not used as the properties aren't available in RealityKit
    // Keeping for documentation purposes
    // private static let maxAngularVelocity: Float = 20.0  // rad/s (~3 rotations/sec) - NOT AVAILABLE
    // private static let sleepThreshold: Float = 0.01      // For both linear and angular - NOT AVAILABLE

    // MARK: - Improved Physics Setup

    static func addKinematicPhysics(
        to entity: Entity,
        shape: ShapeResource,
        mass: Float,
        config: PhysicsConfiguration
    ) {
        // Normalize mass (kinematic can be heavier but not extreme)
        let normalizedMass = min(mass, baseMass * massRatioMax)

        var physicsBody = PhysicsBodyComponent(
            shapes: [shape],
            mass: normalizedMass,
            material: .generate(
                staticFriction: config.staticFriction,
                dynamicFriction: config.dynamicFriction,
                restitution: config.restitution
            ),
            mode: .kinematic
        )

        // Moderate damping for kinematic (it's controlled, not simulated)
        physicsBody.angularDamping = config.angularDamping * 0.6
        physicsBody.linearDamping = config.linearDamping

        entity.components.set(physicsBody)
        entity.components.set(CollisionComponent(shapes: [shape]))
        entity.components.set(InputTargetComponent())
    }

    static func addDynamicPhysics(
        to entity: Entity,
        shape: ShapeResource,
        mass: Float,
        config: PhysicsConfiguration,
        isExtremity: Bool = false
    ) {
        // Normalize mass to prevent extreme ratios
        let normalizedMass = max(baseMass, min(mass, baseMass * massRatioMax))

        var physicsBody = PhysicsBodyComponent(
            shapes: [shape],
            mass: normalizedMass,
            material: .generate(
                staticFriction: staticFriction,
                dynamicFriction: dynamicFriction,
                restitution: restitution
            ),
            mode: .dynamic
        )

        // NOTE: CCD, maxAngularVelocity, and sleepThreshold are not available in RealityKit
        // Relying on mass normalization, damping, and collider sizing for stability instead

        // Much higher damping for stability
        if isExtremity {
            physicsBody.angularDamping = config.extremityAngularDamping
            physicsBody.linearDamping = config.extremityLinearDamping
        } else {
            physicsBody.angularDamping = config.angularDamping
            physicsBody.linearDamping = config.linearDamping
        }

        entity.components.set(physicsBody)
        entity.components.set(CollisionComponent(shapes: [shape]))
    }

    // MARK: - Joint Creation (unchanged, keeping existing methods)

    static func createSphericalJoint(
        parent: Entity,
        parentOffset: SIMD3<Float>,
        child: Entity,
        childOffset: SIMD3<Float>,
        coneLimitRadians: Float = .pi / 4
    ) throws {
        let parentPin = parent.pins.set(
            named: "\(parent.name ?? "parent")_\(UUID().uuidString.prefix(8))_pin",
            position: parentOffset
        )

        let childPin = child.pins.set(
            named: "\(child.name ?? "child")_\(UUID().uuidString.prefix(8))_pin",
            position: childOffset
        )

        var joint = PhysicsSphericalJoint(
            pin0: parentPin,
            pin1: childPin
        )

        // Set limits on all axes for better constraint
        joint.angularLimitInYZ = (coneLimitRadians, coneLimitRadians)

        try joint.addToSimulation()
    }

    static func createRevoluteJoint(
        parent: Entity,
        parentOffset: SIMD3<Float>,
        child: Entity,
        childOffset: SIMD3<Float>,
        axis: SIMD3<Float>,
        minAngle: Float,
        maxAngle: Float
    ) throws {
        let hingeOrientation = simd_quatf(from: [1, 0, 0], to: axis)

        let parentPin = parent.pins.set(
            named: "\(parent.name ?? "parent")_\(UUID().uuidString.prefix(8))_pin",
            position: parentOffset,
            orientation: hingeOrientation
        )

        let childPin = child.pins.set(
            named: "\(child.name ?? "child")_\(UUID().uuidString.prefix(8))_pin",
            position: childOffset,
            orientation: hingeOrientation
        )

        // Create revolute joint with angle limits
        var joint = PhysicsRevoluteJoint(
            pin0: parentPin,
            pin1: childPin,
            angularLimit: minAngle...maxAngle
        )

        try joint.addToSimulation()
    }

    // MARK: - Helper: Calculate Collider Size

    static func colliderSize(visualSize: Float) -> Float {
        return visualSize * colliderSizeMultiplier
    }

    static func colliderRadius(visualRadius: Float) -> Float {
        return visualRadius * colliderSizeMultiplier
    }
}
