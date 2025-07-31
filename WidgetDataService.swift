import Foundation
import WidgetKit

/// Servicio para compartir datos entre la app principal y el widget
class WidgetDataService {
    static let shared = WidgetDataService()
    private let userDefaults = UserDefaults(suiteName: "group.principepuerta.ListaPendientes")
    
    private init() {}
    
    // MARK: - Keys para UserDefaults
    private enum Keys {
        static let todaysTasks = "todaysTasks"
        static let completedTasksCount = "completedTasksCount"
        static let totalTasksCount = "totalTasksCount"
        static let lastUpdate = "lastUpdate"
    }
    
    // MARK: - Métodos para guardar datos desde la app principal
    func saveTodaysTasks(_ tasks: [TaskItem]) {
        let encoder = JSONEncoder()
        let widgetTasks = tasks.map { task in
            WidgetTaskData(
                id: task.id.uuidString,
                title: task.title,
                isCompleted: false // Esto se actualizará con el estado del día
            )
        }
        
        if let encoded = try? encoder.encode(widgetTasks) {
            userDefaults?.set(encoded, forKey: Keys.todaysTasks)
        }
        
        userDefaults?.set(Date(), forKey: Keys.lastUpdate)
        userDefaults?.synchronize()
        
        // Actualizar widget
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    func updateTaskProgress(tasks: [TaskItem], todayRecord: DailyRecord) {
        print("📱 WidgetDataService - Iniciando updateTaskProgress con \(tasks.count) tareas")
        
        let encoder = JSONEncoder()
        let widgetTasks = tasks.map { task in
            let isCompleted = todayRecord.statuses.first(where: { $0.taskId == task.id })?.completed ?? false
            print("📱 WidgetDataService - Tarea: '\(task.title)', Completada: \(isCompleted)")
            return WidgetTaskData(
                id: task.id.uuidString,
                title: task.title,
                isCompleted: isCompleted
            )
        }
        
        print("📱 WidgetDataService - Generados \(widgetTasks.count) datos para widget")
        
        guard let userDefaults = userDefaults else {
            print("❌ WidgetDataService - CRÍTICO: No se pudo acceder a UserDefaults con suite 'group.principepuerta.ListaPendientes'")
            return
        }
        print("✅ WidgetDataService - UserDefaults disponible")
        
        if let encoded = try? encoder.encode(widgetTasks) {
            userDefaults.set(encoded, forKey: Keys.todaysTasks)
            print("✅ WidgetDataService - Datos de tareas guardados: \(encoded.count) bytes")
        } else {
            print("❌ WidgetDataService - ERROR: No se pudieron codificar las tareas")
            return
        }
        
        let completedCount = widgetTasks.filter { $0.isCompleted }.count
        userDefaults.set(completedCount, forKey: Keys.completedTasksCount)
        userDefaults.set(widgetTasks.count, forKey: Keys.totalTasksCount)
        userDefaults.set(Date(), forKey: Keys.lastUpdate)
        
        print("📱 WidgetDataService - Metadatos guardados: \(completedCount)/\(widgetTasks.count) tareas")
        
        let syncSuccess = userDefaults.synchronize()
        print("📱 WidgetDataService - Sincronización UserDefaults: \(syncSuccess ? "✅ Exitosa" : "❌ Falló")")
        
        // Actualizar widget
        WidgetCenter.shared.reloadAllTimelines()
        print("📱 WidgetDataService - Timeline del widget forzado a recargar")
    }
    
    // MARK: - Métodos para leer datos desde el widget
    func getTodaysTasks() -> [WidgetTaskData] {
        guard let data = userDefaults?.data(forKey: Keys.todaysTasks) else {
            return []
        }
        
        let decoder = JSONDecoder()
        return (try? decoder.decode([WidgetTaskData].self, from: data)) ?? []
    }
    
    func getCompletedTasksCount() -> Int {
        return userDefaults?.integer(forKey: Keys.completedTasksCount) ?? 0
    }
    
    func getTotalTasksCount() -> Int {
        return userDefaults?.integer(forKey: Keys.totalTasksCount) ?? 0
    }
    
    func getLastUpdate() -> Date? {
        return userDefaults?.object(forKey: Keys.lastUpdate) as? Date
    }
    
    // MARK: - Métodos de utilidad
    func isDataStale() -> Bool {
        guard let lastUpdate = getLastUpdate() else { return true }
        let hoursSinceUpdate = Date().timeIntervalSince(lastUpdate) / 3600
        return hoursSinceUpdate > 1 // Considerar obsoleto después de 1 hora
    }
}

/// Estructura de datos para el widget
struct WidgetTaskData: Codable {
    let id: String
    let title: String
    var isCompleted: Bool
}
