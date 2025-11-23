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

#### `JointMarkerComponent.swift`

- Custom RealityKit component for storing joint metadata on marker entities
- Properties: `jointIndex`, `jointName`, `isDraggable`
- Enables identification of joint markers during gesture handling

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

#### `ArticulationManager.swift`

Manages skeleton articulation and joint manipulation for interactive control.

**Public Methods:**

- `setupArticulation(for:skeletonInfo:configs:)` - Configures joints for articulation
- `identifyArticulationJoints(from:)` - Automatically identifies key joints (hands, elbows, shoulders)
- `handleJointDrag(jointIndex:translation:)` - Handles drag gestures on joints

**Features:**

- Creates visual markers for draggable joints
- Supports joint rotation constraints (min/max angles)
- Enables interactive manipulation of skeleton
- Automatically identifies hands, elbows, and shoulders by name patterns

#### `GestureManager.swift`

Manages gesture interactions for articulated joints.

**Public Methods:**

- `setupGestures(for:)` - Prepares gesture recognition
- `handleDragBegan(entity:at:)` - Handles drag start
- `handleDragChanged(entity:translation:)` - Updates joint during drag
- `handleDragEnded(entity:)` - Handles drag completion

**Features:**

- Tracks drag state for joint markers
- Coordinates with `ArticulationManager` for joint updates
- Smooth gesture-based joint manipulation

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
- `setupArticulation(for:skeletonInfo:anchor:)` - Configures interactive articulation

**Properties:**

- `articulationManager` - Manages joint articulation
- `gestureManager` - Handles gesture interactions
- `rootAnchor` - Reference to scene root for gesture coordination

### Views

SwiftUI views for UI presentation.

#### `ContentView.swift`

Main view with error handling and loading states.

#### `RealitySceneView.swift`

Interactive view that displays the RealityKit scene with gesture handling.

- Calls `viewModel.buildScene()`
- Blue sky gradient background
- Camera orbit controls
- **Drag gesture handling** for joint markers
- Coordinates with `GestureManager` for articulation

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

## Interactive Articulation System

The application now features a complete interactive articulation system:

### Current Features ✅

1. **Automatic Joint Detection** - Identifies hands, elbows, and shoulders from skeleton
2. **Visual Joint Markers** - Blue spheres mark draggable joints (hands)
3. **Drag Gestures** - Click and drag joint markers to move them
4. **Joint Constraints** - Configurable rotation limits per joint
5. **Clean Architecture** - Separated concerns across services

### How It Works

1. `SkeletonManager` extracts skeleton from USDZ model
2. `ArticulationManager.identifyArticulationJoints()` finds key joints (hands, elbows)
3. Visual markers created for draggable joints
4. `GestureManager` handles drag gestures on markers
5. View coordinates gestures with managers

### Making the Robot Wave

The system automatically creates draggable markers on the robot's hands. Users can:

- **Click and drag** hand markers to move them
- **Orbit camera** to view from different angles
- Joints respect configured rotation limits

## Next Steps for Full Ragdoll Physics

To implement full physics-based ragdoll:

1. Create `RagdollPhysicsManager` service
2. Generate physics bodies for bone segments between joints
3. Connect bodies with `PhysicsJointComponent` (hinges, ball-and-socket)
4. Apply gravity and physics simulation
5. Implement inverse kinematics for smooth motion

The current architecture makes these enhancements straightforward and maintainable.
