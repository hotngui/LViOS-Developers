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
            }, content: {
                if let selection {
                    DummyView(data: selection)
                }
            })
            //.listStyle(PlainListStyle())
            .navigationTitle("Album Search")
        }
        .searchable(text: $searchText,
                    placement: .automatic,
                    prompt: "Enter Artist Name")
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
