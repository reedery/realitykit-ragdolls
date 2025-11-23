//
//  ContentView.swift
//  realitykit-ragdolls
//
//  Created by ryan reede on 11/22/25.
//

import SwiftUI
import RealityKit

struct ContentView: View {

    // MARK: - Properties

    @State private var viewModel = RealityViewModel()

    // MARK: - Body

    var body: some View {
        ZStack {
            // RealityKit 3D Scene
            RealitySceneView(viewModel: viewModel)
                .ignoresSafeArea()

            // Error overlay
            if let error = viewModel.loadingError {
                VStack {
                    Spacer()
                    ErrorView(message: error)
                        .padding()
                }
            }

            // Loading indicator
            if viewModel.isLoading {
                ProgressView("Loading model...")
                    .padding()
                    .background(.regularMaterial)
                    .cornerRadius(10)
            }
        }
    }
}

// MARK: - Error View

struct ErrorView: View {
    let message: String

    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.yellow)
            Text(message)
                .font(.caption)
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(10)
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
