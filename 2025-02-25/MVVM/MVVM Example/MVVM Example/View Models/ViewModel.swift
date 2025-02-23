//
// Created by Joey Jarosz on 2/22/25.
// Copyright (c) 2025 hot-n-GUI, LLC. All rights reserved.
//

import SwiftUI
import SwiftData

@Observable
class ViewModel {
    private var modelContext: ModelContext
    private var items: [MyData] = []
    
    // MARK: - Data Access
    
    var itemIds: [UUID] {
        items.map(\.id)
    }
    
    func firstName(for id: UUID) -> String? {
        items.first { $0.id == id }?.firstName
    }
    
    func lastName(for id: UUID) -> String? {
        items.first { $0.id == id }?.lastName
    }
    
    func isActive(for id: UUID) -> Bool? {
        items.first { $0.id == id }?.isActive
    }

    // MARK: - Initializers
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchItems()
    }
    
    // MARK: - Data Fetching
    
    func fetchItems() {
        let descriptor = FetchDescriptor<MyData>(sortBy: [SortDescriptor(\.lastName)])
        
        do {
            items = try modelContext.fetch(descriptor)
            
            print(items.map({$0.lastName}))
        } catch {
            print("Error fetching items: \(error)")
            items = []
        }
    }
    
    // MARK: - CRUD Operations
    
    func addItem(firstName: String, lastName: String) {
        let newItem = MyData(firstName: firstName, lastName: lastName)
        modelContext.insert(newItem)
        fetchItems()
    }
    
    func deleteItem(id: UUID) {
        if let itemToDelete = items.first(where: { $0.id == id }) {
            modelContext.delete(itemToDelete)
            fetchItems()
        }
    }
    
    func toggleItemStatus(id: UUID) {
        if let item = items.first(where: { $0.id == id }) {
            item.isActive.toggle()
            fetchItems()
        }
    }
}
