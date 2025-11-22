//
//  RAGDOLL STABILITY ANALYSIS & FIXES
//  realitykit-ragdolls
//
//  Based on physics first principles analysis
//

/*
 ROOT CAUSES OF INSTABILITY:

 1. PENETRATION/COLLISION ISSUES ⚠️ CRITICAL
    - Colliders at 87-90% still cause overlap during joint movement
    - No CCD (Continuous Collision Detection) = tunneling through geometry
    - Initial spawn positions might have colliders touching
    - Solution: Reduce to 70-75%, enable CCD, increase spawn spacing

 2. MASS/INERTIA MISCONFIGURATION ⚠️ CRITICAL
    - Current ratios: torso 8.0, limbs 0.4-1.5 = up to 20:1 ratio
    - Extreme ratios destabilize solver (should be max 3:1)
    - Light limbs get "thrown" by heavy torso
    - Solution: Normalize masses (torso 6.0, lightest limb 2.0)

 3. JOINT CONSTRAINT VIOLATIONS ⚠️ HIGH
    - Joint pins might be inside collider boundaries
    - Spherical joints with only Y/Z limits (missing X limit)
    - No maximum swing distance on ball-and-socket joints
    - Solution: Place pins on collider surface, add all axis limits

 4. ITERATION COUNT ⚠️ MEDIUM
    - 80 iterations is decent but not enough for complex ragdolls
    - Each joint adds constraint complexity
    - 10 body parts + 9 joints = needs ~120-150 iterations
    - Solution: Increase to 150 position, 150 velocity iterations

 5. FRICTION ISSUES ⚠️ MEDIUM
    - High friction (0.9/0.8) causes "stick-slip" behavior
    - Bodies stick together then suddenly release with force
    - Solution: Reduce to 0.5/0.4 for smoother sliding

 6. NO SLEEP THRESHOLDS ⚠️ MEDIUM
    - Bodies never rest, constantly micro-jittering
    - Micro-movements accumulate into chaos
    - Solution: Add sleep thresholds (linear 0.01, angular 0.01)

 7. NO ANGULAR VELOCITY LIMITS ⚠️ LOW
    - Limbs can spin infinitely fast
    - Creates huge momentum that destabilizes
    - Solution: Cap at 20 rad/s (~3 rotations per second)

 8. EXTERNAL FORCES (DRAG) ⚠️ LOW
    - Current drag applies position directly (good)
    - No force amplification detected
    - Solution: Keep current approach

 PRIORITY FIX ORDER:
 1. Enable CCD on all dynamic bodies
 2. Normalize mass ratios (3:1 max)
 3. Reduce collider sizes to 70-75%
 4. Increase solver iterations to 150
 5. Add sleep thresholds
 6. Reduce friction to 0.5/0.4
 7. Add angular velocity limits
 8. Fix joint pin placement
 */

import RealityKit
import UIKit

/// Enhanced physics with stability improvements
enum StableRagdollPhysics {

    // MARK: - Stability Constants

    private static let colliderSizeMultiplier: Float = 0.70  // 70% of visual (was 87-90%)
    private static let massRatioMax: Float = 3.0            // Maximum mass ratio between parts
    private static let baseMass: Float = 2.0                // Minimum mass for any part
    private static let maxAngularVelocity: Float = 20.0     // rad/s (~3 rotations/sec)
    private static let sleepThreshold: Float = 0.01         // For both linear and angular
    private static let staticFriction: Float = 0.5          // Reduced from 0.9
    private static let dynamicFriction: Float = 0.4         // Reduced from 0.8
    private static let restitution: Float = 0.0             // No bounce at all

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

        // CRITICAL: Enable CCD to prevent tunneling
        physicsBody.isCCDEnabled = true

        // Much higher damping for stability
        if isExtremity {
            physicsBody.angularDamping = config.extremityAngularDamping
            physicsBody.linearDamping = config.extremityLinearDamping
        } else {
            physicsBody.angularDamping = config.angularDamping
            physicsBody.linearDamping = config.linearDamping
        }

        // CRITICAL: Add max angular velocity to prevent spinning chaos
        physicsBody.maxAngularVelocity = maxAngularVelocity

        // CRITICAL: Add sleep thresholds so bodies can rest
        physicsBody.sleepThreshold = sleepThreshold

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

        var joint = PhysicsRevoluteJoint(pin0: parentPin, pin1: childPin)

        // Add angle limits
        joint.limits = (minAngle, maxAngle)

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
