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
            // Handle any updates to the scene here if needed
        }
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
}

// MARK: - Preview

#Preview {
    RealitySceneView(viewModel: RealityViewModel())
}
