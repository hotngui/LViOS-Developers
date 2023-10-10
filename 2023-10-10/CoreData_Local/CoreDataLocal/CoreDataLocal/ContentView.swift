//
// Created by Joey Jarosz on 10/1/23.
// 
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Item.lastName, ascending: true)], animation: .default)
    private var items: FetchedResults<Item>

    @State private var isEditorOpen = false

    ///
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
            .navigationTitle("CoreData Local")
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
            offsets.map { items[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}


#if DEBUG
#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
#endif

