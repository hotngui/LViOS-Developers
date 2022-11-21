//
// Created by Joey Jarosz on 11/11/22.
// Copyright © 2022 hot-n-GUI, LLC. All rights reserved.
//

import SwiftUI

struct AlternateView1: View {
    var body: some View {
        VStack {
            HStack {
                MyButton(title: "One")
                MyButton(title: "Two")
                MyButton(title: "Three")
            }
            .padding(0)

            HStack {
                MyButton(title: "Four")
                MyButton(title: "Five")
                MyButton(title: "Six")
            }
            .padding(0)
        }
        .padding(0)
    }
}

#if DEBUG
struct AlternateView1_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            AlternateView1()
                .previewDevice("Apple Watch Ultra (49mm)")
                .previewDisplayName("Ultra")
            AlternateView1()
                .previewDevice("Apple Watch Series 8 (41mm)")
                .previewDisplayName("41mm")
        }
    }
}
#endif
