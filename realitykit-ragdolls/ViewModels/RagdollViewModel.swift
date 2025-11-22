//
//  RagdollViewModel.swift
//  realitykit-ragdolls
//
//  Created by ryan reede on 11/22/25.
//

import SwiftUI
import RealityKit

/// ViewModel for managing ragdoll state and interactions
@MainActor
class RagdollViewModel: ObservableObject {
    @Published var torsoEntity: Entity?
    @Published var isDragging = false

    private var initialTorsoPosition: SIMD3<Float>?

    // MARK: - Drag Handling

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

    func onDragEnded() {
        isDragging = false
        initialTorsoPosition = nil
    }

    // MARK: - Scene Setup

    func setupRagdoll(in content: RealityViewContent) {
        do {
            let ragdollScene = try RagdollBuilder.buildRagdollScene()
            content.add(ragdollScene)

            // Find and store the torso entity reference
            if let torso = ragdollScene.findEntity(named: "torso") {
                torsoEntity = torso
            }
        } catch {
            print("Error building ragdoll scene: \(error)")
        }
    }
}
