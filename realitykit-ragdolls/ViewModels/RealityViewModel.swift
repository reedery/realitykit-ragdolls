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
class RealityViewModel {

    // MARK: - Properties

    var model: USDZModel
    var loadingError: String?
    var isLoading = false

    // MARK: - Initialization

    init(model: USDZModel = USDZModel(fileName: "robot.usdz")) {
        self.model = model
    }

    // MARK: - Public Methods

    /// Builds and returns the complete RealityKit scene
    /// - Returns: AnchorEntity containing the entire scene setup
    func buildScene() async -> AnchorEntity? {
        isLoading = true
        loadingError = nil

        defer { isLoading = false }

        // Create the root anchor
        let anchor = AnchorEntity(world: .zero)

        // Load and add the model
        guard let modelEntity = await loadModelEntity() else {
            return nil
        }

        // Add scene elements
        anchor.addChild(createGroundPlane())
        anchor.addChild(modelEntity)
        setupLighting(in: anchor)
        setCamera(in: anchor, position: [0, 2, 5])

        return anchor
    }

    // MARK: - Private Methods

    /// Loads a USDZ model entity from the app bundle
    /// - Returns: ModelEntity if successful, nil otherwise
    private func loadModelEntity() async -> ModelEntity? {
        do {
            // Load the USDZ file from the app bundle
            let entity = try await ModelEntity(named: model.fileName)

            // Apply transformations
            entity.scale = model.scale
            entity.position = model.position
            entity.orientation = model.rotation

            // Enable gestures for interaction
            entity.generateCollisionShapes(recursive: true)
            entity.components.set(InputTargetComponent())

            // Extract and store skeleton information
            if let skeletonInfo = SkeletonManager.extractSkeletonInfo(from: entity) {
                model.skeletonInfo = skeletonInfo
                
                // Print debug information
                print("\n=== Entity Hierarchy ===")
                SkeletonManager.printEntityHierarchy(entity)
                SkeletonManager.printSkeletonDebugInfo(from: entity)
            }

            return entity
        } catch {
            loadingError = "Failed to load model: \(error.localizedDescription)"
            print("Error loading USDZ model: \(error)")
            return nil
        }
    }

    /// Creates a ground plane for the scene
    /// - Returns: ModelEntity representing the ground
    private func createGroundPlane() -> ModelEntity {
        let planeMesh = MeshResource.generatePlane(width: 20, depth: 20)

        var material = PhysicallyBasedMaterial()
        material.baseColor = .init(tint: .white.withAlphaComponent(0.95))
        material.roughness = .init(floatLiteral: 0.9)
        material.metallic = .init(floatLiteral: 0.1)

        // Add subtle grid-like appearance
        material.clearcoat = .init(floatLiteral: 0.3)

        let planeEntity = ModelEntity(mesh: planeMesh, materials: [material])
        planeEntity.position = [0, -1, 0]

        // Add collision for physics interactions
        planeEntity.generateCollisionShapes(recursive: false)

        // Add physics body for the ground
        planeEntity.components.set(PhysicsBodyComponent(
            massProperties: .default,
            material: .default,
            mode: .static
        ))
        return planeEntity
    }

    /// Sets up lighting for the scene
    /// - Parameter anchor: The anchor entity to add lights to
    private func setupLighting(in anchor: AnchorEntity) {
        // Main directional light (sun-like) from upper right
        let directionalLight = DirectionalLight()
        directionalLight.light.color = .white
        directionalLight.light.intensity = 2000
        directionalLight.look(at: [0, 0, 0], from: [5, 8, 5], relativeTo: nil)

        // Enable shadows for more realistic rendering
        directionalLight.shadow?.shadowProjection = .automatic(maximumDistance: 15)
        directionalLight.shadow?.depthBias = 3.0

        anchor.addChild(directionalLight)

        // Fill light from opposite side (softer, cooler tone)
        let fillLight = DirectionalLight()
        fillLight.light.color = .init(red: 0.8, green: 0.9, blue: 1.0, alpha: 1.0)
        fillLight.light.intensity = 800
        fillLight.look(at: [0, 0, 0], from: [-3, 4, -3], relativeTo: nil)

        anchor.addChild(fillLight)

        // Ambient light for soft overall illumination
        let ambientLight = PointLight()
        ambientLight.light.color = .white
        ambientLight.light.intensity = 400
        ambientLight.light.attenuationRadius = 30
        ambientLight.position = [0, 8, 0]

        anchor.addChild(ambientLight)
    }

    /// Sets up a camera in the scene
    /// - Parameters:
    ///   - anchor: The anchor to add the camera to
    ///   - position: The position of the camera
    private func setCamera(in anchor: AnchorEntity, position: SIMD3<Float>) {
        let camera = PerspectiveCamera()
        camera.position = position
        camera.look(at: [0, 0, 0], from: position, relativeTo: anchor)
        anchor.addChild(camera)
    }

    /// Updates the model with new parameters
    func updateModel(_ newModel: USDZModel) {
        self.model = newModel
    }
}
