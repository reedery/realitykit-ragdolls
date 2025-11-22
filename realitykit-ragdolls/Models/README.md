# RealityKit Ragdolls - Project Overview

## Project Structure

This project demonstrates a physics-based ragdoll character in RealityKit with interactive dragging.

### Files

1. **RagdollPhysics-Models.swift** - Physics helper functions
2. **RagdollBodyPart.swift** - Factory for creating body part entities
3. **RagdollBuilder.swift** - Assembles the complete ragdoll with joints
4. **RagdollViewModel.swift** - Manages ragdoll state and interactions
5. **ContentView.swift** - SwiftUI view with RealityView
6. **AppDelegate.swift** - App setup
7. **RagdollTests.swift** - Comprehensive test suite

## Architecture

```
ContentView (SwiftUI)
    ↓
RagdollViewModel (State Management)
    ↓
RagdollBuilder (Assembly)
    ↓
RagdollBodyPart (Creation) + RagdollPhysics (Physics)
    ↓
RealityKit Entities
```

## Key Features

### 1. Ragdoll Structure
- **Torso** (kinematic) - Blue sphere, draggable
- **Head** (dynamic) - Orange sphere
- **Arms** (dynamic) - Orange boxes (upper & lower × 2)
- **Legs** (dynamic) - Orange boxes (upper & lower × 2)

### 2. Physics Setup
- **Kinematic torso**: Can be moved by user, drives the rest
- **Dynamic limbs**: React to physics and joints
- **High damping**: Prevents wild oscillations
- **Revolute joints**: Connect all body parts

### 3. Interaction
- **Drag gesture**: Drag the blue torso to move the ragdoll
- **Orbit controls**: Camera can be rotated around the scene
- **Visual feedback**: Shows "Dragging torso" when active

## How to Use

### Running the App

1. Build and run the project (⌘R)
2. You'll see a ragdoll character in 3D space
3. Drag the blue torso sphere to move the ragdoll
4. Use touch gestures to orbit the camera
5. Watch the limbs react with physics

### Running Tests

1. Press ⌘U to run all tests
2. Or use Product → Test in Xcode
3. Tests verify:
   - Scene creation
   - All body parts exist
   - Physics components are correct
   - Collision detection works
   - ViewModel state management

### Customization

#### Change Body Part Colors
In `RagdollBodyPart.swift`, modify the `baseColor.tint`:
```swift
material.baseColor.tint = .red  // Change to any UIColor
```

#### Adjust Physics
In `RagdollPhysics-Models.swift`, tune:
- `angularDamping`: Higher = less rotation
- `linearDamping`: Higher = less movement
- `mass`: Heavier parts move less

#### Modify Joint Behavior
In `RagdollBuilder.swift`, adjust joint positions and axes in `createJoints()`

#### Change Gravity
In `RagdollBuilder.swift`, modify:
```swift
simulationComponent.gravity = [0, -2.0, 0]  // Change Y value
```

## Testing Guide

### Unit Tests
The test suite covers:
- ✅ Scene creation
- ✅ Body part existence
- ✅ Physics modes (kinematic vs dynamic)
- ✅ Collision components
- ✅ ViewModel state management

### Manual Testing Checklist
- [ ] App launches without crashes
- [ ] Ragdoll appears on screen
- [ ] Torso can be dragged
- [ ] Limbs follow with physics
- [ ] Camera controls work
- [ ] No parts fly off wildly
- [ ] Joints hold together

## Troubleshooting

### Ragdoll Parts Fly Apart
- Increase damping values in `RagdollPhysics-Models.swift`
- Check joint offsets in `RagdollBuilder.swift`
- Increase solver iterations in `buildRagdollScene()`

### Dragging Doesn't Work
- Ensure torso has `InputTargetComponent`
- Check gesture is targeting the torso entity
- Verify torso is kinematic mode

### Physics Too Fast/Slow
- Adjust gravity in simulation component
- Modify mass values for body parts
- Change damping parameters

## Next Steps

### Enhancements You Can Add
1. **Joint Limits**: Add angle constraints to joints
2. **Multiple Ragdolls**: Create an array of ragdolls
3. **Animations**: Add keyframe animations
4. **Ground Plane**: Add a floor for ragdoll to stand on
5. **Force Application**: Add tap to apply impulse forces
6. **Ragdoll Poses**: Save and load specific poses
7. **Better Materials**: Use PBR textures and lighting

## Code Quality

- ✅ Clean separation of concerns
- ✅ Comprehensive documentation
- ✅ Type-safe Swift APIs
- ✅ SwiftUI best practices
- ✅ Async/await ready
- ✅ MainActor annotations
- ✅ Observable pattern with @Published

## Performance Notes

- Uses RealityKit's native physics engine
- Efficient entity hierarchy
- Minimal overhead from SwiftUI/RealityKit bridge
- Suitable for multiple ragdolls if needed

---

**Platform**: iOS 18+ / iPadOS 18+  
**Language**: Swift 6  
**Frameworks**: RealityKit, SwiftUI  
**Testing**: Swift Testing framework
