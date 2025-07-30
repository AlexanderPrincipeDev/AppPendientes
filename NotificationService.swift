import Foundation
import UserNotifications

@MainActor
class NotificationService: ObservableObject {
    static let shared = NotificationService()
    
    @Published var notificationPermissionStatus: UNAuthorizationStatus = .notDetermined
    
    private init() {
        checkPermissionStatus()
    }
    
    func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            await MainActor.run {
                notificationPermissionStatus = granted ? .authorized : .denied
            }
            return granted
        } catch {
            print("Error requesting notification permission: \(error)")
            return false
        }
    }
    
    func checkPermissionStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.notificationPermissionStatus = settings.authorizationStatus
            }
        }
    }
    
    func scheduleTaskReminder(for task: TaskItem, at time: Date, repeatDaily: Bool = true, userName: String = "") {
        guard notificationPermissionStatus == .authorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Recordatorio de tarea"
        
        let personalizedBody = if !userName.isEmpty {
            "Hola \(userName), no olvides: \(task.title)"
        } else {
            "No olvides: \(task.title)"
        }
        content.body = personalizedBody
        content.sound = .default
        content.badge = 1
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: components,
            repeats: repeatDaily
        )
        
        let request = UNNotificationRequest(
            identifier: "task_\(task.id.uuidString)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }
    
    func cancelNotification(for taskId: UUID) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["task_\(taskId.uuidString)"]
        )
    }
    
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    func scheduleTasksDailyReminder(tasks: [TaskItem], at time: Date, userName: String = "") {
        guard notificationPermissionStatus == .authorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Lista Pendientes"
        
        let personalizedBody = if !userName.isEmpty {
            "Hola \(userName), tienes \(tasks.count) tareas pendientes para hoy"
        } else {
            "Tienes \(tasks.count) tareas pendientes para hoy"
        }
        content.body = personalizedBody
        content.sound = .default
        content.badge = NSNumber(value: tasks.count)
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: components,
            repeats: true
        )
        
        let request = UNNotificationRequest(
            identifier: "daily_reminder",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling daily reminder: \(error)")
            }
        }
    }
    
    func sendCompletionCelebration(completedTasks: Int, userName: String = "") {
        guard notificationPermissionStatus == .authorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "¡Felicitaciones! 🎉"
        
        let personalizedMessage = if !userName.isEmpty {
            "¡Increíble \(userName)! Has completado todas tus \(completedTasks) tareas del día. ¡Eres imparable!"
        } else {
            "¡Increíble! Has completado todas tus \(completedTasks) tareas del día. ¡Eres imparable!"
        }
        
        content.body = personalizedMessage
        content.sound = .default
        content.badge = NSNumber(value: 0)
        
        let request = UNNotificationRequest(
            identifier: "completion_celebration",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling completion celebration: \(error)")
            }
        }
    }
}
