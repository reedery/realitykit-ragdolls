# USDZ Import Instructions

This guide explains how to import USDZ 3D model files into your RealityKit project.

## Project Architecture

This project follows the **MVVM (Model-View-ViewModel)** architecture pattern:

- **Model** (`Models/USDZModel.swift`): Represents USDZ file data and transformations
- **ViewModel** (`ViewModels/RealityViewModel.swift`): Handles RealityKit logic and model loading
- **View** (`Views/ContentView.swift`): SwiftUI interface with RealityView for 3D rendering

## Method 1: Using Xcode (Recommended)

### Step 1: Prepare Your USDZ File
Ensure you have a `.usdz` file ready. You can:
- Create one using Reality Composer
- Export from 3D modeling software (Blender, Maya, etc.)
- Download from online sources

### Step 2: Add to Xcode Project
1. Open `realitykit-ragdolls.xcodeproj` in Xcode
2. In the Project Navigator (left sidebar), locate the `Assets3d` folder
3. Right-click on `Assets3d` and select **"Add Files to 'realitykit-ragdolls'..."**
4. Navigate to your USDZ file
5. **IMPORTANT**: Make sure the following options are selected:
   - ✅ **"Copy items if needed"** (this copies the file into your project)
   - ✅ **"Create groups"** (not folder references)
   - ✅ Under "Add to targets", ensure **"realitykit-ragdolls"** is checked
6. Click **"Add"**

### Step 3: Verify the File
1. The USDZ file should now appear in the `Assets3d` folder in Xcode
2. Click on the file to preview it in Xcode's 3D viewer
3. Build the project (⌘B) to ensure it's included in the bundle

### Step 4: Use the Model in Code
Update the ViewModel initialization to use your new file:

```swift
// In ContentView.swift or wherever you initialize the ViewModel
@State private var viewModel = RealityViewModel(
    model: USDZModel(fileName: "your_model_name.usdz")
)
```

Or update the default model in `RealityViewModel.swift`:

```swift
init(model: USDZModel = USDZModel(fileName: "your_model_name.usdz")) {
    self.model = model
}
```

## Method 2: Manual File System Copy

### Step 1: Copy File to Assets3d Folder
```bash
# From your terminal, navigate to the project directory
cd /path/to/realitykit-ragdolls
cp /path/to/your_model.usdz ./Assets3d/
```

### Step 2: Add to Xcode
Since this project uses Xcode's **File System Synchronization** feature (Xcode 15+), the file should automatically appear in Xcode. If not:
1. Close and reopen the project in Xcode
2. Or right-click the `Assets3d` folder and select **"Add Files to 'realitykit-ragdolls'..."** and add the file

## Current USDZ Files

The project currently includes:
- `biped_robot.usdz` - Default model loaded at origin
- `Morty_Rig_v01.usdz` - Alternative character model

## Customizing Model Appearance

You can customize the model's position, scale, and rotation when creating a `USDZModel`:

```swift
let customModel = USDZModel(
    fileName: "your_model.usdz",
    scale: [0.5, 0.5, 0.5],           // 50% scale
    position: [0, 0.2, -0.5],          // 20cm up, 50cm away
    rotation: simd_quatf(              // 45° rotation around Y axis
        angle: .pi / 4,
        axis: [0, 1, 0]
    )
)

@State private var viewModel = RealityViewModel(model: customModel)
```

## Troubleshooting

### Model Not Loading
- **Error: "Failed to load model"**
  - Verify the file name matches exactly (including `.usdz` extension)
  - Ensure the file is in the `Assets3d` folder
  - Check that the file is included in the build target (Target Membership in Xcode)
  - Try cleaning the build folder (⇧⌘K) and rebuilding

### Model Too Large/Small
- Adjust the `scale` parameter in the `USDZModel` initializer
- Example: `scale: [0.1, 0.1, 0.1]` makes it 10% of original size

### Model Not Visible
- The camera starts at world origin (0, 0, 0)
- Ensure your model is positioned where the camera can see it
- Try adjusting the `position` parameter
- Default position is `[0, 0, 0]` (origin)

## 2025 Swift Standards Used

This project uses the latest Swift and SwiftUI features:

- **@Observable** macro for ViewModels (iOS 17+)
- **RealityView** for RealityKit integration (iOS 17+)
- **async/await** for model loading
- **MVVM architecture** for clean separation of concerns
- **Modern SwiftUI App lifecycle** (no UIKit AppDelegate)
- **Strict concurrency checking** (@MainActor isolation)

## Resources

- [Apple's RealityKit Documentation](https://developer.apple.com/documentation/realitykit)
- [USDZ File Format](https://developer.apple.com/augmented-reality/usdz/)
- [Reality Composer](https://developer.apple.com/augmented-reality/tools/)
