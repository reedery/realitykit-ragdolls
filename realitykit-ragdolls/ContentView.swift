//
//  ContentView.swift
//  realitykit-ragdolls
//
//  Created by ryan reede on 11/22/25.
//

import SwiftUI
import RealityKit

struct ContentView: View {
    @StateObject private var viewModel = RagdollViewModel()

    var body: some View {
        ZStack {
            RealityView { content in
                do {
                    let scene = try viewModel.setupRagdoll()
                    content.add(scene)
                } catch {
                    print("Error setting up ragdoll: \(error)")
                }
            }
            .gesture(
                DragGesture()
                    .targetedToAnyEntity()
                    .onChanged { value in
                        viewModel.onDragChanged(value: value.gestureValue, in: value.entity)
                    }
                    .onEnded { _ in
                        viewModel.onDragEnded()
                    }
            )
            .realityViewCameraControls(.orbit)

            // Optional: Visual feedback when dragging
            if viewModel.isDragging {
                VStack {
                    Text("Dragging torso")
                        .font(.caption)
                        .padding(8)
                        .background(.ultraThinMaterial)
                        .cornerRadius(8)
                    Spacer()
                }
                .padding()
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
}

#Preview {
    ContentView()
}
