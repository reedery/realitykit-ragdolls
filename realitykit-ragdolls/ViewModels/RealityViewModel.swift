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
    
    // Managers
    private(set) var articulationManager: ArticulationManager?
    private(set) var gestureManager: GestureManager?
    private(set) var physicsRigManager: PhysicsRigManager?
    var skeletonController: DirectSkeletonController?  // Public for gesture access
    
    // Scene reference for gesture handling
    private(set) var rootAnchor: AnchorEntity?

    // MARK: - Initialization

    init(model: USDZModel = USDZModel(fileName: "robot.usdz")) {
        self.model = model
        
        // Register custom components
        JointMarkerComponent.registerComponent()
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
        rootAnchor = anchor

        // Load and add the model
        guard let modelEntity = await loadModelEntity() else {
            return nil
        }

        // Add scene elements
        anchor.addChild(createGroundPlane())
        anchor.addChild(modelEntity)
        setupLighting(in: anchor)
        setCamera(in: anchor, position: [0, 2, 5])
        
        // Setup articulation if we have skeleton info
        if let skeletonInfo = model.skeletonInfo {
            // Use DIRECT skeleton control (proven to work!)
            setupDirectSkeletonControl(for: modelEntity, skeletonInfo: skeletonInfo, anchor: anchor)
        }

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
            //entity.generateCollisionShapes(recursive: true)
            entity.components.set(InputTargetComponent())

            // Extract and store skeleton information
            if let skeletonInfo = SkeletonManager.extractSkeletonInfo(from: entity) {
                model.skeletonInfo = skeletonInfo
                
                // Print debug information
                print("\n=== Entity Hierarchy ===")
                SkeletonManager.printEntityHierarchy(entity)
                SkeletonManager.printSkeletonDebugInfo(from: entity)
                
                // TEST: Can we control the skeleton at all?
                let isControllable = SkeletonControlTest.testSkeletonControl(on: entity)
                if isControllable {
                    print("\n✅ Skeleton is controllable! Setting up direct control...")
                } else {
                    print("\n⚠️ WARNING: This skeleton cannot be directly controlled")
                    print("   Possible solutions:")
                    print("   1. Use ARKit body tracking (track a real person)")
                    print("   2. Use pre-made animations")
                    print("   3. Find a different model format")
                }
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
        //planeEntity.generateCollisionShapes(recursive: false)

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

    /// Sets up articulation for the skeleton (OLD APPROACH - marker based)
    /// - Parameters:
    ///   - modelEntity: The entity containing the skeleton
    ///   - skeletonInfo: Information about the skeleton
    ///   - anchor: The root anchor
    private func setupArticulation(
        for modelEntity: Entity,
        skeletonInfo: SkeletonInfo,
        anchor: AnchorEntity
    ) {
        print("\n=== Configuring Articulation ===")
        
        // Identify articulation joints
        let jointConfigs = ArticulationManager.identifyArticulationJoints(from: skeletonInfo)
        
        if jointConfigs.isEmpty {
            print("No articulation joints found")
            return
        }
        
        // Create articulation manager
        let articulationMgr = ArticulationManager()
        articulationMgr.setupArticulation(for: modelEntity, skeletonInfo: skeletonInfo, configs: jointConfigs)
        self.articulationManager = articulationMgr
        
        // Create gesture manager
        let gestureMgr = GestureManager(articulationManager: articulationMgr)
        gestureMgr.setupGestures(for: modelEntity)
        self.gestureManager = gestureMgr
        
        print("Articulation setup complete with \(jointConfigs.count) joints")
    }
    
    /// Sets up physics-based articulation rig (NEW APPROACH - ragdoll physics)
    /// - Parameters:
    ///   - modelEntity: The entity containing the skeleton
    ///   - skeletonInfo: Information about the skeleton
    ///   - anchor: The root anchor
    private func setupPhysicsRig(
        for modelEntity: Entity,
        skeletonInfo: SkeletonInfo,
        anchor: AnchorEntity
    ) {
        print("\n=== Setting Up Physics-Based Articulation ===")
        
        // Create physics rig manager
        let physicsRig = PhysicsRigManager()
        
        // Create a simple test rig with one articulated arm
        if let handMarker = physicsRig.createTestArmRig(in: anchor, skeletonInfo: skeletonInfo) {
            print("✓ Physics test rig created successfully!")
            print("  Green sphere = draggable hand marker")
            print("  Red sphere = fixed shoulder anchor")
            print("  Orange box = arm bone (should rotate when you drag the hand)")
        } else {
            print("⚠️ Failed to create physics test rig")
        }
        
        self.physicsRigManager = physicsRig
    }
    
    /// Sets up direct skeleton control (WORKING METHOD!)
    /// - Parameters:
    ///   - modelEntity: The entity containing the skeleton
    ///   - skeletonInfo: Information about the skeleton
    ///   - anchor: The root anchor
    private func setupDirectSkeletonControl(
        for modelEntity: Entity,
        skeletonInfo: SkeletonInfo,
        anchor: AnchorEntity
    ) {
        print("\n=== Setting Up DIRECT Skeleton Control ===")
        
        let controller = DirectSkeletonController()
        
        // Setup with arm joints we discovered
        let controlJoints = [36, 37, 38, 64, 65, 66]  // Arm joints
        
        if controller.setup(skeletalRoot: modelEntity, controlJoints: controlJoints, in: anchor) {
            self.skeletonController = controller
            
            print("\n🎉 SUCCESS! Direct skeleton control is active!")
            print("   Purple markers = controllable joints")
            print("   These will actually control the robot skeleton!")
            
            // Reset to neutral pose and create controls
            print("\n🤖 Initializing robot controls...")
            controller.resetToNeutralPose()
            
            // Pass the model entity to position controls correctly
            controller.createInteractiveControls(modelEntity: modelEntity, in: anchor)
            
            print("\n✅ Robot ready!")
            print("   🟢 Green = Move character")
            print("   🔴 Red = Right arm IK")
            print("   🔵 Blue = Left arm IK")
            print("   Drag handles to pose the robot!")
        } else {
            print("⚠️ Failed to setup direct skeleton control")
        }
    }
    
    /// Updates the model with new parameters
    func updateModel(_ newModel: USDZModel) {
        self.model = newModel
    }
}
