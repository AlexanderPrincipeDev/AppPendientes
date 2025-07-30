import SwiftUI

@main
struct DailyChoresApp: App {
    @State private var showingSplash = true
    @StateObject private var notificationService = NotificationService.shared
    
    var body: some Scene {
        WindowGroup {
            if showingSplash {
                SplashScreenView {
                    showingSplash = false
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
    }
}
