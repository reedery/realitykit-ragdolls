import RealityKit
import Foundation
import Combine

@MainActor
final class RobotLoader {
    private var robotModelEntity: Entity?
    
    /// Load the robot USDZ model asynchronously
    func loadResources(completion: @escaping (Result<Void, Error>) -> Void) -> AnyCancellable {
        // Load the USDZ file from the bundle
        Entity.loadAsync(named: "robot")
            .sink(
                receiveCompletion: { loadCompletion in
                    switch loadCompletion {
                    case .finished:
                        completion(.success(()))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                },
                receiveValue: { [weak self] entity in
                    // Store the loaded entity for later use
                    self?.robotModelEntity = entity
                    print("Robot model loaded and cached")
                }
            )
    }
    
    /// Create a new instance of the robot from the pre-loaded model
    func createRobot() throws -> Entity {
        guard let model = robotModelEntity else {
            throw RobotLoaderError.modelNotLoaded
        }
        
        // Clone the entity so we can create multiple instances if needed
        return model.clone(recursive: true)
    }
}

// MARK: - Error Types

enum RobotLoaderError: Error, LocalizedError {
    case modelNotLoaded
    
    var errorDescription: String? {
        switch self {
        case .modelNotLoaded:
            return "Robot model has not been loaded yet"
        }
    }
}
