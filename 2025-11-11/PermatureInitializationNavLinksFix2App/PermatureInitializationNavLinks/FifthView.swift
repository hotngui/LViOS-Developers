//
// Created by Joey Jarosz on 11/2/25.
// Copyright (c) 2025 hot-n-GUI, LLC. All rights reserved.
//

import SwiftUI

struct FifthView: View {
    init() {
        print("JOEY: FifthView initialized")
    }
    
    var body: some View {
        List {
            NavigationLink("Go to Sub Fifth 1") {
                SubFifthOneView()
            }
            
            NavigationLink("Go to Sub Fifth 2") {
                SubFifthTwoView()
            }
            
            NavigationLink("Go to Sub Fifth 3") {
                SubFifthThreeView()
            }
            
            NavigationLink("Go to Sub Fifth 4") {
                SubFifthFourView()
            }
            
            NavigationLink("Go to Sub Fifth 5") {
                SubFifthFiveView()
            }
        }
        .navigationTitle("Fifth")
    }
}

#Preview {
    NavigationStack {
        FifthView()
    }
}
