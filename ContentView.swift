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

            HabitsView()
                .tabItem {
                    Label("Hábitos", systemImage: "repeat.circle.fill")
                }
                .tag(2)
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
