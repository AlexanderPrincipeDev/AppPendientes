import SwiftUI

struct ContentView: View {
    @StateObject private var model = ChoreModel()

    var body: some View {
        TabView {
            TodayView()
                .tabItem {
                    Label("Hoy", systemImage: "sun.max.fill")
                }

            TasksView()
                .tabItem {
                    Label("Tareas", systemImage: "checklist")
                }

            StatsView()
                .tabItem {
                    Label("Estadísticas", systemImage: "chart.bar.fill")
                }
                
            HistoryView()
                .tabItem {
                    Label("Historial", systemImage: "calendar")
                }
        }
        .environmentObject(model)
        .accentColor(.blue)
    }
}
