import SwiftUI

struct ContentView: View {
    @StateObject private var model = ChoreModel()

    var body: some View {
        TabView {
            NavigationStack {
                TodayView(model: model)
            }
            .tabItem { Label("Hoy", systemImage: "sun.max") }

            NavigationStack {
                TasksView(model: model)
            }
            .tabItem { Label("Tareas", systemImage: "checklist") }

            NavigationStack {
                HistoryView(model: model)
                    .navigationDestination(for: DailyRecord.self) { rec in
                        RecordDetailView(record: rec, model: model)
                    }
            }
            .tabItem { Label("Historial", systemImage: "calendar") }
        }
    }
}
