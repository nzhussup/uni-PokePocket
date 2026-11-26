import AppIntents
import Foundation

struct OpenPokemonIntent: AppIntent {
    static let title: LocalizedStringResource = "Open Pokémon Details"
    static let description = IntentDescription("Open any Pokémon by name in Poke Pocket.")
    static let openAppWhenRun = true

    @Parameter(
        title: "Pokémon Name",
        description: "The name of the Pokémon to open.",
        requestValueDialog: "Which Pokémon?",
        inputConnectionBehavior: .connectToPreviousIntentResult
    )
    var pokemonName: String

    static var parameterSummary: some ParameterSummary {
        Summary("Open \(\.$pokemonName) in Poke Pocket")
    }

    func perform() async throws -> some IntentResult {
        let cleanedName = pokemonName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedName.isEmpty else {
            throw OpenPokemonIntentError.missingName
        }

        UserDefaults.standard.set(cleanedName, forKey: PokemonNavigationRequest.defaultsKey)
        await MainActor.run {
            NotificationCenter.default.post(name: .openRequestedPokemon, object: nil)
        }
        return .result()
    }
}

enum OpenPokemonIntentError: Error, LocalizedError {
    case missingName

    var errorDescription: String? {
        "Enter a Pokémon name."
    }
}

enum PokemonNavigationRequest {
    nonisolated static let defaultsKey = "requestedPokemonName"
}

extension Notification.Name {
    static let openRequestedPokemon = Notification.Name("openRequestedPokemon")
}

struct PokePocketShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OpenPokemonIntent(),
            phrases: [
                "Look up a Pokémon with \(.applicationName)",
                "Show Pokémon details with \(.applicationName)"
            ],
            shortTitle: "Open Pokémon Details",
            systemImageName: "arrow.up.forward.app"
        )
    }
}
