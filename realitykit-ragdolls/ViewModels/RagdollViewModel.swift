//
//  RagdollViewModel.swift
//  realitykit-ragdolls
//
//  Created by ryan reede on 11/22/25.
//

import SwiftUI
import RealityKit
import Combine

/// ViewModel for managing ragdoll state and interactions
class RagdollViewModel: ObservableObject {
    @Published var torsoEntity: Entity?
    @Published var isDragging = false
    @Published var ragdollScene: Entity?

    private var initialTorsoPosition: SIMD3<Float>?

    // MARK: - Drag Handling

    @MainActor
    func onDragChanged(value: DragGesture.Value, in entity: Entity?) {
        guard let torso = torsoEntity, entity?.name == "torso" else { return }

        isDragging = true

        if initialTorsoPosition == nil {
            initialTorsoPosition = torso.position
        }

        // Convert drag translation to 3D movement
        // Scale factor to make dragging feel natural
        let scale: Float = 0.001
        let translation = SIMD3<Float>(
            Float(value.translation.width) * scale,
            -Float(value.translation.height) * scale,
            0
        )

        if let initialPos = initialTorsoPosition {
            torso.position = initialPos + translation
        }
    }

    @MainActor
    func onDragEnded() {
        isDragging = false
        initialTorsoPosition = nil
    }

    // MARK: - Scene Setup

    @MainActor
    func setupRagdoll() throws -> Entity {
        let scene = try RagdollBuilder.buildRagdollScene()
        ragdollScene = scene

        // Find and store the torso entity reference
        if let torso = scene.findEntity(named: "torso") {
            torsoEntity = torso
        }

        return scene
    }
}
