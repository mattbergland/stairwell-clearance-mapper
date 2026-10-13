import Foundation
import SwiftUI

/// The whole editable state of one site visit: chosen piano, obstacles in
/// walking order, units, and an optional job name. Auto-saved to disk.
struct Route: Codable {
    var piano: Piano?
    var obstacles: [Obstacle] = []
    var settings: Settings = Settings()
    var jobName: String?
}

enum LibraryState: Equatable {
    case loading
    case loaded([Piano])
    case failed(String)
}

@Observable
final class AppState {
    var route: Route {
        didSet { save() }
    }
    var libraryState: LibraryState = .loading
    var selectedTab = 0

    private var storageURL: URL { Self.storageURL() }

    private static func storageURL() -> URL {
        let support = FileManager.default.urls(for: .applicationSupportDirectory,
                                               in: .userDomainMask).first!
        let dir = support.appendingPathComponent("StairwellClearanceMapper", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("route.json")
    }

    init() {
        if ProcessInfo.processInfo.arguments.contains("-resetState") {
            route = Route()
        } else {
            route = (try? JSONDecoder().decode(Route.self,
                                               from: Data(contentsOf: Self.storageURL()))) ?? Route()
        }
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(route) else { return }
        try? data.write(to: storageURL, options: .atomic)
    }

    // MARK: - Library

    @MainActor
    func loadLibrary() async {
        libraryState = .loading
        let pianos: [Piano]? = await Task.detached(priority: .userInitiated) {
            guard let url = Bundle.main.url(forResource: "PianoLibrary", withExtension: "json"),
                  let data = try? Data(contentsOf: url) else { return nil }
            return try? JSONDecoder().decode([Piano].self, from: data)
        }.value
        if let pianos {
            libraryState = .loaded(pianos)
        } else {
            libraryState = .failed("The built-in piano list couldn't be loaded.")
        }
    }

    // MARK: - Route edits

    func choosePiano(_ piano: Piano) {
        route.piano = piano
    }

    func addObstacle(_ obstacle: Obstacle) {
        route.obstacles.append(obstacle)
    }

    func updateObstacle(_ obstacle: Obstacle) {
        if let index = route.obstacles.firstIndex(where: { $0.id == obstacle.id }) {
            route.obstacles[index] = obstacle
        }
    }

    func clearRoute() {
        route = Route(settings: route.settings)
    }

    /// The built-in example: an 1890s row house with a Steinway Model M
    /// headed to a second-floor parlor.
    func loadSampleJob() {
        var modelM = Piano(id: "steinway-model-m",
                           name: "Steinway Model M",
                           era: "1911–",
                           category: .grand,
                           weightLb: 560,
                           width: 56.5,
                           length: 67,
                           caseThickness: 13.5)
        if case let .loaded(pianos) = libraryState,
           let found = pianos.first(where: { $0.id == "steinway-model-m" }) {
            modelM = found
        }
        route.piano = modelM
        route.jobName = "1890s row house — 2nd-floor parlor"
        route.obstacles = [
            Obstacle(name: "Front door",
                     kind: .doorway(width: 36, height: 80)),
            Obstacle(name: "Vestibule door",
                     kind: .doorway(width: 32, height: 80)),
            Obstacle(name: "Main stairs",
                     kind: .straightStairs(width: 34, headroom: 80, rise: 8, run: 9)),
            Obstacle(name: "Landing turn",
                     kind: .turn90(widthIn: 34, widthOut: 32, ceiling: 96)),
            Obstacle(name: "Upper stairs",
                     kind: .straightStairs(width: 31, headroom: 76, rise: 8, run: 9)),
            Obstacle(name: "Parlor door",
                     kind: .doorway(width: 30, height: 79))
        ]
    }
}
