import SwiftUI

struct PokemonHeroView: View {
    let pokemon: PokemonDetail

    var body: some View {
        VStack(spacing: 12) {
            AsyncImage(url: pokemon.imageURL) { phase in
                if let image = phase.image {
                    image.resizable().scaledToFit()
                } else {
                    Image(systemName: "sparkles")
                        .font(.system(size: 70))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(height: 220)

            Text(pokemon.displayName).font(.largeTitle.bold())
            Text("Pokédex #\(pokemon.id)")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                ForEach(pokemon.types, id: \.type.name) { slot in
                    Text(slot.type.name.displayName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(PokemonTypeColor.color(for: slot.type.name))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(PokemonTypeColor.color(for: slot.type.name).opacity(0.12), in: Capsule())
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct PokemonMeasurementsView: View {
    let pokemon: PokemonDetail

    var body: some View {
        HStack {
            metric("Height", value: "\((Double(pokemon.height) / 10).formatted(.number.precision(.fractionLength(1)))) m", icon: "ruler")
            Divider()
            metric("Weight", value: "\((Double(pokemon.weight) / 10).formatted(.number.precision(.fractionLength(1)))) kg", icon: "scalemass")
        }
        .padding()
        .detailCard()
    }

    private func metric(_ title: String, value: String, icon: String) -> some View {
        VStack(spacing: 5) {
            Label(title, systemImage: icon).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.headline)
        }
        .frame(maxWidth: .infinity)
    }
}

struct PokemonSpeciesSection: View {
    let species: PokemonSpecies
    let pokemon: PokemonDetail

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let genus = species.englishGenus { Text(genus).font(.headline) }
            if let description = species.englishDescription {
                Text(description).foregroundStyle(.secondary)
            }
            statusBadges
            Divider()
            DetailFactRow(title: "Generation", value: species.generation.name.displayName)
            DetailFactRow(title: "Base experience", value: pokemon.baseExperience.map(String.init) ?? "Unknown")
            DetailFactRow(title: "Growth rate", value: species.growthRate.name.displayName)
            DetailFactRow(title: "Habitat", value: species.habitat?.name.displayName ?? "Unknown")
            DetailFactRow(title: "Egg groups", value: species.eggGroups.map { $0.name.displayName }.joined(separator: ", "))
            DetailScaleRow(title: "Capture rate", value: Double(species.captureRate), maximum: 255, color: .orange)
            if let happiness = species.baseHappiness {
                DetailScaleRow(title: "Base happiness", value: Double(happiness), maximum: 255, color: .pink)
            }
            DetailFactRow(title: "Hatch cycles", value: "\(species.hatchCounter)")
            genderRow
        }
        .padding()
        .detailCard()
    }

    @ViewBuilder private var statusBadges: some View {
        if species.isLegendary || species.isMythical || species.isBaby {
            HStack {
                if species.isLegendary { StatusBadge(title: "Legendary", color: .orange) }
                if species.isMythical { StatusBadge(title: "Mythical", color: .purple) }
                if species.isBaby { StatusBadge(title: "Baby", color: .pink) }
            }
        }
    }

    @ViewBuilder private var genderRow: some View {
        if species.genderRate < 0 {
            DetailFactRow(title: "Gender", value: "Genderless")
        } else {
            let female = Double(species.genderRate) / 8
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Gender ratio").foregroundStyle(.secondary)
                    Spacer()
                    Text("\((female * 100).formatted(.number.precision(.fractionLength(0))))% female")
                }
                .font(.subheadline)
                ProgressView(value: female).tint(.pink)
            }
        }
    }
}

struct PokemonAbilitiesSection: View {
    let abilities: [PokemonAbilitySlot]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            DetailSectionTitle(title: "Abilities", systemImage: "sparkles")
            ForEach(abilities, id: \.ability.name) { slot in
                HStack {
                    Text(slot.ability.name.displayName)
                    Spacer()
                    if slot.isHidden { Text("Hidden").font(.caption).foregroundStyle(.secondary) }
                }
            }
        }
        .padding()
        .detailCard()
    }
}

struct PokemonStatsSection: View {
    let stats: [PokemonStatSlot]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            DetailSectionTitle(title: "Base Stats", systemImage: "chart.bar.fill")
            ForEach(stats, id: \.stat.name) { stat in
                HStack {
                    Text(stat.stat.name.displayName).frame(width: 110, alignment: .leading).font(.caption)
                    ProgressView(value: Double(stat.baseStat), total: 255)
                        .tint(statColor(stat.stat.name))
                    Text("\(stat.baseStat)").font(.caption.monospacedDigit())
                }
            }
        }
        .padding()
        .detailCard()
    }

    private func statColor(_ name: String) -> Color {
        switch name {
        case "hp": .green
        case "attack": .orange
        case "defense": .blue
        case "special-attack": .purple
        case "special-defense": .indigo
        case "speed": .cyan
        default: .accentColor
        }
    }
}

struct PokemonEvolutionSection: View {
    let evolution: EvolutionChain
    let currentName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            DetailSectionTitle(title: "Evolution Chain", systemImage: "arrow.triangle.branch")
            ForEach(items(from: evolution.chain)) { item in
                HStack(spacing: 12) {
                    Color.clear.frame(width: CGFloat(item.depth) * 14)
                    AsyncImage(url: item.species.spriteURL) { image in
                        image.resizable().scaledToFit()
                    } placeholder: {
                        ProgressView()
                    }
                    .frame(width: 54, height: 54)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(item.species.name.displayName).font(.headline)
                        if !item.condition.isEmpty {
                            Text(item.condition).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    Spacer()

                    if item.species.name != currentName {
                        NavigationLink(value: PokemonRoute(name: item.species.name)) {
                            Image(systemName: "chevron.right")
                        }
                    } else {
                        Text("Current").font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
        .detailCard()
    }

    private func items(from root: EvolutionLink) -> [EvolutionItem] {
        var result = [EvolutionItem(species: root.species, depth: 0, condition: "")]
        append(from: root, depth: 1, to: &result)
        return result
    }

    private func append(from link: EvolutionLink, depth: Int, to items: inout [EvolutionItem]) {
        for next in link.evolvesTo {
            items.append(EvolutionItem(species: next.species, depth: depth, condition: condition(next.evolutionDetails.first)))
            append(from: next, depth: depth + 1, to: &items)
        }
    }

    private func condition(_ detail: EvolutionDetail?) -> String {
        guard let detail else { return "" }
        var parts = [String]()
        if let value = detail.minLevel { parts.append("level \(value)") }
        if let value = detail.minHappiness { parts.append("happiness \(value)") }
        if let value = detail.item { parts.append(value.name.displayName) }
        if let value = detail.heldItem { parts.append("hold \(value.name.displayName)") }
        if let value = detail.knownMove { parts.append("know \(value.name.displayName)") }
        if let value = detail.location { parts.append(value.name.displayName) }
        if !detail.timeOfDay.isEmpty { parts.append(detail.timeOfDay.displayName) }
        if parts.isEmpty { parts.append(detail.trigger.name.displayName) }
        return parts.joined(separator: ", ")
    }
}

private struct EvolutionItem: Identifiable {
    let species: NamedResource
    let depth: Int
    let condition: String
    var id: String { species.name }
}

struct PokemonFormsSection: View {
    let forms: [PokemonFormDetail]

    var body: some View {
        if !forms.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                DetailSectionTitle(title: "Forms", systemImage: "square.on.square")

                ScrollView(.horizontal) {
                    HStack(spacing: 12) {
                        ForEach(forms, id: \.name) { form in
                            VStack(spacing: 8) {
                                AsyncImage(url: form.imageURL) { phase in
                                    if let image = phase.image {
                                        image.resizable().scaledToFit()
                                    } else if phase.error != nil {
                                        Image(systemName: "photo").foregroundStyle(.secondary)
                                    } else {
                                        ProgressView()
                                    }
                                }
                                .frame(width: 96, height: 96)

                                Text(formTitle(form))
                                    .font(.subheadline.weight(.medium))
                                    .lineLimit(2)
                                    .multilineTextAlignment(.center)

                                formLabel(form)
                            }
                            .frame(width: 130, height: 155)
                            .background(.quaternary, in: RoundedRectangle(cornerRadius: 16))
                        }
                    }
                    .padding(.vertical, 2)
                }
                .scrollIndicators(.hidden)
            }
            .padding()
            .detailCard()
        }
    }

    private func formTitle(_ form: PokemonFormDetail) -> String {
        form.formName.isEmpty ? form.name.displayName : form.formName.displayName
    }

    @ViewBuilder
    private func formLabel(_ form: PokemonFormDetail) -> some View {
        if form.isMega {
            Text("Mega").font(.caption2).foregroundStyle(.purple)
        } else if form.isBattleOnly {
            Text("Battle only").font(.caption2).foregroundStyle(.orange)
        } else if form.isDefault {
            Text("Default").font(.caption2).foregroundStyle(.secondary)
        }
    }
}

struct PokemonVarietiesSection: View {
    let varieties: [PokemonVariety]
    let currentName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            DetailSectionTitle(title: "Varieties", systemImage: "circle.grid.2x2")

            ScrollView(.horizontal) {
                HStack(spacing: 12) {
                    ForEach(varieties, id: \.pokemon.name) { variety in
                        if variety.pokemon.name == currentName {
                            varietyCard(variety)
                                .overlay(alignment: .topTrailing) {
                                    Text("Current").font(.caption2).foregroundStyle(.secondary).padding(8)
                                }
                        } else {
                            NavigationLink(value: PokemonRoute(name: variety.pokemon.name)) {
                                varietyCard(variety)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.vertical, 2)
            }
            .scrollIndicators(.hidden)
        }
        .padding()
        .detailCard()
    }

    private func varietyCard(_ variety: PokemonVariety) -> some View {
                            VStack(spacing: 8) {
                                AsyncImage(url: variety.pokemon.spriteURL) { phase in
                                    if let image = phase.image {
                                        image.resizable().scaledToFit()
                                    } else if phase.error != nil {
                                        Image(systemName: "photo").foregroundStyle(.secondary)
                                    } else {
                                        ProgressView()
                                    }
                                }
                                .frame(width: 96, height: 96)

                                Text(variety.pokemon.name.displayName)
                                    .font(.subheadline.weight(.medium))
                                    .lineLimit(2)
                                    .multilineTextAlignment(.center)

                                if variety.isDefault {
                                    Text("Default")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .frame(width: 130, height: 155)
                            .background(.quaternary, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct PokemonGameAppearancesSection: View {
    let games: [PokemonGameIndex]

    private var gameNames: String {
        games
            .sorted { $0.gameIndex < $1.gameIndex }
            .map { $0.version.name.displayName }
            .joined(separator: ", ")
    }

    var body: some View {
        if !games.isEmpty {
            DisclosureGroup {
                Text(gameNames)
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 8)
            } label: {
                DetailSectionTitle(
                    title: "Game Appearances (\(games.count))",
                    systemImage: "gamecontroller"
                )
            }
            .padding()
            .detailCard()
        }
    }
}

struct PokemonHeldItemsSection: View {
    let items: [PokemonHeldItem]
    var body: some View {
        if !items.isEmpty {
            DisclosureGroup {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(items, id: \.item.name) { item in
                        Text(item.item.name.displayName)
                        Text(item.versionDetails.map { "\($0.version.name.displayName): \($0.rarity)%" }.joined(separator: " · "))
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }.padding(.top, 8)
            } label: {
                DetailSectionTitle(title: "Held Items (\(items.count))", systemImage: "shippingbox")
            }
            .padding().detailCard()
        }
    }
}

struct PokemonMovesSection: View {
    let moves: [PokemonMove]

    private let columns = [
        GridItem(.flexible(), spacing: 12, alignment: .leading),
        GridItem(.flexible(), spacing: 12, alignment: .leading)
    ]

    private var groups: [MoveMethodGroup] {
        let summaries = moves.compactMap { move -> MoveSummary? in
            guard let detail = move.versionGroupDetails.last else { return nil }
            return MoveSummary(name: move.move.name, detail: detail)
        }
        return Dictionary(grouping: summaries, by: { $0.detail.moveLearnMethod.name })
            .map { MoveMethodGroup(method: $0.key, moves: $0.value.sorted { $0.name < $1.name }) }
            .sorted { $0.method < $1.method }
    }

    var body: some View {
        if !moves.isEmpty {
            DisclosureGroup {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(groups) { group in
                        VStack(alignment: .leading, spacing: 5) {
                            Text(group.method.displayName)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)

                            LazyVGrid(columns: columns, alignment: .leading, spacing: 6) {
                                ForEach(group.moves) { move in
                                    HStack(spacing: 5) {
                                        Text(move.name.displayName)
                                            .font(.subheadline)
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.8)

                                        if move.detail.levelLearnedAt > 0 {
                                            Text("Lv. \(move.detail.levelLearnedAt)")
                                                .font(.caption2.weight(.medium))
                                                .foregroundStyle(.blue)
                                                .padding(.horizontal, 5)
                                                .padding(.vertical, 2)
                                                .background(.blue.opacity(0.12), in: Capsule())
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        }
                    }
                }
                .padding(.top, 8)
            } label: {
                DetailSectionTitle(title: "Moves (\(moves.count))", systemImage: "bolt.fill")
            }
            .padding()
            .detailCard()
        }
    }
}

private struct MoveSummary: Identifiable {
    let name: String
    let detail: PokemonMoveVersion
    var id: String { name }
}

private struct MoveMethodGroup: Identifiable {
    let method: String
    let moves: [MoveSummary]
    var id: String { method }
}

struct PokemonSpritesSection: View {
    let sprites: PokemonSprites
    var body: some View {
        if !sprites.gallery.isEmpty {
            DisclosureGroup {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 16) {
                    ForEach(Array(sprites.gallery.enumerated()), id: \.offset) { _, sprite in
                        VStack {
                            AsyncImage(url: sprite.url) { $0.resizable().scaledToFit() } placeholder: { ProgressView() }
                                .frame(height: 80)
                            Text(sprite.name).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }.padding(.top, 8)
            } label: {
                DetailSectionTitle(title: "Sprites (\(sprites.gallery.count))", systemImage: "photo.on.rectangle")
            }
            .padding().detailCard()
        }
    }
}

struct PokemonCriesSection: View {
    let cries: PokemonCries?
    let play: (String) -> Void
    var body: some View {
        if let cries, cries.latest != nil || cries.legacy != nil {
            VStack(alignment: .leading, spacing: 12) {
                DetailSectionTitle(title: "Pokémon Cries", systemImage: "waveform")
                HStack {
                    if let latest = cries.latest { Button("Latest", systemImage: "play.fill") { play(latest) }.buttonStyle(.bordered) }
                    if let legacy = cries.legacy { Button("Legacy", systemImage: "play.fill") { play(legacy) }.buttonStyle(.bordered) }
                }
            }
            .padding().detailCard()
        }
    }
}

private struct DetailSectionTitle: View {
    let title: String
    let systemImage: String
    var body: some View { Label(title, systemImage: systemImage).font(.headline) }
}

private struct DetailFactRow: View {
    let title: String
    let value: String
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title).foregroundStyle(.secondary)
            Spacer()
            Text(value).multilineTextAlignment(.trailing)
        }.font(.subheadline)
    }
}

private struct DetailScaleRow: View {
    let title: String
    let value: Double
    let maximum: Double
    let color: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title).foregroundStyle(.secondary)
                Spacer()
                Text("\(Int(value)) / \(Int(maximum))")
            }.font(.subheadline)
            ProgressView(value: value, total: maximum).tint(color)
        }
    }
}

private struct StatusBadge: View {
    let title: String
    let color: Color
    var body: some View {
        Text(title).font(.caption.weight(.semibold)).padding(.horizontal, 10).padding(.vertical, 5)
            .foregroundStyle(color)
            .background(color.opacity(0.12), in: Capsule())
    }
}

private enum PokemonTypeColor {
    static func color(for type: String) -> Color {
        switch type {
        case "fire": .orange
        case "water": .blue
        case "grass": .green
        case "electric": .yellow
        case "psychic", "fairy": .pink
        case "poison": .purple
        case "ground", "rock": .brown
        case "ice": .cyan
        case "dragon": .indigo
        case "fighting": .red
        case "dark", "ghost": .gray
        default: .teal
        }
    }
}

private extension View {
    func detailCard() -> some View {
        frame(maxWidth: .infinity, alignment: .leading)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 16))
    }
}

extension String {
    var displayName: String { replacingOccurrences(of: "-", with: " ").capitalized }
}

private extension NamedResource {
    var spriteURL: URL? {
        guard let url,
              let identifier = URL(string: url)?.pathComponents.last else { return nil }
        return URL(string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/\(identifier).png")
    }
}
