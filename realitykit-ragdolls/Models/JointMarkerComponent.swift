//
//  JointMarkerComponent.swift
//  realitykit-ragdolls
//
//  Created by ryan reede on 11/23/25.
//

import Foundation
import RealityKit

/// Custom component to store joint information on marker entities
struct JointMarkerComponent: Component {
    var jointIndex: Int
    var jointName: String
    var isDraggable: Bool
}

