//
//  CharacterConfiguration.swift
//  realitykit-ragdolls
//
//  Created by ryan reede on 11/22/25.
//

import Foundation
import RealityKit
import UIKit

/// Configuration for a ragdoll character loaded from JSON
struct CharacterConfiguration: Codable, Identifiable {
    let id: String
    let name: String
    let displayName: String
    let bodyProportions: BodyProportions
    let physicsProperties: PhysicsProperties
    let visualProperties: VisualProperties

    /// Body part proportions and sizes
    struct BodyProportions: Codable {
        let torsoRadius: Float
        let headRadius: Float
        let upperArmLength: Float
        let upperArmRadius: Float
        let lowerArmLength: Float
        let lowerArmRadius: Float
        let upperLegLength: Float
        let upperLegRadius: Float
        let lowerLegLength: Float
        let lowerLegRadius: Float

        // Spacing factors (multiplier for gaps between parts)
        let jointSpacing: Float
    }

    /// Physics properties for the character
    struct PhysicsProperties: Codable {
        let torsoMass: Float
        let headMass: Float
        let upperArmMass: Float
        let lowerArmMass: Float
        let upperLegMass: Float
        let lowerLegMass: Float

        let angularDamping: Float
        let linearDamping: Float
        let extremityAngularDamping: Float
        let extremityLinearDamping: Float

        let gravity: Float
        let staticFriction: Float
        let dynamicFriction: Float
        let restitution: Float

        let shoulderConeLimitDegrees: Float
        let hipConeLimitDegrees: Float
        let neckConeLimitDegrees: Float
        let elbowMaxBendDegrees: Float
        let kneeMaxBendDegrees: Float
    }

    /// Visual properties for the character
    struct VisualProperties: Codable {
        let torsoColor: ColorData
        let headColor: ColorData
        let limbColor: ColorData
    }

    /// RGB color data for JSON serialization
    struct ColorData: Codable {
        let red: Float
        let green: Float
        let blue: Float
        let alpha: Float

        func toUIColor() -> UIColor {
            return UIColor(red: CGFloat(red), green: CGFloat(green), blue: CGFloat(blue), alpha: CGFloat(alpha))
        }
    }
}

// MARK: - Character Presets

extension CharacterConfiguration {

    /// Load all character configurations from JSON files
    static func loadPresets() -> [CharacterConfiguration] {
        return [
            .defaultCharacter,
            .tallCharacter,
            .shortCharacter,
            .muscularCharacter
        ]
    }

    /// Default balanced character
    static let defaultCharacter = CharacterConfiguration(
        id: "default",
        name: "default",
        displayName: "Default",
        bodyProportions: BodyProportions(
            torsoRadius: 0.2,
            headRadius: 0.15,
            upperArmLength: 0.3,
            upperArmRadius: 0.03,
            lowerArmLength: 0.3,
            lowerArmRadius: 0.028,
            upperLegLength: 0.3,
            upperLegRadius: 0.04,
            lowerLegLength: 0.3,
            lowerLegRadius: 0.036,
            jointSpacing: 1.0
        ),
        physicsProperties: PhysicsProperties(
            torsoMass: 8.0,
            headMass: 1.2,
            upperArmMass: 1.2,
            lowerArmMass: 0.8,
            upperLegMass: 1.5,
            lowerLegMass: 1.0,
            angularDamping: 12.0,
            linearDamping: 8.0,
            extremityAngularDamping: 15.0,
            extremityLinearDamping: 10.0,
            gravity: -6.0,
            staticFriction: 0.9,
            dynamicFriction: 0.8,
            restitution: 0.01,
            shoulderConeLimitDegrees: 45,
            hipConeLimitDegrees: 30,
            neckConeLimitDegrees: 22.5,
            elbowMaxBendDegrees: 143,
            kneeMaxBendDegrees: 143
        ),
        visualProperties: VisualProperties(
            torsoColor: ColorData(red: 0.0, green: 0.5, blue: 1.0, alpha: 1.0),
            headColor: ColorData(red: 1.0, green: 0.6, blue: 0.4, alpha: 1.0),
            limbColor: ColorData(red: 1.0, green: 0.6, blue: 0.4, alpha: 1.0)
        )
    )

    /// Tall and thin character
    static let tallCharacter = CharacterConfiguration(
        id: "tall",
        name: "tall",
        displayName: "Tall & Slim",
        bodyProportions: BodyProportions(
            torsoRadius: 0.18,
            headRadius: 0.13,
            upperArmLength: 0.35,
            upperArmRadius: 0.025,
            lowerArmLength: 0.35,
            lowerArmRadius: 0.023,
            upperLegLength: 0.4,
            upperLegRadius: 0.035,
            lowerLegLength: 0.4,
            lowerLegRadius: 0.032,
            jointSpacing: 1.1
        ),
        physicsProperties: PhysicsProperties(
            torsoMass: 7.0,
            headMass: 1.0,
            upperArmMass: 1.0,
            lowerArmMass: 0.7,
            upperLegMass: 1.3,
            lowerLegMass: 0.9,
            angularDamping: 14.0,
            linearDamping: 9.0,
            extremityAngularDamping: 17.0,
            extremityLinearDamping: 11.0,
            gravity: -6.0,
            staticFriction: 0.9,
            dynamicFriction: 0.8,
            restitution: 0.01,
            shoulderConeLimitDegrees: 50,
            hipConeLimitDegrees: 35,
            neckConeLimitDegrees: 25,
            elbowMaxBendDegrees: 145,
            kneeMaxBendDegrees: 145
        ),
        visualProperties: VisualProperties(
            torsoColor: ColorData(red: 0.5, green: 0.0, blue: 1.0, alpha: 1.0),
            headColor: ColorData(red: 1.0, green: 0.8, blue: 0.6, alpha: 1.0),
            limbColor: ColorData(red: 1.0, green: 0.8, blue: 0.6, alpha: 1.0)
        )
    )

    /// Short and stocky character
    static let shortCharacter = CharacterConfiguration(
        id: "short",
        name: "short",
        displayName: "Short & Stocky",
        bodyProportions: BodyProportions(
            torsoRadius: 0.22,
            headRadius: 0.16,
            upperArmLength: 0.25,
            upperArmRadius: 0.035,
            lowerArmLength: 0.25,
            lowerArmRadius: 0.032,
            upperLegLength: 0.25,
            upperLegRadius: 0.045,
            lowerLegLength: 0.25,
            lowerLegRadius: 0.042,
            jointSpacing: 0.9
        ),
        physicsProperties: PhysicsProperties(
            torsoMass: 9.0,
            headMass: 1.4,
            upperArmMass: 1.4,
            lowerArmMass: 0.9,
            upperLegMass: 1.7,
            lowerLegMass: 1.2,
            angularDamping: 10.0,
            linearDamping: 7.0,
            extremityAngularDamping: 13.0,
            extremityLinearDamping: 9.0,
            gravity: -6.0,
            staticFriction: 0.9,
            dynamicFriction: 0.8,
            restitution: 0.01,
            shoulderConeLimitDegrees: 40,
            hipConeLimitDegrees: 25,
            neckConeLimitDegrees: 20,
            elbowMaxBendDegrees: 140,
            kneeMaxBendDegrees: 140
        ),
        visualProperties: VisualProperties(
            torsoColor: ColorData(red: 1.0, green: 0.5, blue: 0.0, alpha: 1.0),
            headColor: ColorData(red: 1.0, green: 0.9, blue: 0.7, alpha: 1.0),
            limbColor: ColorData(red: 1.0, green: 0.9, blue: 0.7, alpha: 1.0)
        )
    )

    /// Muscular character
    static let muscularCharacter = CharacterConfiguration(
        id: "muscular",
        name: "muscular",
        displayName: "Muscular",
        bodyProportions: BodyProportions(
            torsoRadius: 0.24,
            headRadius: 0.14,
            upperArmLength: 0.3,
            upperArmRadius: 0.04,
            lowerArmLength: 0.3,
            lowerArmRadius: 0.037,
            upperLegLength: 0.3,
            upperLegRadius: 0.05,
            lowerLegLength: 0.3,
            lowerLegRadius: 0.046,
            jointSpacing: 1.0
        ),
        physicsProperties: PhysicsProperties(
            torsoMass: 10.0,
            headMass: 1.3,
            upperArmMass: 1.5,
            lowerArmMass: 1.0,
            upperLegMass: 2.0,
            lowerLegMass: 1.4,
            angularDamping: 11.0,
            linearDamping: 7.5,
            extremityAngularDamping: 14.0,
            extremityLinearDamping: 9.5,
            gravity: -6.0,
            staticFriction: 0.9,
            dynamicFriction: 0.8,
            restitution: 0.01,
            shoulderConeLimitDegrees: 42,
            hipConeLimitDegrees: 28,
            neckConeLimitDegrees: 20,
            elbowMaxBendDegrees: 141,
            kneeMaxBendDegrees: 141
        ),
        visualProperties: VisualProperties(
            torsoColor: ColorData(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0),
            headColor: ColorData(red: 0.9, green: 0.7, blue: 0.5, alpha: 1.0),
            limbColor: ColorData(red: 0.9, green: 0.7, blue: 0.5, alpha: 1.0)
        )
    )
}
