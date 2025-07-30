import SwiftUI

@main
struct DailyChoresApp: App {
    @State private var showingSplash = true
    @StateObject private var notificationService = NotificationService.shared
    @StateObject private var model = ChoreModel()
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if showingSplash {
                    SplashScreenView {
                        showingSplash = false
                    }
                } else if model.isFirstLaunch {
                    WelcomeView { name in
                        model.setUserName(name)
                    }
                } else {
                    ContentView()
                        .environmentObject(notificationService)
                        .onAppear {
                            Task {
                                await notificationService.requestPermission()
                            }
                        }
                }
            }
            .environmentObject(model)
        }
    }
}
