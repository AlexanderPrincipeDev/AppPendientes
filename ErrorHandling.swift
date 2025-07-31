import Foundation

/// Errores específicos de la aplicación para un manejo más granular
enum AppError: LocalizedError, Equatable {
    case dataCorruption
    case fileNotFound(String)
    case encodingFailed
    case decodingFailed
    case networkUnavailable
    case notificationPermissionDenied
    case invalidTaskData
    case categoryNotFound
    
    var errorDescription: String? {
        switch self {
        case .dataCorruption:
            return "Los datos están corruptos y no se pueden recuperar"
        case .fileNotFound(let fileName):
            return "No se pudo encontrar el archivo: \(fileName)"
        case .encodingFailed:
            return "Error al guardar los datos"
        case .decodingFailed:
            return "Error al cargar los datos"
        case .networkUnavailable:
            return "No hay conexión a internet disponible"
        case .notificationPermissionDenied:
            return "Permisos de notificación denegados"
        case .invalidTaskData:
            return "Los datos de la tarea son inválidos"
        case .categoryNotFound:
            return "La categoría no existe"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .dataCorruption:
            return "La aplicación se reiniciará con datos predeterminados"
        case .fileNotFound:
            return "Se creará un nuevo archivo con datos predeterminados"
        case .encodingFailed, .decodingFailed:
            return "Intenta reiniciar la aplicación"
        case .networkUnavailable:
            return "Verifica tu conexión a internet"
        case .notificationPermissionDenied:
            return "Ve a Configuración > Notificaciones para habilitar los permisos"
        case .invalidTaskData:
            return "Verifica que todos los campos estén completos"
        case .categoryNotFound:
            return "Selecciona una categoría válida"
        }
    }
}

/// Resultado que encapsula éxito o error
enum DataResult<T> {
    case success(T)
    case failure(AppError)
    
    var value: T? {
        if case .success(let value) = self {
            return value
        }
        return nil
    }
    
    var error: AppError? {
        if case .failure(let error) = self {
            return error
        }
        return nil
    }
}

/// Logger centralizado para la aplicación
class AppLogger {
    static let shared = AppLogger()
    
    private init() {}
    
    enum LogLevel: String {
        case debug = "🔍 DEBUG"
        case info = "ℹ️ INFO"
        case warning = "⚠️ WARNING"
        case error = "❌ ERROR"
    }
    
    func log(_ message: String, level: LogLevel = .info, file: String = #file, function: String = #function, line: Int = #line) {
        #if DEBUG
        let fileName = (file as NSString).lastPathComponent
        let timestamp = DateFormatter.logFormatter.string(from: Date())
        print("\(timestamp) [\(level.rawValue)] \(fileName):\(line) \(function) - \(message)")
        #endif
    }
}

extension DateFormatter {
    static let logFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter
    }()
}