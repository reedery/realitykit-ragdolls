//
//  RagdollPhysics-Models.swift
//  realitykit-ragdolls
//
//  Created by ryan reede on 11/22/25.
//

import RealityKit
import UIKit

/// Handles physics setup for ragdoll entities
enum RagdollPhysics {
    
    // MARK: - Physics Component Creation
    
    /// Adds kinematic physics to an entity (for the torso)
    static func addKinematicPhysics(to entity: Entity, shape: ShapeResource, mass: Float) {
        var physicsBody = PhysicsBodyComponent(
            shapes: [shape],
            mass: mass,
            material: .generate(staticFriction: 0.8, dynamicFriction: 0.7, restitution: 0.05),
            mode: .kinematic
        )
        // Higher damping for more stability
        physicsBody.angularDamping = 7.0
        physicsBody.linearDamping = 8.0
        
        entity.components.set(physicsBody)
        entity.components.set(CollisionComponent(shapes: [shape]))
        entity.components.set(InputTargetComponent())
    }
    
    /// Adds dynamic physics to an entity (for limbs)
    static func addDynamicPhysics(to entity: Entity, shape: ShapeResource, mass: Float, isExtremity: Bool = false) {
        var physicsBody = PhysicsBodyComponent(
            shapes: [shape],
            mass: mass,
            material: .generate(staticFriction: 0.9, dynamicFriction: 0.8, restitution: 0.01),
            mode: .dynamic
        )
        
        // Much higher damping for extremities (head, hands, feet)
        if isExtremity {
            physicsBody.angularDamping = 15.0  // Very high to prevent wobbling
            physicsBody.linearDamping = 10.0
        } else {
            // High damping for regular limbs
            physicsBody.angularDamping = 12.0
            physicsBody.linearDamping = 8.0
        }
        
        entity.components.set(physicsBody)
        entity.components.set(CollisionComponent(shapes: [shape]))
    }
    
    // MARK: - Joint Creation
    
    /// Creates a spherical joint between two entities with configurable limits
    /// - Parameters:
    ///   - parent: The parent entity
    ///   - parentOffset: The offset from parent's origin
    ///   - child: The child entity
    ///   - childOffset: The offset from child's origin
    ///   - coneLimitRadians: The cone limit in radians (default is π/4 or 45 degrees)
    static func createSphericalJoint(
        parent: Entity,
        parentOffset: SIMD3<Float>,
        child: Entity,
        childOffset: SIMD3<Float>,
        coneLimitRadians: Float = .pi / 4
    ) throws {
        // Create pin on parent
        let parentPin = parent.pins.set(
            named: "\(parent.name ?? "parent")_pin",
            position: parentOffset
        )
        
        // Create pin on child
        let childPin = child.pins.set(
            named: "\(child.name ?? "child")_pin",
            position: childOffset
        )
        
        // Create spherical joint
        var joint = PhysicsSphericalJoint(
            pin0: parentPin,
            pin1: childPin
        )
        
        // Set the angular limit (cone shape around x-axis)
        joint.angularLimitInYZ = (coneLimitRadians, coneLimitRadians)
        
        // Add the joint to the simulation
        try joint.addToSimulation()
    }
    
    /// Creates a revolute joint between two entities
    static func createRevoluteJoint(
        parent: Entity,
        parentOffset: SIMD3<Float>,
        child: Entity,
        childOffset: SIMD3<Float>,
        axis: SIMD3<Float>,
        minAngle: Float? = nil,
        maxAngle: Float? = nil
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
        
        // Create revolute joint with angle limits if provided
        let joint: PhysicsRevoluteJoint
        
        if let minAngle = minAngle, let maxAngle = maxAngle {
            // Create joint with angular limits using ClosedRange
            joint = PhysicsRevoluteJoint(
                pin0: parentPin,
                pin1: childPin,
                angularLimit: minAngle...maxAngle
            )
        } else {
            // Create joint without limits
            joint = PhysicsRevoluteJoint(pin0: parentPin, pin1: childPin)
        }
        
        // Add the joint to the simulation
        try joint.addToSimulation()
    }
}
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
