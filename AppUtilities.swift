import Foundation
import SwiftUI

// MARK: - Extensiones avanzadas y utilidades profesionales

// MARK: - Performance Monitoring
struct PerformanceMonitor {
    static let shared = PerformanceMonitor()
    private let logger = AppLogger.shared
    
    private init() {}
    
    /// Mide el tiempo de ejecución de una operación
    func measureTime<T>(operation: String, _ block: () throws -> T) rethrows -> T {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try block()
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        logger.log("⏱️ \(operation) took \(String(format: "%.3f", timeElapsed))s")
        
        if timeElapsed > 0.1 { // Warn if operation takes more than 100ms
            logger.log("⚠️ Slow operation detected: \(operation)", level: .warning)
        }
        
        return result
    }
    
    /// Mide operaciones async
    func measureAsyncTime<T>(operation: String, _ block: () async throws -> T) async rethrows -> T {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try await block()
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        logger.log("⏱️ \(operation) took \(String(format: "%.3f", timeElapsed))s")
        return result
    }
}

// MARK: - Memory Management Helpers
extension NSObject {
    /// Añade logging de deallocación para debugging
    func trackDeallocation(className: String? = nil) {
        let name = className ?? String(describing: type(of: self))
        AppLogger.shared.log("🗑️ Deallocating \(name)")
    }
}

// MARK: - Thread Safety Utilities
@propertyWrapper
class ThreadSafe<T> {
    private var value: T
    private let queue = DispatchQueue(label: "ThreadSafe_\(UUID().uuidString)", attributes: .concurrent)
    
    init(wrappedValue: T) {
        self.value = wrappedValue
    }
    
    var wrappedValue: T {
        get {
            queue.sync { value }
        }
        set {
            queue.async(flags: .barrier) { [weak self] in
                self?.value = newValue
            }
        }
    }
}

// MARK: - App Configuration
struct AppConfiguration {
    static let shared = AppConfiguration()
    
    // MARK: - Build Configuration
    var isDebugBuild: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
    
    var isTestFlight: Bool {
        Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt"
    }
    
    var isAppStore: Bool {
        !isDebugBuild && !isTestFlight
    }
    
    // MARK: - App Info
    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }
    
    var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }
    
    var bundleIdentifier: String {
        Bundle.main.bundleIdentifier ?? "Unknown"
    }
    
    // MARK: - Feature Flags
    var enableAdvancedLogging: Bool {
        isDebugBuild || UserDefaults.standard.bool(forKey: "enableAdvancedLogging")
    }
    
    var enableAnalytics: Bool {
        isAppStore || UserDefaults.standard.bool(forKey: "enableAnalytics")
    }
    
    var maxTasksPerDay: Int {
        UserDefaults.standard.object(forKey: "maxTasksPerDay") as? Int ?? 50
    }
    
    private init() {}
}

// MARK: - Network Monitoring (para futuras funcionalidades)
import Network

class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()
    
    @Published var isConnected = false
    @Published var connectionType: NWInterface.InterfaceType?
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    private init() {
        startMonitoring()
    }
    
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                self?.connectionType = path.availableInterfaces.first?.type
            }
        }
        monitor.start(queue: queue)
    }
    
    deinit {
        monitor.cancel()
    }
}

// MARK: - Accessibility Helpers
extension View {
    /// Añade etiquetas de accesibilidad estándar
    func accessibilityLabel(for task: TaskItem, isCompleted: Bool) -> some View {
        self.accessibilityLabel("\(task.title), \(isCompleted ? LocalizedStrings.accessibilityTaskCompleted : LocalizedStrings.accessibilityTaskPending)")
    }
    
    /// Soporte para Dynamic Type
    func supportsDynamicType() -> some View {
        self.font(.system(size: UIFont.preferredFont(forTextStyle: .body).pointSize))
    }
}

// MARK: - Data Migration Helper
struct DataMigrationManager {
    static let shared = DataMigrationManager()
    private let logger = AppLogger.shared
    
    private init() {}
    
    /// Versión actual del esquema de datos
    private let currentDataVersion = 1
    
    /// Ejecuta migraciones necesarias
    func performMigrationIfNeeded() {
        let savedVersion = UserDefaults.standard.integer(forKey: "dataSchemaVersion")
        
        if savedVersion < currentDataVersion {
            logger.log("Performing data migration from version \(savedVersion) to \(currentDataVersion)")
            
            // Aquí se ejecutarían las migraciones necesarias
            switch savedVersion {
            case 0:
                // Migración inicial
                migrateToVersion1()
            default:
                break
            }
            
            UserDefaults.standard.set(currentDataVersion, forKey: "dataSchemaVersion")
        }
    }
    
    private func migrateToVersion1() {
        // Ejemplo de migración
        logger.log("Executing migration to version 1")
        // Aquí se haría la migración real de datos
    }
}

// MARK: - App State Manager
@MainActor
class AppStateManager: ObservableObject {
    static let shared = AppStateManager()
    
    @Published var isActive = true
    @Published var sessionStartTime = Date()
    @Published var backgroundTime: Date?
    
    private init() {
        setupNotifications()
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.isActive = false
            self.backgroundTime = Date()
        }
        
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.isActive = true
            if let backgroundTime = self.backgroundTime {
                let timeInBackground = Date().timeIntervalSince(backgroundTime)
                AppLogger.shared.log("App was in background for \(timeInBackground)s")
            }
            self.backgroundTime = nil
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
