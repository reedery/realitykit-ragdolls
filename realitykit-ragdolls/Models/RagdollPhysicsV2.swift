//
//  RagdollPhysicsV2.swift
//  realitykit-ragdolls
//
//  Created by ryan reede on 11/22/25.
//

import RealityKit

/// Enhanced physics setup with configuration support
extension RagdollPhysics {

    // MARK: - Physics with Configuration

    /// Adds kinematic physics with custom configuration
    static func addKinematicPhysics(
        to entity: Entity,
        shape: ShapeResource,
        mass: Float,
        config: PhysicsConfiguration
    ) {
        var physicsBody = PhysicsBodyComponent(
            shapes: [shape],
            mass: mass,
            material: .generate(
                staticFriction: config.staticFriction,
                dynamicFriction: config.dynamicFriction,
                restitution: config.restitution
            ),
            mode: .kinematic
        )
        physicsBody.angularDamping = config.angularDamping * 0.6  // Slightly less for kinematic
        physicsBody.linearDamping = config.linearDamping * 1.0

        entity.components.set(physicsBody)
        entity.components.set(CollisionComponent(shapes: [shape]))
        entity.components.set(InputTargetComponent())
    }

    /// Adds dynamic physics with custom configuration
    static func addDynamicPhysics(
        to entity: Entity,
        shape: ShapeResource,
        mass: Float,
        config: PhysicsConfiguration,
        isExtremity: Bool = false
    ) {
        var physicsBody = PhysicsBodyComponent(
            shapes: [shape],
            mass: mass,
            material: .generate(
                staticFriction: config.staticFriction,
                dynamicFriction: config.dynamicFriction,
                restitution: config.restitution
            ),
            mode: .dynamic
        )

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
}
