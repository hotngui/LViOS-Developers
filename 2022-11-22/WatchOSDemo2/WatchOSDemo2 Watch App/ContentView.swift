//
// Created by Joey Jarosz on 11/11/22.
// Copyright © 2022 hot-n-GUI, LLC. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var currentSelection: Selection

    var model = CommsWatch()
    
    var body: some View {
        ViewThatFits {
            AlternateView1()
            AlternateView2()
        }
        .onChange(of: model) { newValue in
            model.send(currentSelection.current)
        }
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView()
                .previewDevice("Apple Watch Ultra (49mm)")
                .previewDisplayName("Ultra")
            ContentView()
                .previewDevice("Apple Watch Series 8 (41mm)")
                .previewDisplayName("41mm")
        }
    }
}
#endif
