//
// Created by Joey Jarosz on 3/4/24.
// Copyright (c) 2024 hot-n-GUI, LLC. All rights reserved.
//

import SwiftUI


struct ContentView: View {
    @State var dummyData = [String]()

    @State var searchText = ""
    @State private var selection: String? = nil
    @State private var isAlbumSheetShowing = false
    @State private var isSearchPresented = true                            // <--- NEW
    
    var body: some View {
        NavigationStack {
            List(dummyData, id: \.self, selection: $selection) { data in
                Text(data)
            }
            .onChange(of: selection) { oldValue, newValue in
                if newValue != nil {
                    isAlbumSheetShowing = true
                }
            }
            .sheet(isPresented: $isAlbumSheetShowing, onDismiss: {
                selection = nil
                isSearchPresented = true
            }, content: {
                if let selection {
                    DummyView(data: selection)
                        .onAppear {                                        // <- NEW
                            isSearchPresented = false                      // <- NEW
                        }                                                  // <- NEW
                }
            })
            .listStyle(PlainListStyle())
            .navigationTitle("Album Search")
        }
        .searchable(text: $searchText,                                     // <- Modified
                    isPresented: $isSearchPresented,                       // <- Modified
                    prompt: "Enter Artist Name")                           // <- Modified
        .onSubmit(of: .search) {
            doSearch(for: searchText)
        }
        .onChange(of: searchText, { oldValue, newValue in
            print("searchText = \(searchText)")
        })
    }

    @MainActor
    private func doSearch(for term: String) {
        dummyData.append("One")
        dummyData.append("Two")
        dummyData.append("Three")
        dummyData.append("Four")
    }
}
