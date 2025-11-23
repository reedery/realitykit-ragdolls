# RealityKit Ragdolls - Architecture Overview

## Project Structure

### Models

Defines the data structures for the application.

#### `USDZModel.swift`

- Represents a USDZ 3D model with metadata
- Properties: fileName, scale, position, rotation
- **New**: Contains optional `SkeletonInfo` for skeletal data
- Methods to check if model has skeleton and joint count

#### `Joint.swift`

- `Joint`: Represents a skeletal joint with transform data (translation, rotation, scale)
- `SkeletalPose`: Collection of joints representing a skeleton pose
- `SkeletonInfo`: Complete skeleton information including entity name, poses, and joint names

### Services

Business logic and utilities.

#### `SkeletonManager.swift`

Manages skeleton extraction and manipulation for USDZ models.

**Public Methods:**

- `extractSkeletonInfo(from:)` - Extracts skeleton data from entity hierarchy
- `printSkeletonDebugInfo(from:)` - Prints detailed skeleton information
- `printEntityHierarchy(_:indent:)` - Prints entity hierarchy for debugging

**Features:**

- Automatically discovers `SkeletalPosesComponent` in entity hierarchy
- Extracts joint names and transforms
- Provides structured skeleton data for ragdoll physics implementation

### ViewModels

Manages state and business logic for views.

#### `RealityViewModel.swift`

Manages RealityKit scene and USDZ model loading.

**Responsibilities:**

- Scene composition (builds complete RealityKit scene)
- Model loading and transformation
- Ground plane creation
- Lighting setup (3-point lighting system)
- Camera positioning
- Delegates skeleton operations to `SkeletonManager`

**Key Methods:**

- `buildScene()` - Constructs the entire scene
- `loadModelEntity()` - Loads USDZ model and extracts skeleton info
- `createGroundPlane()` - Creates physics-enabled ground
- `setupLighting(in:)` - Professional 3-point lighting
- `setCamera(in:position:)` - Camera setup

### Views

SwiftUI views for UI presentation.

#### `ContentView.swift`

Main view with error handling and loading states.

#### `RealitySceneView.swift`

Minimal view that displays the RealityKit scene.

- Calls `viewModel.buildScene()`
- Blue sky gradient background
- Camera orbit controls

## Separation of Concerns

### ✅ Models

Pure data structures with no business logic. Easily testable and reusable.

### ✅ Services

Encapsulated business logic. `SkeletonManager` handles all skeleton-related operations independently.

### ✅ ViewModels

Orchestrates scene composition, delegates to services, manages state. No skeleton extraction logic.

### ✅ Views

Purely presentational. Minimal logic, just displays what the ViewModel provides.

## Benefits of New Architecture

1. **Modularity**: Skeleton logic is isolated in `SkeletonManager`
2. **Testability**: Each component can be tested independently
3. **Reusability**: `SkeletonManager` can be used with any USDZ model
4. **Maintainability**: Changes to skeleton logic don't affect ViewModel or Views
5. **Scalability**: Easy to add new features (e.g., ragdoll physics, animation)

## Next Steps for Ragdoll Physics

With the skeleton data now properly extracted and structured:

1. Create `RagdollPhysicsManager` service
2. Use `SkeletonInfo` to identify joint pairs
3. Create physics bodies for each bone segment
4. Connect bodies with `PhysicsJointComponent` (hinges, ball-and-socket)
5. Apply physics properties (mass, friction, damping)
6. Implement joint limits for realistic movement

The current architecture makes these steps straightforward and maintainable.
