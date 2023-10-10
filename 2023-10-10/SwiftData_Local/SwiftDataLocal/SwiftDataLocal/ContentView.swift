//
// Created by Joey Jarosz on 10/7/23.
// 
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]

    @State private var isEditorOpen = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(items) { item in
                    ContactCard(contact: item)
                }
                .onDelete(perform: deleteItems)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button {
                        isEditorOpen = true
                    } label: {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
            .navigationTitle("SwiftData Local")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $isEditorOpen) {
            NavigationStack {
                ContactEditor()
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(items[index])
            }
        }
    }
}

#if DEBUG
#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
#endif
