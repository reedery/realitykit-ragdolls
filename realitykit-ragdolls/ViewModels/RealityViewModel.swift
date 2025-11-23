//
//  RealityViewModel.swift
//  realitykit-ragdolls
//
//  Created by ryan reede on 11/22/25.
//

import Foundation
import RealityKit
import SwiftUI
import Observation

/// ViewModel managing RealityKit scene and USDZ model loading
@Observable
final class RealityViewModel {

    // MARK: - Properties

    var model: USDZModel
    var loadingError: String?
    var isLoading = false

    // MARK: - Initialization

    init(model: USDZModel = USDZModel(fileName: "biped_robot.usdz")) {
        self.model = model
    }

    // MARK: - Public Methods

    /// Loads a USDZ model entity from the app bundle
    /// - Returns: ModelEntity if successful, nil otherwise
    func loadModelEntity() async -> ModelEntity? {
        isLoading = true
        loadingError = nil

        defer { isLoading = false }

        do {
            // Load the USDZ file from the app bundle
            let entity = try await ModelEntity(named: model.fileName)

            // Apply transformations
            entity.scale = model.scale
            entity.position = model.position
            entity.orientation = model.rotation

            // Enable gestures for interaction (optional)
            entity.generateCollisionShapes(recursive: true)
            entity.components.set(InputTargetComponent())

            return entity
        } catch {
            loadingError = "Failed to load model: \(error.localizedDescription)"
            print("Error loading USDZ model: \(error)")
            return nil
        }
    }

    /// Updates the model with new parameters
    func updateModel(_ newModel: USDZModel) {
        self.model = newModel
    }
}
