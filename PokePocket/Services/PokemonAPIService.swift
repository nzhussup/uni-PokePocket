import Foundation

enum PokemonAPIError: LocalizedError, Equatable {
    case invalidURL
    case notFound
    case serviceUnavailable
    case requestFailed
    case decodingError

    var errorDescription: String? {
        switch self {
        case .invalidURL: "Something went wrong while preparing your request."
        case .notFound: "We couldn’t find that Pokémon. Check the name and try again."
        case .serviceUnavailable: "Pokémon data is unavailable right now. Please try again shortly."
        case .requestFailed: "You appear to be offline. Check your connection and try again."
        case .decodingError: "We couldn’t display this Pokémon right now. Please try again."
        }
    }
}

struct PokemonAPIService: Sendable {
    private let baseURL = "https://pokeapi.co/api/v2"

    nonisolated init() {}

    func fetchPokemonPage(url: URL? = nil, offset: Int = 0, limit: Int = 100) async throws -> PokemonListResponse {
        if let url {
            return try await request(url: url)
        }
        return try await request(path: "/pokemon?limit=\(limit)&offset=\(offset)")
    }

    func fetchPokemonCatalog() async throws -> [PokemonListItem] {
        let response = try await fetchPokemonPage(limit: 2000)
        return response.results
    }

    func fetchPokemon(named name: String) async throws -> PokemonDetail {
        let encodedName = name.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? name
        return try await request(path: "/pokemon/\(encodedName.lowercased())")
    }

    func fetchPokemonDetails(named name: String) async throws -> PokemonDetailsBundle {
        let pokemon = try await fetchPokemon(named: name)
        guard let speciesURLString = pokemon.species.url,
              let speciesURL = URL(string: speciesURLString) else {
            throw PokemonAPIError.invalidURL
        }

        let species: PokemonSpecies = try await request(url: speciesURL)
        var evolution: EvolutionChain?
        if let evolutionURLString = species.evolutionChain?.url,
           let evolutionURL = URL(string: evolutionURLString) {
            evolution = try? await request(url: evolutionURL)
        }

        let forms = await fetchForms(pokemon.forms)
        return PokemonDetailsBundle(
            pokemon: pokemon,
            species: species,
            evolution: evolution,
            forms: forms
        )
    }

    private func fetchForms(_ resources: [NamedResource]) async -> [PokemonFormDetail] {
        await withTaskGroup(of: PokemonFormDetail?.self) { group in
            for resource in resources {
                guard let urlString = resource.url, let url = URL(string: urlString) else { continue }
                group.addTask { try? await request(url: url) }
            }

            var forms = [PokemonFormDetail]()
            for await form in group {
                if let form { forms.append(form) }
            }
            return forms.sorted { $0.name < $1.name }
        }
    }

    private func request<T: Decodable>(path: String) async throws -> T {
        guard let url = URL(string: baseURL + path) else {
            throw PokemonAPIError.invalidURL
        }
        return try await request(url: url)
    }

    private func request<T: Decodable>(url: URL) async throws -> T {
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw PokemonAPIError.serviceUnavailable
            }
            if httpResponse.statusCode == 404 { throw PokemonAPIError.notFound }
            guard 200..<300 ~= httpResponse.statusCode else {
                throw PokemonAPIError.serviceUnavailable
            }

            do {
                return try JSONDecoder().decode(T.self, from: data)
            } catch {
                throw PokemonAPIError.decodingError
            }
        } catch let error as PokemonAPIError {
            throw error
        } catch {
            throw PokemonAPIError.requestFailed
        }
    }
}
