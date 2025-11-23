//
//  GestureManager.swift
//  realitykit-ragdolls
//
//  Created by ryan reede on 11/23/25.
//

import Foundation
import RealityKit
import SwiftUI

/// Manages gesture interactions for articulated joints
class GestureManager {
    
    // MARK: - Properties
    
    private var articulationManager: ArticulationManager
    private var dragStartPositions: [String: SIMD3<Float>] = [:]
    private var currentDragJointIndex: Int?
    
    // MARK: - Initialization
    
    init(articulationManager: ArticulationManager) {
        self.articulationManager = articulationManager
    }
    
    // MARK: - Public Methods
    
    /// Sets up gesture recognizers for an entity
    /// - Parameter entity: The root entity containing draggable joints
    func setupGestures(for entity: Entity) {
        print("Setting up gesture recognizers for entity: \(entity.name)")
        
        // The gestures will be handled in the RealityView
        // This method prepares the necessary state
    }
    
    /// Handles the start of a drag gesture
    /// - Parameters:
    ///   - entity: The entity being dragged
    ///   - location: The 3D location where the drag started
    func handleDragBegan(entity: Entity, at location: SIMD3<Float>) {
        dragStartPositions[entity.name] = entity.position
        
        // Store the joint index for this drag
        if let jointIndex = extractJointIndex(from: entity) {
            currentDragJointIndex = jointIndex
            print("Drag began on: \(entity.name) (joint \(jointIndex)) at \(location)")
        } else {
            print("Drag began on: \(entity.name) at \(location)")
        }
    }
    
    /// Handles drag movement
    /// - Parameters:
    ///   - entity: The entity being dragged
    ///   - translation: The translation vector from the drag
    func handleDragChanged(entity: Entity, translation: SIMD3<Float>) {
        guard let startPosition = dragStartPositions[entity.name] else { return }
        
        // Update entity position
        entity.position = startPosition + translation
        
        // Update the skeleton joint through articulation manager
        if let jointIndex = currentDragJointIndex {
            articulationManager.handleJointDrag(jointIndex: jointIndex, translation: translation)
            print("Dragging joint \(jointIndex) with translation: \(translation)")
        }
    }
    
    /// Handles the end of a drag gesture
    /// - Parameter entity: The entity being dragged
    func handleDragEnded(entity: Entity) {
        dragStartPositions.removeValue(forKey: entity.name)
        currentDragJointIndex = nil
        print("Drag ended on: \(entity.name)")
    }
    
    // MARK: - Private Methods
    
    /// Extracts the joint index from a marker entity
    /// - Parameter entity: The marker entity
    /// - Returns: Joint index if found
    private func extractJointIndex(from entity: Entity) -> Int? {
        // Get the joint index from our custom component
        guard let markerComponent = entity.components[JointMarkerComponent.self] else {
            return nil
        }
        return markerComponent.jointIndex
    }
}

