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
