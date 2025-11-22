//
//  PhysicsDebugView.swift
//  realitykit-ragdolls
//
//  Created by ryan reede on 11/22/25.
//

import SwiftUI

struct PhysicsDebugView: View {
    @Bindable var config: PhysicsConfiguration
    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            // Toggle button
            Button(action: {
                withAnimation(.spring(response: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Image(systemName: "wrench.and.screwdriver.fill")
                    Text("Physics Debug")
                        .font(.headline)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(12, corners: isExpanded ? [.topLeft, .topRight] : .allCorners)
            }

            if isExpanded {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Gravity
                        DebugSlider(
                            title: "Gravity",
                            value: $config.gravity,
                            range: -20...0,
                            unit: "m/s²"
                        )

                        Divider()

                        // Solver Iterations
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Solver Iterations")
                                .font(.headline)

                            DebugSlider(
                                title: "Position",
                                value: Binding(
                                    get: { Float(config.positionIterations) },
                                    set: { config.positionIterations = UInt32($0) }
                                ),
                                range: 10...200,
                                step: 10,
                                unit: ""
                            )

                            DebugSlider(
                                title: "Velocity",
                                value: Binding(
                                    get: { Float(config.velocityIterations) },
                                    set: { config.velocityIterations = UInt32($0) }
                                ),
                                range: 10...200,
                                step: 10,
                                unit: ""
                            )
                        }

                        Divider()

                        // Damping
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Damping")
                                .font(.headline)

                            DebugSlider(
                                title: "Angular",
                                value: $config.angularDamping,
                                range: 0...30,
                                unit: ""
                            )

                            DebugSlider(
                                title: "Linear",
                                value: $config.linearDamping,
                                range: 0...20,
                                unit: ""
                            )

                            DebugSlider(
                                title: "Extremity Angular",
                                value: $config.extremityAngularDamping,
                                range: 0...30,
                                unit: ""
                            )

                            DebugSlider(
                                title: "Extremity Linear",
                                value: $config.extremityLinearDamping,
                                range: 0...20,
                                unit: ""
                            )
                        }

                        Divider()

                        // Material Properties
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Material Properties")
                                .font(.headline)

                            DebugSlider(
                                title: "Static Friction",
                                value: $config.staticFriction,
                                range: 0...2,
                                unit: ""
                            )

                            DebugSlider(
                                title: "Dynamic Friction",
                                value: $config.dynamicFriction,
                                range: 0...2,
                                unit: ""
                            )

                            DebugSlider(
                                title: "Restitution",
                                value: $config.restitution,
                                range: 0...1,
                                unit: ""
                            )
                        }

                        Divider()

                        // Joint Limits
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Joint Limits")
                                .font(.headline)

                            DebugSlider(
                                title: "Shoulder Cone",
                                value: $config.shoulderConeLimitDegrees,
                                range: 0...90,
                                unit: "°"
                            )

                            DebugSlider(
                                title: "Hip Cone",
                                value: $config.hipConeLimitDegrees,
                                range: 0...90,
                                unit: "°"
                            )

                            DebugSlider(
                                title: "Neck Cone",
                                value: $config.neckConeLimitDegrees,
                                range: 0...45,
                                unit: "°"
                            )

                            DebugSlider(
                                title: "Elbow Max Bend",
                                value: $config.elbowMaxBendDegrees,
                                range: 90...180,
                                unit: "°"
                            )

                            DebugSlider(
                                title: "Knee Max Bend",
                                value: $config.kneeMaxBendDegrees,
                                range: 90...180,
                                unit: "°"
                            )
                        }

                        // Reset button
                        Button(action: {
                            config.reset()
                        }) {
                            Text("Reset to Defaults")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.orange)
                                .cornerRadius(10)
                        }
                        .padding(.top, 10)
                    }
                    .padding()
                }
                .frame(maxHeight: 500)
                .background(.ultraThinMaterial)
                .cornerRadius(12, corners: [.bottomLeft, .bottomRight])
            }
        }
        .shadow(radius: 10)
    }
}

struct DebugSlider: View {
    let title: String
    @Binding var value: Float
    let range: ClosedRange<Float>
    var step: Float = 0.1
    let unit: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.body.weight(.medium))
                Spacer()
                Text(String(format: "%.1f\(unit)", value))
                    .font(.body.weight(.bold).monospacedDigit())
                    .foregroundColor(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(6)
            }

            Slider(value: $value, in: range, step: step)
                .tint(.blue)
        }
        .padding(.vertical, 4)
    }
}

// Helper for custom corner radius
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    PhysicsDebugView(config: PhysicsConfiguration())
        .padding()
}
