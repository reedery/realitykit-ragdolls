//
//  HomeView.swift
//  realitykit-ragdolls
//
//  Created by ryan reede on 11/22/25.
//

import SwiftUI

struct HomeView: View {
    @State private var selectedCharacter: CharacterConfiguration?
    @State private var showPhysicsDebug = false
    @State private var navigateToRagdoll = false
    @State private var navigateToRobot = false

    let characters = CharacterConfiguration.loadPresets()

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.1, green: 0.2, blue: 0.4),
                        Color(red: 0.2, green: 0.3, blue: 0.5)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 30) {
                    // Title
                    Text("RealityKit Ragdolls")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.top, 50)

                    // Robot Ragdoll Button
                    Button(action: {
                        navigateToRobot = true
                    }) {
                        HStack {
                            Image(systemName: "figure.walk.motion")
                                .font(.title2)
                            Text("Robot Model Demo") //not ragdoll
                                .font(.title3.bold())
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.green, Color.blue]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(15)
                        .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 2)
                    }
                    .padding(.horizontal, 40)

                    Divider()
                        .background(Color.white.opacity(0.3))
                        .padding(.horizontal, 40)
                        .padding(.vertical, 10)

                    Text("Select a Character")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.8))

                    // Character selection grid
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 20) {
                        ForEach(characters) { character in
                            CharacterCard(
                                character: character,
                                isSelected: selectedCharacter?.id == character.id
                            )
                            .onTapGesture {
                                selectedCharacter = character
                            }
                        }
                    }
                    .padding(.horizontal)

                    Spacer()

                    // Debug toggle
                    Toggle(isOn: $showPhysicsDebug) {
                        Text("Show Physics Debug Controls")
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 40)
                    .tint(.orange)

                    // Launch button
                    Button(action: {
                        if selectedCharacter != nil {
                            navigateToRagdoll = true
                        }
                    }) {
                        Text("Launch Ragdoll")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                selectedCharacter != nil ?
                                Color.blue : Color.gray
                            )
                            .cornerRadius(15)
                    }
                    .padding(.horizontal, 40)
                    .disabled(selectedCharacter == nil)

                    Spacer()
                        .frame(height: 50)
                }
            }
            .navigationDestination(isPresented: $navigateToRagdoll) {
                if let character = selectedCharacter {
                    RagdollSceneView(
                        character: character,
                        showPhysicsDebug: showPhysicsDebug
                    )
                    .navigationBarBackButtonHidden(false)
                }
            }
            .navigationDestination(isPresented: $navigateToRobot) {
                //RobotRagdollView().navigationBarBackButtonHidden(false)
                RobotModelView().navigationBarBackButtonHidden(false)
            }
        }
    }
}

struct CharacterCard: View {
    let character: CharacterConfiguration
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 12) {
            // Character icon (using color as preview)
            ZStack {
                Circle()
                    .fill(Color(uiColor: character.visualProperties.torsoColor.toUIColor()))
                    .frame(width: 80, height: 80)

                Circle()
                    .fill(Color(uiColor: character.visualProperties.headColor.toUIColor()))
                    .frame(width: 40, height: 40)
                    .offset(y: -25)
            }
            .padding()

            Text(character.displayName)
                .font(.headline)
                .foregroundColor(.white)

            // Stats
            VStack(alignment: .leading, spacing: 4) {
                StatRow(label: "Mass", value: String(format: "%.1f", character.physicsProperties.torsoMass))
                StatRow(label: "Height", value: character.bodyProportions.upperLegLength > 0.35 ? "Tall" : character.bodyProportions.upperLegLength < 0.28 ? "Short" : "Med")
            }
            .font(.caption)
            .foregroundColor(.white.opacity(0.8))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(isSelected ? Color.blue.opacity(0.3) : Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
                )
        )
    }
}

struct StatRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label + ":")
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
    }
}

#Preview {
    HomeView()
}
