import SwiftUI

struct PokemonListView: View {
    @StateObject private var viewModel = PokemonListViewModel()
    @State private var searchText = ""
    @State private var scrollToTopRequest = 0

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.pokemon.isEmpty {
                ProgressView("Gathering Pokémon…")
            } else if let message = viewModel.errorMessage, viewModel.pokemon.isEmpty {
                errorView(title: "Couldn’t Load Pokémon", message: message) {
                    await viewModel.loadPokemon()
                }
            } else if searchText.isEmpty {
                pokemonList(viewModel.pokemon, loadsNextPage: true)
            } else {
                searchContent
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 7) {
                    Image("PokePocketLogo")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 28, height: 28)
                        .clipShape(Circle())

                    Text("Poke Pocket")
                        .font(.headline)
                }
                .fixedSize()
                .contentShape(Rectangle())
                .onTapGesture { scrollToTopRequest += 1 }
                .accessibilityLabel("Poke Pocket")
                .accessibilityHint("Scrolls to the top")
                .accessibilityAddTraits(.isButton)
            }
        }
        .searchable(text: $searchText, prompt: "Search Pokémon")
        .task { await viewModel.loadPokemon() }
        .task(id: searchText) {
            guard !searchText.isEmpty else { return }
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            await viewModel.searchPokemon(searchText)
        }
    }

    @ViewBuilder
    private var searchContent: some View {
        if viewModel.isSearching {
            ProgressView("Searching Pokémon…")
        } else if let message = viewModel.searchErrorMessage {
            errorView(title: "Couldn’t Search", message: message) {
                await viewModel.searchPokemon(searchText)
            }
        } else if viewModel.searchResults.isEmpty {
            ContentUnavailableView(
                "No Pokémon Found",
                systemImage: "magnifyingglass",
                description: Text("Check the spelling of “\(searchText)” and try again.")
            )
        } else {
            pokemonList(viewModel.searchResults, loadsNextPage: false)
        }
    }

    private func pokemonList(_ pokemon: [PokemonListItem], loadsNextPage: Bool) -> some View {
        ScrollViewReader { proxy in
            List {
                Section {
                    ForEach(pokemon) { item in
                        NavigationLink(value: PokemonRoute(name: item.name)) {
                            PokemonRowView(pokemon: item)
                        }
                        .onAppear {
                            guard loadsNextPage else { return }
                            Task { await viewModel.loadNextPageIfNeeded(after: item) }
                        }
                    }
                } header: {
                    if !pokemon.isEmpty { Text("\(pokemon.count) Pokémon") }
                }
                .id("pokemon-list-top")

                if loadsNextPage && viewModel.isLoadingNextPage {
                    HStack {
                        Spacer()
                        ProgressView("Finding more Pokémon…")
                        Spacer()
                    }
                    .listRowSeparator(.hidden)
                } else if loadsNextPage && viewModel.hasLoadedAllPokemon {
                    Label("You’ve discovered every Pokémon!", systemImage: "sparkles")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                        .listRowSeparator(.hidden)
                }
            }
            .listStyle(.insetGrouped)
            .onChange(of: scrollToTopRequest) {
                withAnimation {
                    proxy.scrollTo("pokemon-list-top", anchor: .top)
                }
            }
        }
    }

    private func errorView(
        title: String,
        message: String,
        retry: @escaping () async -> Void
    ) -> some View {
        ContentUnavailableView {
            Label(title, systemImage: "wifi.exclamationmark")
        } description: {
            Text(message)
        } actions: {
            Button("Try Again") { Task { await retry() } }
                .buttonStyle(.borderedProminent)
        }
    }
}

private struct PokemonRowView: View {
    let pokemon: PokemonListItem

    var body: some View {
        HStack(spacing: 16) {
            AsyncImage(url: imageURL) { phase in
                if let image = phase.image {
                    image.resizable().scaledToFit()
                } else if phase.error != nil {
                    Image(systemName: "questionmark.circle").foregroundStyle(.secondary)
                } else {
                    ProgressView()
                }
            }
            .frame(width: 60, height: 60)

            VStack(alignment: .leading, spacing: 4) {
                Text(pokemon.displayName).font(.headline)
                if let number {
                    Text("Pokédex #\(number)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 6)
    }

    private var number: String? {
        pokemon.url.split(separator: "/").last.map(String.init)
    }

    private var imageURL: URL? {
        guard let number else { return nil }
        return URL(string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/\(number).png")
    }
}
