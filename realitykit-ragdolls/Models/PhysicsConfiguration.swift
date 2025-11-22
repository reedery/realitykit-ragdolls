//
//  PhysicsConfiguration.swift
//  realitykit-ragdolls
//
//  Created by ryan reede on 11/22/25.
//

import Foundation
import SwiftUI

/// Observable physics configuration for live editing
@Observable
class PhysicsConfiguration {
    var gravity: Float = -4.0
    var positionIterations: Int = 150
    var velocityIterations: Int = 150

    var angularDamping: Float = 18.0
    var linearDamping: Float = 12.0
    var extremityAngularDamping: Float = 22.0
    var extremityLinearDamping: Float = 15.0

    var staticFriction: Float = 0.5
    var dynamicFriction: Float = 0.4
    var restitution: Float = 0.0

    var shoulderConeLimitDegrees: Float = 45
    var hipConeLimitDegrees: Float = 30
    var neckConeLimitDegrees: Float = 22.5
    var elbowMaxBendDegrees: Float = 143
    var kneeMaxBendDegrees: Float = 143

    // Apply a character configuration
    func apply(from character: CharacterConfiguration) {
        let props = character.physicsProperties

        gravity = props.gravity
        angularDamping = props.angularDamping
        linearDamping = props.linearDamping
        extremityAngularDamping = props.extremityAngularDamping
        extremityLinearDamping = props.extremityLinearDamping
        staticFriction = props.staticFriction
        dynamicFriction = props.dynamicFriction
        restitution = props.restitution
        shoulderConeLimitDegrees = props.shoulderConeLimitDegrees
        hipConeLimitDegrees = props.hipConeLimitDegrees
        neckConeLimitDegrees = props.neckConeLimitDegrees
        elbowMaxBendDegrees = props.elbowMaxBendDegrees
        kneeMaxBendDegrees = props.kneeMaxBendDegrees
    }

    func reset() {
        apply(from: .defaultCharacter)
    }
}
