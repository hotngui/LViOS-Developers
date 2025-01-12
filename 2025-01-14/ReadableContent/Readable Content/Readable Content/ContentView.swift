//
// Created by Joey Jarosz on 1/11/25.
// Copyright (c) 2025 hot-n-GUI, LLC. All rights reserved.
//

import SwiftUI

let sampleText = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nunc ut efficitur nibh, in vehicula odio. Vivamus dui massa, condimentum sed viverra et, condimentum in odio. Quisque at tortor lacus. Nam varius posuere dolor eget mollis. Etiam gravida malesuada mi ac euismod. Fusce maximus urna a diam maximus placerat. Aliquam erat volutpat. Duis semper commodo sem, sit amet sollicitudin nibh interdum ut. Donec et nisl augue. Sed eu imperdiet nulla. Nulla dictum nisi eget iaculis vulputate. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nunc ut efficitur nibh, in vehicula odio. Vivamus dui massa, condimentum sed viverra et, condimentum in odio. Quisque at tortor lacus. Nam varius posuere dolor eget mollis. Etiam gravida malesuada mi ac euismod. Fusce maximus urna a diam maximus placerat. Aliquam erat volutpat. Duis semper commodo sem, sit amet sollicitudin nibh interdum ut. Donec et nisl augue. Sed eu imperdiet nulla. Nulla dictum nisi eget iaculis vulputate."


// When using iPad's the width of a line of text can be quite long which makes it harder
// for a user to read - creating eye fatigue. Even if you app is using the same layout
// for both iPhone and iPad you want to make sure the line length does not get too long.
//
struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Simple", systemImage: "circle") {
                NavigationStack {
                    ScrollView {
                        VStack {
                            ForEach(0..<100) { _ in
                                Text("\(sampleText)")
                                Text("")
                            }
                        }
                    }
                    .padding()
                    .navigationBarTitle("Simple")
                }
            }
            Tab("Readable", systemImage: "square") {
                NavigationStack {
                    ScrollView {
                        VStack {
                            ForEach(0..<100) { _ in
                                Text("\(sampleText)")
                                    .readableContentWidth()
                                Text("")
                            }
                        }
                    }
                    .padding()
                    .navigationBarTitle("Readable Margins")
                }
            }
        }
    }
}

#Preview("Portrait", traits: .portrait) {
    ContentView()
}

#Preview("Landscape", traits: .landscapeLeft) {
    ContentView()
}
