//
//  RagdollBodyPart.swift
//  realitykit-ragdolls
//
//  Created by ryan reede on 11/22/25.
//

import RealityKit
import UIKit

/// Factory for creating ragdoll body part entities
struct RagdollBodyPart {

    // MARK: - Body Part Creation

    static func createTorso() -> Entity {
        let entity = Entity()
        entity.name = "torso"

        let mesh = MeshResource.generateSphere(radius: 0.2)
        var material = PhysicallyBasedMaterial()
        material.baseColor.tint = .blue
        entity.components.set(ModelComponent(mesh: mesh, materials: [material]))

        return entity
    }

    static func createHead() -> Entity {
        let entity = Entity()
        entity.name = "head"

        let mesh = MeshResource.generateSphere(radius: 0.15)
        var material = PhysicallyBasedMaterial()
        material.baseColor.tint = .orange
        entity.components.set(ModelComponent(mesh: mesh, materials: [material]))

        return entity
    }

    static func createUpperArm() -> Entity {
        let entity = Entity()
        entity.name = "upper_arm"

        // Longer arms for better stability (0.3 instead of 0.2)
        let mesh = MeshResource.generateBox(size: [0.3, 0.08, 0.08])
        var material = PhysicallyBasedMaterial()
        material.baseColor.tint = .orange
        entity.components.set(ModelComponent(mesh: mesh, materials: [material]))

        return entity
    }

    static func createLowerArm() -> Entity {
        let entity = Entity()
        entity.name = "lower_arm"

        // Longer arms for better stability (0.3 instead of 0.2)
        let mesh = MeshResource.generateBox(size: [0.3, 0.07, 0.07])
        var material = PhysicallyBasedMaterial()
        material.baseColor.tint = .orange
        entity.components.set(ModelComponent(mesh: mesh, materials: [material]))

        return entity
    }

    static func createUpperLeg() -> Entity {
        let entity = Entity()
        entity.name = "upper_leg"

        let mesh = MeshResource.generateBox(size: [0.1, 0.3, 0.1])
        var material = PhysicallyBasedMaterial()
        material.baseColor.tint = .orange
        entity.components.set(ModelComponent(mesh: mesh, materials: [material]))

        return entity
    }

    static func createLowerLeg() -> Entity {
        let entity = Entity()
        entity.name = "lower_leg"

        let mesh = MeshResource.generateBox(size: [0.09, 0.3, 0.09])
        var material = PhysicallyBasedMaterial()
        material.baseColor.tint = .orange
        entity.components.set(ModelComponent(mesh: mesh, materials: [material]))

        return entity
    }
}
//
//  RagdollBodyPartV2.swift
//  realitykit-ragdolls
//
//  Created by ryan reede on 11/22/25.
//

import RealityKit
import UIKit

/// Enhanced body part factory with customization support
extension RagdollBodyPart {

    // MARK: - Customizable Body Parts

    static func createTorso(radius: Float, color: UIColor) -> Entity {
        let entity = Entity()
        entity.name = "torso"

        let mesh = MeshResource.generateSphere(radius: radius)
        var material = PhysicallyBasedMaterial()
        material.baseColor.tint = color
        material.roughness = 0.7
        material.metallic = 0.0
        entity.components.set(ModelComponent(mesh: mesh, materials: [material]))

        return entity
    }

    static func createHead(radius: Float, color: UIColor) -> Entity {
        let entity = Entity()
        entity.name = "head"

        let mesh = MeshResource.generateSphere(radius: radius)
        var material = PhysicallyBasedMaterial()
        material.baseColor.tint = color
        material.roughness = 0.6
        material.metallic = 0.0
        entity.components.set(ModelComponent(mesh: mesh, materials: [material]))

        return entity
    }

    static func createLimb(
        length: Float,
        radius: Float,
        color: UIColor,
        name: String
    ) -> Entity {
        let entity = Entity()
        entity.name = name

        // Use box for visual representation (capsule for physics)
        let mesh = MeshResource.generateBox(size: [length, radius * 2, radius * 2])
        var material = PhysicallyBasedMaterial()
        material.baseColor.tint = color
        material.roughness = 0.7
        material.metallic = 0.0
        entity.components.set(ModelComponent(mesh: mesh, materials: [material]))

        return entity
    }
}
