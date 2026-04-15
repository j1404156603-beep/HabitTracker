//
//  HabitTrackerApp.swift
//  HabitTracker
//
//  Created by Soren on 2026/4/13.
//

import SwiftUI

@main
struct HabitTrackerApp: App {
    @StateObject private var auth = AuthManager()
    @StateObject private var settings = AppSettings()
    @StateObject private var store: HabitStore

    init() {
        let s = AppSettings()
        _settings = StateObject(wrappedValue: s)
        _store = StateObject(wrappedValue: HabitStore(settings: s))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(auth)
                .environmentObject(store)
                .environmentObject(settings)
                .preferredColorScheme(settings.appearance.preferredColorScheme)
                .environment(\.locale, settings.language.locale)
        }
    }
}
