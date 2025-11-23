import SwiftUI
import RealityKit
import Combine


struct RobotModelView: View {
    @EnvironmentObject var viewModel: RobotModelViewModel

    var body: some View {
        ZStack {
            // Sky gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.4, green: 0.7, blue: 1.0),
                    Color(red: 0.9, green: 0.9, blue: 1.0)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            RealityView { content in
                await viewModel.setupScene(in: content)
            }
            .realityViewCameraControls(.orbit)
            .opacity(viewModel.assetsLoaded ? 1 : 0)

            // Loading screen
            ZStack {
                Color.white
                Text("Loading robot model...")
                    .foregroundColor(Color.black)
            }
            .opacity(viewModel.assetsLoaded ? 0 : 1)
            .ignoresSafeArea()
            .animation(Animation.default.speed(1), value: viewModel.assetsLoaded)
        }
        .navigationTitle("Robot Model")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        RobotModelView()
            .environmentObject(RobotModelViewModel())
    }
}


// MARK: - View Model

@MainActor
final class RobotModelViewModel: ObservableObject {
    /// Allow loading to take a minimum amount of time, to ease state transitions
    private static let loadBuffer: TimeInterval = 2
    
    private let robotLoader = RobotLoader()
    private var loadCancellable: AnyCancellable?
    
    @Published var assetsLoaded = false
    
    init() {}
    
    func resume() {
        if !assetsLoaded && loadCancellable == nil {
            loadAssets()
        }
    }
    
    func pause() {
        loadCancellable?.cancel()
        loadCancellable = nil
    }
    
    // MARK: - Scene Setup
    
    func setupScene(in content: some RealityViewContentProtocol) async {
        guard assetsLoaded else {
            print("Assets not loaded yet")
            return
        }
        
        do {
            // Create a new robot instance from pre-loaded model
            let robot = try robotLoader.createRobot()
            robot.position = [0, 0, -1]  // Position in front of camera
            
            content.add(robot)
            addLighting(to: content)
            
            print("Robot model loaded successfully")
            
        } catch {
            print("Error loading robot model: \(error)")
        }
    }
    
    // MARK: - Private methods
    
    private func loadAssets() {
        let beforeTime = Date().timeIntervalSince1970
        
        loadCancellable = robotLoader.loadResources { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case let .failure(error):
                print("Failed to load assets: \(error)")
            case .success:
                let delta = Date().timeIntervalSince1970 - beforeTime
                var buffer = Self.loadBuffer - delta
                if buffer < 0 {
                    buffer = 0
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + buffer) {
                    self.assetsLoaded = true
                }
            }
        }
    }
    
    // MARK: - Lighting
    
    private func addLighting(to content: some RealityViewContentProtocol) {
        // Directional light (sun)
        let sunlight = DirectionalLight()
        sunlight.light.intensity = 2000
        sunlight.light.color = .white
        sunlight.look(at: [0, 0, 0], from: [3, 5, 3], relativeTo: nil)
        sunlight.shadow?.shadowProjection = .automatic(maximumDistance: 5.0)
        sunlight.shadow?.depthBias = 0.5
        content.add(sunlight)
        
        // Ambient light
        let ambient = PointLight()
        ambient.light.intensity = 500
        ambient.light.color = .white
        ambient.light.attenuationRadius = 10
        ambient.position = [0, 3, 0]
        content.add(ambient)
    }
}


// MARK: - Preview

#Preview {
    NavigationStack {
        RobotModelView()
    }
}
