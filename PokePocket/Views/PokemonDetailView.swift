import SwiftUI
import AVFoundation

struct PokemonDetailView: View {
    let pokemonName: String

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = PokemonDetailViewModel()
    @State private var cryPlayer: AVPlayer?

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Loading details…")
            } else if let pokemon = viewModel.pokemon {
                details(for: pokemon)
            } else if let message = viewModel.errorMessage {
                errorView(message)
            }
        }
        .navigationTitle(viewModel.pokemon?.displayName ?? pokemonName.capitalized)
        .navigationBarTitleDisplayMode(.inline)
        .task(id: pokemonName) { await viewModel.load(named: pokemonName) }
    }

    private func details(for pokemon: PokemonDetail) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                PokemonHeroView(pokemon: pokemon)
                PokemonMeasurementsView(pokemon: pokemon)

                if let species = viewModel.species {
                    PokemonSpeciesSection(species: species, pokemon: pokemon)
                }

                PokemonAbilitiesSection(abilities: pokemon.abilities)
                PokemonStatsSection(stats: pokemon.stats)

                if let evolution = viewModel.evolution {
                    PokemonEvolutionSection(evolution: evolution, currentName: pokemon.name)
                }

                PokemonFormsSection(forms: viewModel.forms)

                if let varieties = viewModel.species?.varieties, varieties.count > 1 {
                    PokemonVarietiesSection(varieties: varieties, currentName: pokemon.name)
                }

                PokemonSpritesSection(sprites: pokemon.sprites)
                PokemonHeldItemsSection(items: pokemon.heldItems)
                PokemonGameAppearancesSection(games: pokemon.gameIndices)
                PokemonMovesSection(moves: pokemon.moves)
                PokemonCriesSection(cries: pokemon.cries, play: playCry)
            }
            .padding()
        }
    }

    private func errorView(_ message: String) -> some View {
        ContentUnavailableView {
            Label(
                viewModel.isNotFound ? "Pokémon Not Found" : "Couldn’t Load Pokémon",
                systemImage: viewModel.isNotFound ? "questionmark.circle" : "wifi.exclamationmark"
            )
        } description: {
            Text(message)
        } actions: {
            if viewModel.isNotFound {
                Button("Back to Pokédex") { dismiss() }
                    .buttonStyle(.borderedProminent)
            } else {
                Button("Try Again") { Task { await viewModel.load(named: pokemonName) } }
                    .buttonStyle(.borderedProminent)
            }
        }
    }

    private func playCry(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }

        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: .mixWithOthers)
            try audioSession.setActive(true)
        } catch {
            // AVPlayer can still attempt playback if the session is managed externally.
        }

        cryPlayer = AVPlayer(url: url)
        cryPlayer?.play()
    }
}
