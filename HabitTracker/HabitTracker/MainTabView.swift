import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("tab_home", systemImage: "house")
            }

            NavigationStack {
                HabitsView()
            }
            .tabItem {
                Label("tab_habits", systemImage: "list.bullet")
            }

            NavigationStack {
                StatsView()
            }
            .tabItem {
                Label("tab_stats", systemImage: "chart.bar")
            }

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("tab_settings", systemImage: "gearshape")
            }
        }
        .tint(Color.theme.accent)
    }
}

