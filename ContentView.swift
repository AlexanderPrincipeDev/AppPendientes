import SwiftUI

struct ContentView: View {
    @StateObject private var model = ChoreModel()
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
        .accentColor(.blue)
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SwitchToTodayTab"))) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                selectedTab = 0
            }
        }
    }
}
