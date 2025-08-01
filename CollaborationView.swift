import SwiftUI

struct CollaborationView: View {
    @EnvironmentObject private var model: ChoreModel
    @StateObject private var sharingManager = SharingManager.shared
    @State private var showingShareSheet = false
    @State private var showingImportPicker = false
    @State private var showingQRCode = false
    @State private var qrCodeImage: UIImage?
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.largeTitle)
                            .foregroundColor(.blue)
                        
                        Text("Compartir Tareas")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Comparte tus listas de tareas con otros usuarios")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    
                    // Exportar tareas
                    exportSection
                    
                    // Código QR
                    qrCodeSection
                    
                    // Importar tareas
                    importSection
                }
                .padding()
            }
            .navigationTitle("Colaboración")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Exportar Todas las Tareas") {
                            shareAllTasks()
                        }
                        Button("Exportar Tareas de Hoy") {
                            shareTodayTasks()
                        }
                        Divider()
                        Button("Importar Tareas") {
                            showingImportPicker = true
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .fileImporter(
            isPresented: $showingImportPicker,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            handleImport(result: result)
        }
    }
    
    private var exportSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Exportar Tareas", systemImage: "square.and.arrow.up")
                .font(.headline)
            
            VStack(spacing: 12) {
                Button(action: shareAllTasks) {
                    HStack {
                        Image(systemName: "list.bullet")
                        VStack(alignment: .leading) {
                            Text("Todas las Tareas")
                                .font(.headline)
                            Text("\(model.tasks.count) tareas")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemBlue).opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(12)
                }
                
                Button(action: shareTodayTasks) {
                    HStack {
                        Image(systemName: "calendar.badge.plus")
                        VStack(alignment: .leading) {
                            Text("Tareas de Hoy")
                                .font(.headline)
                            Text("\(todayTasksCount) tareas")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGreen).opacity(0.1))
                    .foregroundColor(.green)
                    .cornerRadius(12)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(15)
    }
    
    private var qrCodeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Código QR", systemImage: "qrcode")
                .font(.headline)
            
            Text("Genera un código QR para compartir tus tareas de forma rápida")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button("Generar QR de Tareas") {
                generateQRCode()
            }
            .buttonStyle(.bordered)
            .frame(maxWidth: .infinity)
            
            if let qrImage = qrCodeImage {
                VStack(spacing: 12) {
                    Image(uiImage: qrImage)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 200)
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(radius: 5)
                    
                    Text("Escanea este código para importar las tareas")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(15)
    }
    
    private var importSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Importar Tareas", systemImage: "square.and.arrow.down")
                .font(.headline)
            
            Text("Importa listas de tareas desde archivos JSON compartidos")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button("Seleccionar Archivo") {
                showingImportPicker = true
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
            
            if let lastShared = sharingManager.lastSharedData {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Último archivo compartido:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(lastShared.data.summary)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    
                    Text("Compartido: \(lastShared.sharedAt, style: .relative)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(15)
    }
    
    private var todayTasksCount: Int {
        let today = Date()
        return model.tasks.filter { task in
            if task.taskType == .daily {
                return true
            }
            if let specificDate = task.specificDate {
                return Calendar.current.isDate(specificDate, inSameDayAs: today)
            }
            return false
        }.count
    }
    
    private func shareAllTasks() {
        sharingManager.shareTaskList(tasks: model.tasks, listName: "Todas mis tareas")
        HapticManager.shared.success()
    }
    
    private func shareTodayTasks() {
        let today = Date()
        let todayTasks = model.tasks.filter { task in
            if task.taskType == .daily {
                return true
            }
            if let specificDate = task.specificDate {
                return Calendar.current.isDate(specificDate, inSameDayAs: today)
            }
            return false
        }
        
        sharingManager.shareTaskList(tasks: todayTasks, listName: "Tareas de Hoy")
        HapticManager.shared.success()
    }
    
    private func generateQRCode() {
        qrCodeImage = sharingManager.generateQRCode(for: model.tasks, listName: "Mis Tareas")
        HapticManager.shared.mediumImpact()
    }
    
    private func handleImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            Task {
                do {
                    let importedData = try await sharingManager.importTaskList(from: url)
                    
                    await MainActor.run {
                        // Agregar tareas importadas al modelo
                        var addedCount = 0
                        for task in importedData.tasks {
                            if !model.tasks.contains(where: { $0.title == task.title }) {
                                model.tasks.append(task)
                                addedCount += 1
                            }
                        }
                        
                        if addedCount > 0 {
                            model.saveTasks()
                            HapticManager.shared.success()
                            
                            // Actualizar último archivo compartido
                            sharingManager.lastSharedData = SharedTaskData(
                                id: UUID().uuidString,
                                data: importedData,
                                sharedAt: Date(),
                                expiresAt: nil
                            )
                        } else {
                            HapticManager.shared.warning()
                        }
                    }
                } catch {
                    print("Error al importar: \(error)")
                    HapticManager.shared.error()
                }
            }
            
        case .failure(let error):
            print("Error en importación: \(error)")
            HapticManager.shared.error()
        }
    }
}

#Preview {
    CollaborationView()
        .environmentObject(ChoreModel())
}
