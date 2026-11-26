//
//  PokePocketApp.swift
//  PokePocket
//
//  Created by Nurzhanat Zhussup on 20.10.26.
//

import SwiftUI
import AppIntents

@main
struct PokePocketApp: App {
    @StateObject private var router = NavigationRouter()
    @Environment(\.scenePhase) private var scenePhase

    init() {
        PokePocketShortcuts.updateAppShortcutParameters()
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $router.path) {
                ContentView()
                    .navigationDestination(for: PokemonRoute.self) { route in
                        PokemonDetailView(pokemonName: route.name)
                    }
            }
            .environmentObject(router)
            .onOpenURL { url in
                router.handle(url: url)
            }
            .onReceive(NotificationCenter.default.publisher(for: .openRequestedPokemon)) { _ in
                router.consumePokemonRequest()
            }
            .onAppear {
                router.consumePokemonRequest()
            }
            .onChange(of: scenePhase) { _, phase in
                guard phase == .active else { return }
                router.consumePokemonRequest()
            }
        }
    }
}
