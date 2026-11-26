import SwiftUI
import Combine

struct PokemonRoute: Hashable {
    let name: String
}

@MainActor
final class NavigationRouter: ObservableObject {
    @Published var path = NavigationPath()

    func handle(url: URL) {
        guard url.scheme == "pokepocket",
              url.host?.lowercased() == "pokemon",
              let name = url.pathComponents.dropFirst().first,
              !name.isEmpty else { return }

        path.append(PokemonRoute(name: name.removingPercentEncoding ?? name))
    }

    func consumePokemonRequest() {
        guard let name = UserDefaults.standard.string(
            forKey: PokemonNavigationRequest.defaultsKey
        ) else { return }

        UserDefaults.standard.removeObject(forKey: PokemonNavigationRequest.defaultsKey)
        path.append(PokemonRoute(name: name))
    }
}
