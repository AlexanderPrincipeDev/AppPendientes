import SwiftUI

struct ContentView: View {
    @StateObject private var model = ChoreModel()
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var notificationService = NotificationService.shared
    @State private var selectedTab = 0

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
        }
        .environmentObject(model)
        .environmentObject(themeManager)
        .environmentObject(notificationService)
        .accentColor(themeManager.currentAccentColor)
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SwitchToTodayTab"))) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                selectedTab = 0
            }
        }
    }
}
