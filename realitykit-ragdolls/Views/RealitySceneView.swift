//
//  RealitySceneView.swift
//  realitykit-ragdolls
//
//  Created by ryan reede on 11/23/25.
//

import SwiftUI
import RealityKit

struct RealitySceneView: View {
    
    // MARK: - Properties
    
    let viewModel: RealityViewModel
    @State private var draggedEntity: Entity?
    @State private var dragStartPosition: SIMD3<Float>?
    @State private var cameraTransform: Transform?
    
    // MARK: - Body
    
    var body: some View {
        RealityView { content in
            // Build the complete scene from the ViewModel
            guard let sceneAnchor = await viewModel.buildScene() else {
                return
            }
            
            // Add the scene to the content
            content.add(sceneAnchor)
            
        } update: { content in
            // Get camera transform for proper drag calculations
            // Note: In RealityKit, we don't have direct camera access in iOS
            // We'll use the gesture translation with improved scaling
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .targetedToAnyEntity()
                .onChanged { value in
                    handleDragChanged(entity: value.entity, translation: value.translation3D)
                }
                .onEnded { value in
                    handleDragEnded(entity: value.entity)
                }
        )
        .background(
            // Blue sky gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.2, green: 0.7, blue: 1.0),  // Sky blue
                    Color(red: 0.6, green: 0.95, blue: 1.0)  // Lighter blue at horizon
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(.all)
        )
        .realityViewCameraControls(CameraControls.orbit)
    }
    
    // MARK: - Private Methods
    
    /// Handles drag gesture changes
    /// - Parameters:
    ///   - entity: The entity being dragged
    ///   - translation: The 3D translation from the gesture
    private func handleDragChanged(entity: Entity, translation: SIMD3<Float>) {
        if draggedEntity == nil {
            draggedEntity = entity
            dragStartPosition = entity.position
        }
        
        // Update marker position
        let newPosition = dragStartPosition! + translation
        entity.position = newPosition
        
        // Handle based on control type
        switch entity.name {
        case "control_root":
            // Move whole character
            viewModel.skeletonController?.moveCharacter(to: newPosition)
            
        case "control_right_wrist":
            // IK for right arm
            viewModel.skeletonController?.moveArmIK(wristJoint: 38, to: newPosition)
            
        case "control_left_wrist":
            // IK for left arm
            viewModel.skeletonController?.moveArmIK(wristJoint: 66, to: newPosition)
            
        default:
            break
        }
    }
    
    /// Handles drag gesture end
    /// - Parameter entity: The entity that was dragged
    private func handleDragEnded(entity: Entity) {
        guard draggedEntity != nil else { return }
        
        viewModel.gestureManager?.handleDragEnded(entity: entity)
        draggedEntity = nil
        dragStartPosition = nil
    }
}

// MARK: - Extensions

extension DragGesture.Value {
    /// Converts the 2D screen translation to 3D world space translation
    /// Takes into account camera view direction for natural dragging
    var translation3D: SIMD3<Float> {
        // Scale factor for screen-to-world conversion
        let scale: Float = 0.002
        
        // Screen X/Y movement maps to world X/Y relative to camera view
        // We move in the camera's local XY plane
        let screenX = Float(translation.width) * scale
        let screenY = -Float(translation.height) * scale
        
        // For now, assume camera looking down Z axis (can be improved with actual camera matrix)
        // Right = camera's right vector (X in default view)
        // Up = camera's up vector (Y in default view)
        let worldTranslation = SIMD3<Float>(
            screenX,  // Move horizontally (camera right)
            screenY,  // Move vertically (camera up)
            0         // No depth change during drag
        )
        
        return worldTranslation
    }
}

// MARK: - Preview

#Preview {
    RealitySceneView(viewModel: RealityViewModel())
}
