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
