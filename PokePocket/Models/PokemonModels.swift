import Foundation

struct PokemonListResponse: Codable, Sendable {
    let count: Int
    let next: String?
    let results: [PokemonListItem]
}

struct PokemonListItem: Codable, Hashable, Identifiable, Sendable {
    let name: String
    let url: String

    var id: String { name }
    var displayName: String { name.capitalized }
}

struct PokemonDetail: Codable, Sendable {
    let id: Int
    let name: String
    let baseExperience: Int?
    let height: Int
    let weight: Int
    let order: Int
    let isDefault: Bool
    let sprites: PokemonSprites
    let types: [PokemonTypeSlot]
    let abilities: [PokemonAbilitySlot]
    let stats: [PokemonStatSlot]
    let moves: [PokemonMove]
    let heldItems: [PokemonHeldItem]
    let forms: [NamedResource]
    let gameIndices: [PokemonGameIndex]
    let cries: PokemonCries?
    let species: NamedResource

    enum CodingKeys: String, CodingKey {
        case id, name, height, weight, order, sprites, types, abilities, stats, moves, forms, cries, species
        case baseExperience = "base_experience"
        case isDefault = "is_default"
        case heldItems = "held_items"
        case gameIndices = "game_indices"
    }

    var displayName: String { name.capitalized }
    var imageURL: URL? {
        URL(string: sprites.other?.officialArtwork?.frontDefault ?? sprites.frontDefault ?? "")
    }
}

struct PokemonDetailsBundle: Sendable {
    let pokemon: PokemonDetail
    let species: PokemonSpecies
    let evolution: EvolutionChain?
    let forms: [PokemonFormDetail]
}

struct PokemonFormDetail: Codable, Sendable {
    let name: String
    let formName: String
    let isDefault: Bool
    let isBattleOnly: Bool
    let isMega: Bool
    let pokemon: NamedResource
    let sprites: PokemonSprites

    enum CodingKeys: String, CodingKey {
        case name, pokemon, sprites
        case formName = "form_name"
        case isDefault = "is_default"
        case isBattleOnly = "is_battle_only"
        case isMega = "is_mega"
    }

    var imageURL: URL? {
        URL(string: sprites.frontDefault ?? sprites.frontShiny ?? "")
    }
}

struct PokemonSprites: Codable, Sendable {
    let frontDefault: String?
    let frontFemale: String?
    let frontShiny: String?
    let frontShinyFemale: String?
    let backDefault: String?
    let backFemale: String?
    let backShiny: String?
    let backShinyFemale: String?
    let other: OtherSprites?

    enum CodingKeys: String, CodingKey {
        case frontDefault = "front_default"
        case frontFemale = "front_female"
        case frontShiny = "front_shiny"
        case frontShinyFemale = "front_shiny_female"
        case backDefault = "back_default"
        case backFemale = "back_female"
        case backShiny = "back_shiny"
        case backShinyFemale = "back_shiny_female"
        case other
    }

    var gallery: [(name: String, url: URL)] {
        [
            ("Front", frontDefault), ("Front Female", frontFemale),
            ("Front Shiny", frontShiny), ("Front Shiny Female", frontShinyFemale),
            ("Back", backDefault), ("Back Female", backFemale),
            ("Back Shiny", backShiny), ("Back Shiny Female", backShinyFemale)
        ].compactMap { name, value in
            guard let value, let url = URL(string: value) else { return nil }
            return (name, url)
        }
    }
}

struct OtherSprites: Codable, Sendable {
    let officialArtwork: OfficialArtwork?

    enum CodingKeys: String, CodingKey {
        case officialArtwork = "official-artwork"
    }
}

struct OfficialArtwork: Codable, Sendable {
    let frontDefault: String?

    enum CodingKeys: String, CodingKey {
        case frontDefault = "front_default"
    }
}

struct PokemonTypeSlot: Codable, Sendable {
    let type: NamedResource
}

struct PokemonAbilitySlot: Codable, Sendable {
    let isHidden: Bool
    let slot: Int
    let ability: NamedResource

    enum CodingKeys: String, CodingKey {
        case isHidden = "is_hidden"
        case slot, ability
    }
}

struct PokemonStatSlot: Codable, Sendable {
    let baseStat: Int
    let stat: NamedResource

    enum CodingKeys: String, CodingKey {
        case baseStat = "base_stat"
        case stat
    }
}

struct NamedResource: Codable, Hashable, Sendable {
    let name: String
    let url: String?
}

struct PokemonMove: Codable, Sendable {
    let move: NamedResource
    let versionGroupDetails: [PokemonMoveVersion]

    enum CodingKeys: String, CodingKey {
        case move
        case versionGroupDetails = "version_group_details"
    }
}

struct PokemonMoveVersion: Codable, Sendable {
    let levelLearnedAt: Int
    let moveLearnMethod: NamedResource
    let versionGroup: NamedResource

    enum CodingKeys: String, CodingKey {
        case levelLearnedAt = "level_learned_at"
        case moveLearnMethod = "move_learn_method"
        case versionGroup = "version_group"
    }
}

struct PokemonHeldItem: Codable, Sendable {
    let item: NamedResource
    let versionDetails: [PokemonHeldItemVersion]

    enum CodingKeys: String, CodingKey {
        case item
        case versionDetails = "version_details"
    }
}

struct PokemonHeldItemVersion: Codable, Sendable {
    let rarity: Int
    let version: NamedResource
}

struct PokemonGameIndex: Codable, Sendable {
    let gameIndex: Int
    let version: NamedResource

    enum CodingKeys: String, CodingKey {
        case gameIndex = "game_index"
        case version
    }
}

struct PokemonCries: Codable, Sendable {
    let latest: String?
    let legacy: String?
}

struct PokemonSpecies: Codable, Sendable {
    let id: Int
    let captureRate: Int
    let baseHappiness: Int?
    let genderRate: Int
    let hatchCounter: Int
    let isBaby: Bool
    let isLegendary: Bool
    let isMythical: Bool
    let hasGenderDifferences: Bool
    let formsSwitchable: Bool
    let color: NamedResource
    let shape: NamedResource?
    let habitat: NamedResource?
    let generation: NamedResource
    let growthRate: NamedResource
    let eggGroups: [NamedResource]
    let evolvesFromSpecies: NamedResource?
    let evolutionChain: APIResource?
    let flavorTextEntries: [FlavorTextEntry]
    let genera: [PokemonGenus]
    let varieties: [PokemonVariety]

    enum CodingKeys: String, CodingKey {
        case id, color, shape, habitat, generation, genera, varieties
        case captureRate = "capture_rate"
        case baseHappiness = "base_happiness"
        case genderRate = "gender_rate"
        case hatchCounter = "hatch_counter"
        case isBaby = "is_baby"
        case isLegendary = "is_legendary"
        case isMythical = "is_mythical"
        case hasGenderDifferences = "has_gender_differences"
        case formsSwitchable = "forms_switchable"
        case growthRate = "growth_rate"
        case eggGroups = "egg_groups"
        case evolvesFromSpecies = "evolves_from_species"
        case evolutionChain = "evolution_chain"
        case flavorTextEntries = "flavor_text_entries"
    }

    var englishDescription: String? {
        flavorTextEntries.last { $0.language.name == "en" }?.flavorText
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\u{000C}", with: " ")
    }

    var englishGenus: String? {
        genera.first { $0.language.name == "en" }?.genus
    }
}

struct APIResource: Codable, Sendable {
    let url: String
}

struct FlavorTextEntry: Codable, Sendable {
    let flavorText: String
    let language: NamedResource

    enum CodingKeys: String, CodingKey {
        case flavorText = "flavor_text"
        case language
    }
}

struct PokemonGenus: Codable, Sendable {
    let genus: String
    let language: NamedResource
}

struct PokemonVariety: Codable, Sendable {
    let isDefault: Bool
    let pokemon: NamedResource

    enum CodingKeys: String, CodingKey {
        case isDefault = "is_default"
        case pokemon
    }
}

struct EvolutionChain: Codable, Sendable {
    let chain: EvolutionLink
}

final class EvolutionLink: Codable, @unchecked Sendable {
    let species: NamedResource
    let evolutionDetails: [EvolutionDetail]
    let evolvesTo: [EvolutionLink]

    enum CodingKeys: String, CodingKey {
        case species
        case evolutionDetails = "evolution_details"
        case evolvesTo = "evolves_to"
    }
}

struct EvolutionDetail: Codable, Sendable {
    let trigger: NamedResource
    let minLevel: Int?
    let minHappiness: Int?
    let timeOfDay: String
    let item: NamedResource?
    let heldItem: NamedResource?
    let knownMove: NamedResource?
    let location: NamedResource?

    enum CodingKeys: String, CodingKey {
        case trigger, item, location
        case minLevel = "min_level"
        case minHappiness = "min_happiness"
        case timeOfDay = "time_of_day"
        case heldItem = "held_item"
        case knownMove = "known_move"
    }
}
