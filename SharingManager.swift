import Foundation
import UIKit
import SwiftUI

/// Manager para compartir listas de tareas via AirDrop, Messages, etc.
@MainActor
class SharingManager: ObservableObject {
    static let shared = SharingManager()
    
    @Published var isSharing = false
    @Published var lastSharedData: SharedTaskData?
    
    private init() {}
    
    // MARK: - Export/Import Methods
    
    /// Exportar lista de tareas como archivo JSON
    func exportTaskList(tasks: [TaskItem], listName: String) async -> URL? {
        do {
            let exportData = ExportTaskData(
                listName: listName,
                tasks: tasks,
                exportDate: Date(),
                appVersion: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
            )
            
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            
            let jsonData = try encoder.encode(exportData)
            
            // Crear archivo temporal
            let tempDir = FileManager.default.temporaryDirectory
            let fileName = "\(listName.replacingOccurrences(of: " ", with: "_")).json"
            let fileURL = tempDir.appendingPathComponent(fileName)
            
            try jsonData.write(to: fileURL)
            
            return fileURL
            
        } catch {
            print("Error al exportar tareas: \(error)")
            return nil
        }
    }
    
    /// Importar lista de tareas desde archivo JSON
    func importTaskList(from url: URL) async throws -> ExportTaskData {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let importedData = try decoder.decode(ExportTaskData.self, from: data)
        return importedData
    }
    
    /// Compartir lista usando UIActivityViewController
    func shareTaskList(tasks: [TaskItem], listName: String, sourceView: UIView? = nil) {
        Task {
            guard let fileURL = await exportTaskList(tasks: tasks, listName: listName) else {
                return
            }
            
            isSharing = true
            
            let activityItems: [Any] = [
                "📋 Te comparto mi lista de tareas: \(listName)",
                fileURL
            ]
            
            let activityVC = UIActivityViewController(
                activityItems: activityItems,
                applicationActivities: nil
            )
            
            // Configurar para iPad
            if let popover = activityVC.popoverPresentationController {
                if let sourceView = sourceView {
                    popover.sourceView = sourceView
                    popover.sourceRect = sourceView.bounds
                } else if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                         let window = windowScene.windows.first {
                    popover.sourceView = window
                    popover.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
                }
            }
            
            activityVC.completionWithItemsHandler = { _, completed, _, _ in
                DispatchQueue.main.async {
                    self.isSharing = false
                }
            }
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
                rootViewController.present(activityVC, animated: true)
            }
        }
    }
    
    /// Generar código QR para compartir
    func generateQRCode(for tasks: [TaskItem], listName: String) -> UIImage? {
        do {
            let exportData = ExportTaskData(
                listName: listName,
                tasks: tasks,
                exportDate: Date(),
                appVersion: "1.0"
            )
            
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let jsonData = try encoder.encode(exportData)
            
            // Comprimir datos si es necesario
            let compressedData = try jsonData.compressed()
            let base64String = compressedData.base64EncodedString()
            
            return generateQRCodeImage(from: base64String)
            
        } catch {
            print("Error al generar QR: \(error)")
            return nil
        }
    }
    
    private func generateQRCodeImage(from string: String) -> UIImage? {
        let context = CIContext()
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else {
            print("Error: No se pudo crear el filtro CIQRCodeGenerator")
            return nil
        }
        
        filter.setValue(Data(string.utf8), forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")
        
        if let outputImage = filter.outputImage {
            // Escalar la imagen para que sea más grande y nítida
            let scaleX = 200 / outputImage.extent.size.width
            let scaleY = 200 / outputImage.extent.size.height
            let transformedImage = outputImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
            
            if let cgImage = context.createCGImage(transformedImage, from: transformedImage.extent) {
                return UIImage(cgImage: cgImage)
            }
        }
        
        return nil
    }
}

// MARK: - Data Models

struct ExportTaskData: Codable {
    let listName: String
    let tasks: [TaskItem]
    let exportDate: Date
    let appVersion: String
    
    var summary: String {
        return "\(tasks.count) tareas en '\(listName)'"
    }
}

struct SharedTaskData: Codable {
    let id: String
    let data: ExportTaskData
    let sharedAt: Date
    let expiresAt: Date?
}

// MARK: - Extensions

extension Data {
    func compressed() throws -> Data {
        return try (self as NSData).compressed(using: .lzfse) as Data
    }
    
    func decompressed() throws -> Data {
        return try (self as NSData).decompressed(using: .lzfse) as Data
    }
}
