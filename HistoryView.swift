import SwiftUI

struct HistoryView: View {
    @ObservedObject var model: ChoreModel

    var body: some View {
        List {
            ForEach(model.records) { record in
                NavigationLink(value: record) {
                    Text(record.date)
                }
            }
        }
        .navigationTitle("Historial")
    }
}
