//
//  RagdollPhysics.swift
//  realitykit-ragdolls
//
//  Created by ryan reede on 11/22/25.
//

import RealityKit

/// Handles physics setup for ragdoll entities
struct RagdollPhysics {

    // MARK: - Physics Component Creation

    /// Adds kinematic physics to an entity (for the torso)
    static func addKinematicPhysics(to entity: Entity, shape: ShapeResource, mass: Float) {
        var physicsBody = PhysicsBodyComponent(
            shapes: [shape],
            mass: mass,
            material: .generate(staticFriction: 0.3, dynamicFriction: 0.2, restitution: 0.1),
            mode: .kinematic
        )
        physicsBody.angularDamping = 2.0
        physicsBody.linearDamping = 2.0

        entity.components.set(physicsBody)
        entity.components.set(CollisionComponent(shapes: [shape]))
        entity.components.set(InputTargetComponent())
    }

    /// Adds dynamic physics to an entity (for limbs)
    static func addDynamicPhysics(to entity: Entity, shape: ShapeResource, mass: Float) {
        var physicsBody = PhysicsBodyComponent(
            shapes: [shape],
            mass: mass,
            material: .generate(staticFriction: 0.3, dynamicFriction: 0.2, restitution: 0.1),
            mode: .dynamic
        )
        physicsBody.angularDamping = 1.0
        physicsBody.linearDamping = 0.5

        entity.components.set(physicsBody)
        entity.components.set(CollisionComponent(shapes: [shape]))
    }

    // MARK: - Joint Creation

    /// Creates a revolute joint between two entities
    static func createRevoluteJoint(
        parent: Entity,
        parentOffset: SIMD3<Float>,
        child: Entity,
        childOffset: SIMD3<Float>,
        axis: SIMD3<Float>
    ) throws {
        // Create orientation for the joint axis
        let hingeOrientation = simd_quatf(from: [1, 0, 0], to: axis)

        // Create pin on parent
        let parentPin = parent.pins.set(
            named: "\(parent.name ?? "parent")_pin",
            position: parentOffset,
            orientation: hingeOrientation
        )

        // Create pin on child
        let childPin = child.pins.set(
            named: "\(child.name ?? "child")_pin",
            position: childOffset,
            orientation: hingeOrientation
        )

        // Create revolute joint
        let joint = PhysicsRevoluteJoint(pin0: parentPin, pin1: childPin)

        // Add the joint to the simulation
        try joint.addToSimulation()
    }
}
