import SwiftUI

struct ContentView: View {
    @StateObject private var model = ChoreModel()
    @EnvironmentObject var themeManager: ThemeManager
    @State private var selectedTab = 0
    @State private var showingThemeSettings = false

    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView()
                .tabItem {
                    Label("Hoy", systemImage: "sun.max.fill")
                }
                .tag(0)

            TasksView()
                .tabItem {
                    Label("Tareas", systemImage: "checklist")
                }
                .tag(1)

            StatsView()
                .tabItem {
                    Label("Estadísticas", systemImage: "chart.bar.fill")
                }
                .tag(2)
                
            HistoryView()
                .tabItem {
                    Label("Historial", systemImage: "calendar")
                }
                .tag(3)
                
            SettingsTabView(showingThemeSettings: $showingThemeSettings)
                .tabItem {
                    Label("Ajustes", systemImage: "gearshape.fill")
                }
                .tag(4)
        }
        .environmentObject(model)
        .accentColor(themeManager.currentAccentColor)
        .background(themeManager.themeColors.background)
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SwitchToTodayTab"))) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                selectedTab = 0
            }
        }
        .onChange(of: selectedTab) { oldValue, newValue in
            HapticManager.shared.navigation()
        }
        .sheet(isPresented: $showingThemeSettings) {
            ThemeSettingsView()
        }
    }
}
