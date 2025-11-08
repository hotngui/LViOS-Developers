//
// Created by Joey Jarosz on 11/2/25.
// Copyright (c) 2025 hot-n-GUI, LLC. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    enum Destination {
        case one, two, three, four, five
    }

    var body: some View {
        NavigationStack {
            List {
                NavigationLink(value: Destination.one) {
                    Text("First View")
                }
                NavigationLink(value: Destination.two) {
                    Text("Second View")
                }
                NavigationLink(value: Destination.three) {
                    Text("Third View")
                }
                NavigationLink(value: Destination.four) {
                    Text("Fourth View")
                }
                NavigationLink(value: Destination.five) {
                    Text("Fifth View")
                }
            }
            .navigationTitle("Main Menu")
            
            .navigationDestination(for: Destination.self) { selected in
                switch selected {
                case .one:
                    FirstView()
                case .two:
                    SecondView()
                case .three:
                    ThirdView()
                case .four:
                    FourthView()
                case .five:
                    FifthView()
                }
            }

        }
    }
}

#Preview {
    ContentView()
}
