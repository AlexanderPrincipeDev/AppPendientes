import SwiftUI

struct ContentView: View {
    @StateObject private var choreModel = ChoreModel()

    var body: some View {
        TabView {
            TodayView()
                .tabItem {
                    Label("Hoy", systemImage: "sun.max.fill")
                }

            TasksView(model: choreModel)
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
        .environmentObject(choreModel)
        .accentColor(.blue)
    }
}
