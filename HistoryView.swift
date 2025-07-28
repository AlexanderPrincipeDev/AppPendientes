import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var model: ChoreModel
    
    var body: some View {
        List {
            ForEach(model.records) { record in
                NavigationLink(value: record) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(formatDate(record.date))
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        HStack {
                            let completedCount = record.statuses.filter { $0.completed }.count
                            let total = record.statuses.count
                            
                            Text("\(completedCount) de \(total) tareas completadas")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            Spacer()
                            
                            ProgressView(value: Double(completedCount), total: Double(total))
                                .tint(completedCount == total ? .green : .blue)
                                .frame(width: 100)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Historial")
        .navigationBarTitleDisplayMode(.large)
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let date = formatter.date(from: dateString) {
            formatter.dateStyle = .long
            return formatter.string(from: date)
        }
        return dateString
    }
}
