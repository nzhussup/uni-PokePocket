# PokePocket

PokePocket is a SwiftUI iOS app for browsing Pokémon from [PokéAPI](https://pokeapi.co/).
It loads Pokémon in pages as you scroll, searches the loaded catalog locally, and
shows details including
artwork, types, abilities, measurements, and base stats.

## Technologies

- Swift and SwiftUI (iOS 17+)
- `async`/`await`, `URLSession`, and `Codable`
- `NavigationStack` and custom URL deep links
- App Intents and Siri/Shortcuts

## Architecture

The project uses a lightweight MVVM structure:

- `Models.swift` contains the Codable API models.
- `PokemonAPIService.swift` contains all PokéAPI requests and HTTP error handling.
- `ViewModels.swift` owns loading/error state for the list and detail screens.
- `PokemonViews.swift` contains the SwiftUI screens and reusable row/detail components.
- `NavigationRouter.swift` centralizes navigation and deep-link handling.
- `OpenPokemonIntent.swift` exposes one arbitrary-name action to Siri and Shortcuts.

## Running

Open `PokePocket.xcodeproj` in Xcode, select an iOS Simulator or device, and run
the `PokePocket` scheme. An internet connection is required to load PokéAPI data.

## Siri and deep links

After adding the app shortcut, supported commands include:

- Say “Hey Siri, look up a Pokémon with Poke Pocket.”
- When Siri asks which Pokémon, answer with a name such as “Mewtwo.”

The app also accepts URLs such as:

```text
pokepocket://pokemon/pikachu
```

The intent accepts arbitrary text, including text passed in by another Shortcuts
action. It records the requested Pokémon before launching the app. The root
navigation model consumes that request on both cold and active launches. Unknown
names still open the detail route and display the Pokémon-not-found state.
