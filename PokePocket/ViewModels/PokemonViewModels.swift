import Foundation
import Combine

@MainActor
final class PokemonListViewModel: ObservableObject {
    @Published private(set) var pokemon: [PokemonListItem] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isLoadingNextPage = false
    @Published private(set) var hasLoadedAllPokemon = false
    @Published private(set) var searchResults: [PokemonListItem] = []
    @Published private(set) var isSearching = false
    @Published private(set) var searchErrorMessage: String?
    @Published var errorMessage: String?

    private let service: PokemonAPIService
    private var nextPageURL: URL?
    private var searchCatalog: [PokemonListItem]?

    init(service: PokemonAPIService = PokemonAPIService()) {
        self.service = service
    }

    func loadPokemon() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        do {
            let page = try await service.fetchPokemonPage()
            pokemon = page.results
            nextPageURL = page.next.flatMap(URL.init(string:))
            hasLoadedAllPokemon = nextPageURL == nil
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func loadNextPageIfNeeded(after item: PokemonListItem) async {
        guard item.id == pokemon.last?.id,
              !isLoading,
              !isLoadingNextPage,
              !hasLoadedAllPokemon else { return }

        isLoadingNextPage = true
        do {
            let page = try await service.fetchPokemonPage(url: nextPageURL)
            pokemon.append(contentsOf: page.results)
            nextPageURL = page.next.flatMap(URL.init(string:))
            hasLoadedAllPokemon = nextPageURL == nil
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoadingNextPage = false
    }

    func searchPokemon(_ searchText: String) async {
        let prefix = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prefix.isEmpty else {
            searchResults = []
            searchErrorMessage = nil
            return
        }

        isSearching = true
        searchErrorMessage = nil
        defer { isSearching = false }

        do {
            if searchCatalog == nil {
                searchCatalog = try await service.fetchPokemonCatalog()
            }
            searchResults = searchCatalog?.filter {
                $0.name.lowercased().hasPrefix(prefix.lowercased())
            } ?? []
        } catch {
            searchResults = []
            searchErrorMessage = error.localizedDescription
        }
    }

}

@MainActor
final class PokemonDetailViewModel: ObservableObject {
    @Published private(set) var pokemon: PokemonDetail?
    @Published private(set) var species: PokemonSpecies?
    @Published private(set) var evolution: EvolutionChain?
    @Published private(set) var forms: [PokemonFormDetail] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    @Published private(set) var isNotFound = false

    private let service: PokemonAPIService

    init(service: PokemonAPIService = PokemonAPIService()) {
        self.service = service
    }

    func load(named name: String) async {
        isLoading = true
        errorMessage = nil
        isNotFound = false
        do {
            let details = try await service.fetchPokemonDetails(named: name)
            pokemon = details.pokemon
            species = details.species
            evolution = details.evolution
            forms = details.forms
        } catch {
            pokemon = nil
            species = nil
            evolution = nil
            forms = []
            isNotFound = (error as? PokemonAPIError) == .notFound
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
